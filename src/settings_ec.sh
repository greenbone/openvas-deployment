# =============================================================================
# init_settings_ec()
# =============================================================================
# Validates and stores the settings required for EC scan deployments.
#
# The function verifies that DEPLOYMENT_MODE, FEED_MODE, and CCERT_MODE are
# included in their respective supported option lists and persists the selected
# values in SETTINGS_DIR using init_setting().
#
# Mount-based feed and CCERT modes are currently rejected. Depending on
# CCERT_MODE, the function stores the corresponding CCERT_TYPE and then
# initializes the configured feed synchronization hour.
#
# If DEPLOYMENT_MODE is set to 'openvasd', the corresponding openvasd settings
# are initialized as well.
#
# Arguments:
#   $1  Deployment mode. Defaults to DEPLOYMENT_MODE.
#   $2  Feed mode. Defaults to FEED_MODE.
#   $3  CCERT mode. Defaults to CCERT_MODE.
#   $4  Feed path. Defaults to FEED_PATH.
#   $5  CCERT path. Defaults to CCERT_PATH.
#   $6  Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if DEPLOYMENT_MODE is not supported.
#   1 if FEED_MODE is not supported.
#   1 if CCERT_MODE is not supported.
#   1 if FEED_MODE is set to 'mount'.
#   1 if CCERT_MODE is set to 'mount'.
init_settings_ec() {
    local deployment_mode="${1:-$DEPLOYMENT_MODE}"
    local feed_mode="${2:-$FEED_MODE}"
    local ccert_mode="${3:-$CCERT_MODE}"
    local feed_path="${4:-$FEED_PATH}"
    local ccert_path="${5:-$CCERT_PATH}"
    local settings_dir="${6:-$SETTINGS_DIR}"

    echo 'Info: Init settings EC'

    if [[ " ${DEPLOYMENT_MODE_OPTIONS[*]} " =~ " ${deployment_mode} " ]]; then
        init_setting "DEPLOYMENT_MODE" "${deployment_mode}" "${settings_dir}"
    else
        echo "Error: Deployment mode ${deployment_mode} is not supported only ${DEPLOYMENT_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [[ " ${FEED_MODE_OPTIONS[*]} " =~ " ${feed_mode} " ]]; then
        init_setting "FEED_MODE" "${feed_mode}" "${settings_dir}"
    else
        echo "Error: feed mode option ${feed_mode} is not supported only ${FEED_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [[ " ${CCERT_MODE_OPTIONS[*]} " =~ " ${ccert_mode} " ]]; then
        init_setting "CCERT_MODE" "${ccert_mode}" "${settings_dir}"
    else
        echo "Error: feed mode option ${ccert_mode} is not supported only ${CCERT_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [ "${feed_mode}" == 'mount' ]; then
        if [ -d "${feed_path}" ]; then
            echo "Error: feed mode option mount is not supported currently!"
        else
            echo "Error: feed path ${feed_path} does not exist!"
        fi
        exit 1
    fi
    if [ "${ccert_mode}" == 'mount' ]; then
        if [ -d "${ccert_path}" ]; then
            echo "Error: ccert mode option mount is not supported currently!"
        else
            echo "Error: ccert path ${ccert_path} does not exist!"
        fi
        exit 1
    fi
    if [ "${ccert_mode}" == 'ca' ] || [ "${ccert_mode}" == 'cert' ]; then
        init_setting "CCERT_TYPE" "env" "${settings_dir}"
    else
        init_setting "CCERT_TYPE" "mount" "${settings_dir}"
    fi

    init_feed_sync_hour

    if [ "${deployment_mode}" == 'openvasd' ]; then
        init_settings_openvasd
    fi
}

# =============================================================================
# load_settings_ec()
# =============================================================================
# Loads the settings required for an enterprise-container deployment.
#
# The function reads the persisted deployment, feed, CCERT, and feed
# synchronization settings from SETTINGS_DIR and exports them for use by
# subsequent deployment operations.
#
# Mount-specific paths are loaded when the corresponding mode is set to
# 'mount'. After loading the common enterprise-container settings, the function
# dispatches to the deployment-mode-specific settings loader.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if a required settings file is missing.
load_settings_ec() {
    echo 'Info: Load settings EC'

    if [ -f "${SETTINGS_DIR}/DEPLOYMENT_MODE" ]; then
        export DEPLOYMENT_MODE="$(< "${SETTINGS_DIR}/DEPLOYMENT_MODE")"
    else
        echo "Error: No deployment mode found at ${SETTINGS_DIR}/DEPLOYMENT_MODE! Please run --init!"
        exit 1
    fi
    if [ -f "${SETTINGS_DIR}/FEED_MODE" ]; then
        export FEED_MODE="$(< "${SETTINGS_DIR}/FEED_MODE")"
    else
        echo "Error: No feed mode found at ${SETTINGS_DIR}/FEED_MODE! Please run --init!"
        exit 1
    fi
    if [ -f "${SETTINGS_DIR}/CCERT_MODE" ]; then
        export CCERT_MODE="$(< "${SETTINGS_DIR}/CCERT_MODE")"
    else
        echo "Error: No ccert mode found at ${SETTINGS_DIR}/CCERT_MODE! Please run --init!"
        exit 1
    fi
    if [ "${FEED_MODE}" == 'mount' ] && [ -f "${SETTINGS_DIR}/FEED_PATH" ]; then
        export FEED_PATH="$(< "${SETTINGS_DIR}/FEED_PATH")"
    elif [ "${FEED_MODE}" == 'mount' ]; then
        echo "Error: No feed path found at ${SETTINGS_DIR}/FEED_PATH! Please run --init!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'mount' ] && [ -f "${SETTINGS_DIR}/CCERT_PATH" ]; then
        export CCERT_PATH="$(< "${SETTINGS_DIR}/CCERT_PATH")"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
        echo "Error: No ccert path found at ${SETTINGS_DIR}/CCERT_PATH! Please run --init!"
        exit 1
    fi
    if [ -f "${SETTINGS_DIR}/CCERT_TYPE" ]; then
        export CCERT_TYPE="$(< "${SETTINGS_DIR}/CCERT_TYPE")"
    else
        echo "Error: No ccert type found at ${SETTINGS_DIR}/CCERT_TYPE! Please run --init!"
        exit 1
    fi
    if [ -f "${SETTINGS_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR" ]; then
        export GREENBONE_FEED_SYNC_JOB_HOUR="$(< "${SETTINGS_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR")"
    else
        echo "Error: No FEED_SYNC_JOB_HOUR found at ${SETTINGS_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR! Please run --init or --change-feed-sync-hour with --feed-sync-hour!"
        exit 1
    fi

    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_settings_openvasd
    fi
}
