# =============================================================================
# artifact_download()
# =============================================================================
# Downloads and extracts the latest available product release from the OCI
# registry.
#
# The function verifies that the required OCI client certificate and private
# key are available, determines the latest version published for PRODUCT_URL,
# and downloads the corresponding artifact using ORAS.
#
# If the latest version has already been downloaded and contains a compose.yaml
# file, the function returns without downloading it again. Otherwise, it
# creates a version-specific artifact directory, pulls the product archive,
# extracts its contents, and removes the downloaded archive.
#
# Arguments:
#   None.
#
# Returns:
#   0 if the latest product version is already available locally.
#
# Exits:
#   1 if a required OCI client certificate or key is missing.
#   1 if no product release can be found in the configured OCI registry.
#   Exits if changing to the artifact directory fails.
artifact_download() {
    echo "🚀 Downloading product..."

    if [ "${VERSION_EXPLICIT}" = 'y' ]; then
        if ! VERSION="$(normalize_semver "${VERSION-}")"; then
            exit 1
        fi
    fi

    # Check certs exist
    if ! [ -f "${CERT_DIR_OCI}/client.crt" ]; then
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_PRODUCT}/server.crt! Please run --init!"
        exit 1
    fi
    if ! [ -f "${CERT_DIR_OCI}/client.key" ]; then
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_PRODUCT}/server.crt! Please run --init!"
        exit 1
    fi

    # Get latest version
    if [ "${VERSION_EXPLICIT}" != 'y' ]; then
        set +e
        VERSION="$(oras repo tags --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PRODUCT_URL}" | {
            latest=''
            while IFS= read -r tag; do
            normalized="$(normalize_semver "${tag}" 2>/dev/null)" || continue
            if [ -z "${latest}" ] || semver_greater "${normalized}" "${latest}"; then
                latest="${normalized}"
            fi
            done
            printf '%s\n' "${latest}"
        })"
        set -e
    fi

    # Check if VERSION exist
    if ! [ "${VERSION}" ]; then
        echo "Error: No product release found in registry ${PRODUCT_URL}!"
        echo "For support, visit: https://www.greenbone.net/support/"
        exit 1
    fi

    # Check if compose files already exist
    if [ -f "$ARTIFACT_DIR/${VERSION}/compose.yaml" ]; then
        echo "Info: Latest version ${VERSION} already downloaded."
        return 0
    fi

    # Create artifact dir
    mkdir -p "$ARTIFACT_DIR/${VERSION}"

    # Download the selected artifact without falling back to another tag.
    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        if ! oras pull --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PRODUCT_URL}:${VERSION}"; then
            echo "Error: Product version ${VERSION} is not available in registry ${PRODUCT_URL}." >&2
            exit 1
        fi
        tar  xzf "${PRODUCT}.tar.gz"
        rm -f "${PRODUCT}.tar.gz"
    popd > /dev/null
}

# =============================================================================
# get_latest_version()
# =============================================================================
# Determines the latest locally downloaded product version.
#
# The function scans ARTIFACT_DIR for version directories matching a semantic
# version pattern, sorts the discovered versions, and stores the latest version
# in VERSION.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if ARTIFACT_DIR does not exist.
#   1 if no downloaded product version can be found in ARTIFACT_DIR.
get_latest_version() {
    if [ "${VERSION_EXPLICIT}" = 'y' ]; then
        if ! VERSION="$(normalize_semver "${VERSION-}")"; then
            exit 1
        fi
        if [ ! -d "${ARTIFACT_DIR}" ] || [ ! -f "${ARTIFACT_DIR}/${VERSION}/compose.yaml" ]; then
            echo "Error: Requested version ${VERSION} is not downloaded at ${ARTIFACT_DIR}/${VERSION}/compose.yaml. Please run --update." >&2
            exit 1
        fi
        return 0
    fi

    if [ -d "${ARTIFACT_DIR}" ]; then
        set +e
        local entry normalized
        local latest=''
        for entry in "${ARTIFACT_DIR}"/*; do
            [ -d "${entry}" ] || continue
            [ -f "${entry}/compose.yaml" ] || continue
            normalized="$(normalize_semver "${entry##*/}" 2>/dev/null)" || continue
            if [ -z "${latest}" ] || semver_greater "${normalized}" "${latest}"; then
                latest="${normalized}"
            fi
        done
        VERSION="${latest}"
        set -e
        if ! [ "${VERSION}" ]; then
            echo "Error: No product downloaded! Please run --update!"
            exit 1
        fi
    else
        echo "Error: No working directory exist! Please run --init and/or --update!"
        exit 1
    fi
}
