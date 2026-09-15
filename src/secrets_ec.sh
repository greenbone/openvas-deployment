# =============================================================================
# init_secrets_ec()
# =============================================================================
# Initializes secrets required by the Enterprise Container deployment.
#
# For scan deployments, the function initializes the scan-specific secrets.
# For other deployment modes, no additional secrets are initialized.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_secrets_ec() {
    echo "Info: Init secrets EC"

    if [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        init_secrets_scan
    fi
}

# =============================================================================
# load_secrets_ec()
# =============================================================================
# Loads secrets required by the Enterprise Container deployment.
#
# For scan deployments, the function loads the scan-specific secrets.
# For other deployment modes, no additional secrets are loaded.
#
# Arguments:
#   None.
#
# Returns:
#   None.
load_secrets_ec() {
    echo 'Info: Load secrets EC'

    if [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_secrets_scan
    fi
}
