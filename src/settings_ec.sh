init_settings_ec() {
    if [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        init_settings_scan
    elif [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        init_settings_scan
        init_settings_openvasd
    fi
}

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
        export CCERT_PATH="$(< "${SETTINGS_DIR}/FEED_PATH")"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
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
    if [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_settings_scan
    elif [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_settings_openvasd
    fi
}
