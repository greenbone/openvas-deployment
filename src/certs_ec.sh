# =============================================================================
# init_certs_ec()
# =============================================================================
# Initializes certificates for the EC deployment according to the selected
# deployment mode.
#
# In scan mode, the function initializes both scan-related and ingress
# certificates. In openvasd mode, it initializes the certificates required by
# openvasd. Other deployment modes do not trigger certificate initialization.
#
# Arguments:
#   $1
#     Deployment mode that determines which certificate initialization
#     functions are called.
#     Defaults to DEPLOYMENT_MODE.
#
# Returns:
#   None.
init_certs_ec() {
    local deployment_mode="${1:-$DEPLOYMENT_MODE}"

    echo 'Info: Init certs EC'

    init_feed_key
    if [ "${deployment_mode}" == 'scan' ]; then
        init_certs_scan
        init_certs_ingress
    elif [ "${deployment_mode}" == 'openvasd' ]; then
        init_certs_openvasd
    fi
}

# =============================================================================
# init_feed_key()
# =============================================================================
# Validates and installs the feed key for the selected product.
#
# The function verifies that FEED_KEY references an existing file. If the file
# contains valid Base64-encoded data, its decoded contents are written to
# CERT_DIR_PRODUCT/feed.key. Otherwise, the file is copied directly.
#
# The installed feed key is stored with restrictive file permissions.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if FEED_KEY is not set to an existing file.
init_feed_key(){
    if ! [ -f "${FEED_KEY}" ]; then
        echo "Error: --feed-key argument missing!"
        echo "Info: Feed Mount options are not implemented."
        exit 1
    fi

    if base64 -d "${FEED_KEY}" >/dev/null 2>&1; then
        base64 -d "${FEED_KEY}" > "${CERT_DIR_PRODUCT}/feed.key"
        chmod 0600 "${CERT_DIR_PRODUCT}/feed.key"
    else
        install -m 0600 "${FEED_KEY}" "${CERT_DIR_PRODUCT}/feed.key"
    fi
}

# =============================================================================
# load_certs_ec()
# =============================================================================
# Loads the certificate configuration required for the selected
# enterprise-container deployment mode.
#
# In openvasd mode, the function loads the OpenVASD certificates and, if
# OPENVASD_PORT is set, exports it as OPENVAS_SCANNER_HOST_LISTEN_PORT.
#
# In scan mode, the function loads the scan and ingress certificate
# configuration.
#
# Arguments:
#   None.
#
# Returns:
#   None.
load_certs_ec() {
    echo 'Info: Load certs EC'

    load_feed_key
    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_certs_openvasd
    elif [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_certs_scan
        load_certs_ingress
    fi
}

# =============================================================================
# load_feed_key()
# =============================================================================
# Loads the feed key for volume-based feed synchronization.
#
# If FEED_MODE is set to 'volume', the function reads the feed key from the
# product certificate directory and exports its contents for use by the feed
# synchronization service.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if FEED_MODE is 'volume' and the feed key file is missing.
load_feed_key() {
    if [ "$FEED_MODE" == 'volume' ]; then
        if [ -f "${CERT_DIR_PRODUCT}/feed.key" ]; then
            export FEED_SYNC_GSF_KEY="$(< "${CERT_DIR_PRODUCT}/feed.key")"
        else
            echo "Error: No Feed key found at ${CERT_DIR_PRODUCT}/feed.key! Please run --init!"
            exit 1
        fi
    fi
}
