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
