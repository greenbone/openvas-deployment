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

    echo "Info: Install Feed Key..."
    if base64 -d "${FEED_KEY}" >/dev/null 2>&1; then
        base64 -d "${FEED_KEY}" > "${CERT_DIR_PRODUCT}/feed.key"
        chmod 0600 "${CERT_DIR_PRODUCT}/feed.key"
    else
        install -m 0600 "${FEED_KEY}" "${CERT_DIR_PRODUCT}/feed.key"
    fi
}

# =============================================================================
# init_secrets_ec()
# =============================================================================
# Initializes secrets for the enterprise-container product.
#
# The function currently performs no secret generation or persistence and only
# reports that enterprise-container secret initialization has started.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_secrets_ec() {
    echo "Info: Init secrets EC"

    init_feed_key
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

# =============================================================================
# load_secrets_ec()
# =============================================================================
# Loads secrets for the enterprise-container product.
#
# The function currently performs no secret loading and only reports that
# enterprise-container secrets are being loaded.
#
# Arguments:
#   None.
#
# Returns:
#   None.
load_secrets_ec() {
    echo 'Info: Load secrets EC'

    load_feed_key
    if [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_secrets_scan
    fi
}
