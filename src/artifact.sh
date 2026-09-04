# =============================================================================
# artifact_download()
# =============================================================================
# Downloads the latest OpenVAS artifact using `oras`, extracts it, and
# prepares it for deployment.
artifact_download() {
    echo "🚀 Downloading product..."

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
    set +e
    VERSION="$(oras repo tags --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PRODUCT_URL}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sed '/-/! s/$/_/' | sort -Vu | sed 's/_$//' | tail -1)"
    set -e

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

    # Download artifact
    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        oras pull --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PRODUCT_URL}:${VERSION}"
        tar  xzf "${PRODUCT}.tar.gz"
        rm -f "${PRODUCT}.tar.gz"
    popd > /dev/null
}

# =============================================================================
# get_latest_version()
# =============================================================================
# Gets the latest downloaded OpenVAS artifact version.
get_latest_version() {
    if [ -d "${ARTIFACT_DIR}" ]; then
        set +e
        VERSION="$(ls "${ARTIFACT_DIR}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sed '/-/! s/$/_/' | sort -Vu | sed 's/_$//' | tail -1)"
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
