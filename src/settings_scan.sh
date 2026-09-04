init_settings_scan() {
    if [[ " ${DEPLOYMENT_MODE_OPTIONS[*]} " =~ " ${DEPLOYMENT_MODE} " ]]; then
        echo "${DEPLOYMENT_MODE}" > "${SETTINGS_DIR}/DEPLOYMENT_MODE"
    else
        echo "Error: Deployment mode ${DEPLOYMENT_MODE} is not supported only ${DEPLOYMENT_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [[ " ${FEED_MODE_OPTIONS[*]} " =~ " ${FEED_MODE} " ]]; then
        echo "${FEED_MODE}" > "${SETTINGS_DIR}/FEED_MODE"
    else
        echo "Error: feed mode option ${FEED_MODE} is not supported only ${FEED_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [[ " ${CCERT_MODE_OPTIONS[*]} " =~ " ${CCERT_MODE} " ]]; then
        echo "${CCERT_MODE}" > "${SETTINGS_DIR}/CCERT_MODE"
    else
        echo "Error: feed mode option ${CCERT_MODE} is not supported only ${CCERT_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [ "${FEED_MODE}" == 'mount' ] && [ -d "${FEED_PATH}" ]; then
        echo "Error: feed mode option mount is not supported currently!"
        exit 1
        echo "${FEED_PATH}" > "${SETTINGS_DIR}/FEED_PATH"
    elif [ "${FEED_MODE}" == 'mount' ]; then
        echo " Error: feed path ${FEED_PATH} does not exist!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'mount' ] && [ -d "${CCERT_PATH}" ]; then
        echo "Error: ccert mode option mount is not supported currently!"
        exit 1
        echo "${CCERT_PATH}" > "${SETTINGS_DIR}/CCERT_PATH"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
        echo " Error: ccert path ${CCERT_PATH} does not exist!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'ca' ] || [ "${CCERT_MODE}" == 'cert' ]; then
        echo 'env' > "${SETTINGS_DIR}/CCERT_TYPE"
    else
        echo 'mount' > "${SETTINGS_DIR}/CCERT_TYPE"
    fi
    init_feed_sync_hour
}

# =============================================================================
# load_settings_scan()
# =============================================================================
# Loads the scan environment configuration by reading the GVMD administrator
# password from the GVMD_ADMIN_PASSWORD file in the working directory and
# exporting it for use by subsequent scan operations.
#
# Arguments:
#   $1
#     Working directory containing the GVMD_ADMIN_PASSWORD file.
#     Defaults to WORKING_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the GVMD_ADMIN_PASSWORD file is missing.
load_settings_scan() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    if [ -f "${settings_dir}/GVMD_ADMIN_PASSWORD" ]; then
        export GVMD_ADMIN_PASSWORD="$(< "${settings_dir}/GVMD_ADMIN_PASSWORD")"
    else
        echo "Error: No admin password found at ${settings_dir}/GVMD_ADMIN_PASSWORD! Please run --init or --change-admin-password!"
        exit 1
    fi
}
