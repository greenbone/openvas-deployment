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

    if [ "${deployment_mode}" == 'scan' ]; then
        init_certs_scan
        init_certs_ingress
    elif [ "${deployment_mode}" == 'openvasd' ]; then
        init_certs_openvasd
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

    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_certs_openvasd
        # Todo: put me into file
        if [ "${OPENVASD_PORT}" ]; then
            export OPENVAS_SCANNER_HOST_LISTEN_PORT="${OPENVASD_PORT}"
        fi
    elif [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_certs_scan
        load_certs_ingress
    fi
}
