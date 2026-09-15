# =============================================================================
# change_admin_password_scan()
# =============================================================================
# Changes the gvmd administrator password for a scan deployment.
#
# The function verifies that GVMD_ADMIN_PASSWORD is set, stores the password in
# the product settings directory, and then updates the password of the admin
# user by executing gvmd inside the configured gvmd container.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if GVMD_ADMIN_PASSWORD is not set.
change_admin_password_scan() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${SECRETS_DIR}/GVMD_ADMIN_PASSWORD"
    else
        echo 'Error: No admin password set. Please use --change-admin-password with --admin-password'
        exit 1
    fi

    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd \
        --user=admin --new-password="${GVMD_ADMIN_PASSWORD}"
}

# =============================================================================
# change_feed_sync_hour()
# =============================================================================
# Updates the configured feed synchronization hour and triggers a feed sync.
#
# The function initializes the feed synchronization schedule using
# init_feed_sync_hour and then immediately starts a forced feed synchronization.
#
# Arguments:
#   None.
#
# Returns:
#   None.
change_feed_sync_hour() {
    init_feed_sync_hour

    force_feed_sync
}

# =============================================================================
# force_feed_sync()
# =============================================================================
# Restarts the feed synchronization service for the latest product deployment.
#
# The function determines the latest locally available product version, loads
# the current settings, and restarts the feed-sync service in the corresponding
# Docker Compose stack.
#
# Unless FEED_SYNC_FORCE_NO_LOG is set to 'n', the function does not prompt for
# log output. When it is set to 'n', the user is asked whether to follow the
# feed-sync container logs after the restart.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   Exits if changing to the artifact directory fails.
force_feed_sync() {
    local feed_sync_force_no_log="${1:-$FEED_SYNC_FORCE_NO_LOG}"

    if ! [ "${feed_sync_force_no_log}" ]; then
        read -r -p "Info: Do you want to watch the feed sync container logs? (y/n)" feed_sync_force_no_log
    fi
    compose_recreate_container 'feed-sync' "${feed_sync_force_no_log}"
}

# =============================================================================
# init_feed_sync_hour()
# =============================================================================
# Validates and stores the configured feed synchronization hour.
#
# The function verifies that GREENBONE_FEED_SYNC_JOB_HOUR is set and contains
# a value between 0 and 23. If valid, the value is written to the product
# settings directory for use by the feed synchronization schedule.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if GREENBONE_FEED_SYNC_JOB_HOUR is not set.
#   1 if GREENBONE_FEED_SYNC_JOB_HOUR is outside the range 0 through 23.
init_feed_sync_hour() {
    if [ "${GREENBONE_FEED_SYNC_JOB_HOUR}" ]; then
        if (( GREENBONE_FEED_SYNC_JOB_HOUR >= 0 && GREENBONE_FEED_SYNC_JOB_HOUR <= 23 )); then
            echo "${GREENBONE_FEED_SYNC_JOB_HOUR}" > "${SETTINGS_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR"
        else
            echo "Error: No feed sync hour ${GREENBONE_FEED_SYNC_JOB_HOUR} needs to be between 0 and 23. Please run --change-feed-sync-hour or --init with --feed-sync-hour."
            exit 1
        fi
    else
        echo "Error: No feed sync hour set. Please run --change-feed-sync-hour or --init with --feed-sync-hour."
        exit 1
    fi
}
