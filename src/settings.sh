# =============================================================================
# init_settings()
# =============================================================================
# Validates the deployment, feed, and client-certificate configuration and
# writes the selected values to the working directory.
#
# DEPLOYMENT_MODE, FEED_MODE, and CCERT_MODE must match their corresponding
# supported-option arrays. Unsupported values terminate the script.
#
# Mount-based feed and client-certificate modes are currently rejected. For
# client-certificate modes "ca" and "cert", CCERT_TYPE is stored as "env";
# otherwise, it is stored as "mount".
init_settings() {
    local product="${1:-$PRODUCT}"

    if [[ " ${PRODUCT_OPTIONS[*]} " =~ " ${product} " ]]; then
        echo "${product}" > "${WORKING_DIR}/PRODUCT"
    else
        echo "Error: Product ${product} is not supported only ${PRODUCT_OPTIONS[*]}."
        exit 1
    fi

    if [ "${product}" == 'enterprise-container' ]; then
        init_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_settings_osi
    fi
}

load_settings() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_settings_osi
    fi
}
