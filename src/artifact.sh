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
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_OCI}/client.crt! Please run --init!"
        exit 1
    fi
    if ! [ -f "${CERT_DIR_OCI}/client.key" ]; then
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_OCI}/client.key! Please run --init!"
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
# list_remote_versions()
# =============================================================================
# Lists strict SemVer tags for PRODUCT_URL from the OCI registry.
#
# Uses the configured OCI client certificate and key, preserves each accepted
# tag's spelling, and outputs versions newest first with lexical ascending
# order for SemVer ties. An empty successful tag list produces no output.
#
# Arguments:
#   CERT_DIR_OCI
#     Directory containing the OCI client certificate and private key. Defaults
#     to CERT_DIR_OCI when omitted or empty. The configured value is required.
#   CERT_DIR_PRODUCT
#     Directory used in the missing-credential error message. Defaults to
#     CERT_DIR_PRODUCT when omitted or empty. The configured value is required.
#   PRODUCT_URL
#     OCI registry repository whose tags are listed. Defaults to PRODUCT_URL
#     when omitted or empty. The configured value is required.
#
# Outputs:
#   One accepted tag per line on stdout; errors are reported on stderr.
#
# Returns:
#   0 on success; 1 if a required configured value or credential is missing,
#   or the ORAS tag request fails.
list_remote_versions() {
    local cert_dir_oci="${1:-${CERT_DIR_OCI:?Error: CERT_DIR_OCI is empty or unset}}"
    local cert_dir_product="${2:-${CERT_DIR_PRODUCT:?Error: CERT_DIR_PRODUCT is empty or unset}}"
    local product_url="${3:-${PRODUCT_URL:?Error: PRODUCT_URL is empty or unset}}"
    local tags tag normalized
    if ! [ -f "${cert_dir_oci}/client.crt" ]; then
        echo "Error: No OCI TLS client certificate found at ${cert_dir_oci}/client.crt! Please run --init!" >&2
        return 1
    fi
    if ! [ -f "${cert_dir_oci}/client.key" ]; then
        echo "Error: No OCI TLS certificate found at ${cert_dir_oci}/client.key! Please run --init!" >&2
        return 1
    fi

    tags="$(oras repo tags --cert-file "${cert_dir_oci}/client.crt" --key-file "${cert_dir_oci}/client.key" "${product_url}")" || return 1

    local -a versions=()
    while IFS= read -r tag; do
        normalized="$(normalize_semver "${tag}" 2>/dev/null)" || continue
        versions+=("${tag}")
    done <<< "${tags}"

    if [ "${#versions[@]}" -gt 0 ]; then
        _sort_semver_versions "${versions[@]}"
    fi
}

# =============================================================================
# list_local_versions()
# =============================================================================
# Lists valid SemVer versions available in ARTIFACT_DIR.
#
# Includes directory basenames only when their directory contains compose.yaml,
# and outputs normalized versions newest first with lexical ascending order for
# SemVer ties. An existing empty directory produces no output.
#
# Arguments:
#   ARTIFACT_DIR
#     Directory containing downloaded version directories. Defaults to
#     ARTIFACT_DIR when omitted or empty. The configured value is required.
#
# Outputs:
#   One version per line on stdout; a missing or non-directory path is reported
#   on stderr.
#
# Returns:
#   0 on success; 1 if ARTIFACT_DIR is not configured, does not exist, or is
#   not a directory.
list_local_versions() {
    local artifact_dir="${1:-${ARTIFACT_DIR:?Error: ARTIFACT_DIR is empty or unset}}"
    local entry normalized
    local -a versions=()
    if [ ! -d "${artifact_dir}" ]; then
        printf 'Error: Artifact directory does not exist or is not a directory: %s\n' "${artifact_dir}" >&2
        return 1
    fi

    for entry in "${artifact_dir}"/*; do
        [ -d "${entry}" ] || continue
        [ -f "${entry}/compose.yaml" ] || continue
        normalized="$(normalize_semver "${entry##*/}" 2>/dev/null)" || continue
        versions+=("${normalized}")
    done
    if [ "${#versions[@]}" -gt 0 ]; then
        _sort_semver_versions "${versions[@]}"
    fi
}

# =============================================================================
# _sort_semver_versions()
# =============================================================================
# Outputs valid SemVer inputs in descending version order.
#
# Equal versions are ordered by their original strings in ascending lexical
# order. Inputs that are not valid SemVer are ignored. The function requires at
# least one non-empty first argument; zero arguments or an empty first argument
# cause a parameter-expansion error.
#
# Arguments:
#   $@
#     Version strings to sort.
#
# Outputs:
#   Sorted version strings, one per line on stdout.
#
# Returns:
#   The status of the final output operation.
#
# Exits:
#   The shell reports a parameter-expansion error if the first argument is
#   omitted or empty.
_sort_semver_versions() {
    local left right left_normalized right_normalized index
    local -a sorted=()
    local required_input="${1:?Error: Version input is empty}"
    while [ "$#" -gt 0 ]; do
        left="$required_input"
        shift
        required_input=${1-}
        left_normalized="$(normalize_semver "${left}" 2>/dev/null)" || continue
        index=0
        while [ "${index}" -lt "${#sorted[@]}" ]; do
            right="${sorted[index]}"
            right_normalized="$(normalize_semver "${right}" 2>/dev/null)" || {
                index=$((index + 1))
                continue
            }
            if semver_greater "${left_normalized}" "${right_normalized}"; then
                break
            fi
            if ! semver_greater "${right_normalized}" "${left_normalized}" && [[ "${left}" < "${right}" ]]; then
                break
            fi
            index=$((index + 1))
        done
        sorted=("${sorted[@]:0:index}" "${left}" "${sorted[@]:index}")
    done
    printf '%s\n' "${sorted[@]}"
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
