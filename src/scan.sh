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
# Updates the configured feed synchronization hour and triggers a forced sync.
#
# Validates the GREENBONE_FEED_SYNC_JOB_HOUR environment variable to ensure
# it is set and contains a value between 0 and 23 (inclusive).
# If valid, writes the hour to the corresponding settings file and starts
# a forced feed synchronization using force_feed_sync.
#
# If the hour is missing or outside the allowed range, prints an error
# message and exits with status code 1.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Side effects:
#   - Updates the GREENBONE_FEED_SYNC_JOB_HOUR settings file.
#   - Triggers a forced feed synchronization.
#   - Terminates the script if validation fails.
change_feed_sync_hour() {
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

    force_feed_sync
}

# =============================================================================
# force_feed_sync()
# =============================================================================
# Restarts the feed synchronization service for the requested product
# deployment, or the latest deployment when no version was requested. Artifact
# resolution is performed by compose_recreate_container.
#
# The function uses the first argument as the log-follow setting, falling back
# to FEED_SYNC_FORCE_LOG when no argument is provided. If neither is set, the
# user is prompted whether to follow the feed-sync container logs after the
# restart.
#
# Arguments:
#   $1  Optional log-follow setting. Defaults to FEED_SYNC_FORCE_LOG.
#
# Returns:
#   None.
force_feed_sync() {
    local feed_sync_force_log="${1:-$FEED_SYNC_FORCE_LOG}"

    echo "Info: Feed sync may still be waiting for gvmd and openvasd to finish synchronization."
    echo "Info: This is indicated by the following log messages:"
    echo "      Trying to acquire lock on /var/lib/gvm/feed-update.lock"
    echo "      /var/lib/gvm/feed-update.lock is locked by another process."
    echo "      Waiting 5 seconds before next try."
    echo "Info: To trigger another feed sync immediately, run the script with --run."

    if ! [ "${feed_sync_force_log}" ]; then
        read -r -p "Info: Do you want to watch the feed sync container logs? (y/n)" feed_sync_force_log
    fi
    compose_recreate_container 'feed-sync' "${feed_sync_force_log}"
}

# =============================================================================
# init_feed_sync_hour()
# =============================================================================
# Initializes the configured feed synchronization hour.
#
# Checks whether the GREENBONE_FEED_SYNC_JOB_HOUR settings file exists and
# is non-empty. If so, returns successfully without modifying the file.
#
# Otherwise, validates the GREENBONE_FEED_SYNC_JOB_HOUR environment variable
# to ensure it is set and contains a value between 0 and 23 (inclusive).
# If valid, writes the configured hour to the settings file.
#
# If the hour is missing or outside the allowed range, prints an error
# message and exits with status code 1.
#
# Arguments:
#   None.
#
# Returns:
#   0 if the settings file already exists and is non-empty, or if the
#   feed synchronization hour is successfully initialized.
#
# Side effects:
#   - Creates or overwrites the GREENBONE_FEED_SYNC_JOB_HOUR settings file
#     if it is missing or empty.
#   - Terminates the script if validation fails.
init_feed_sync_hour() {
    if [ -s "${SETTINGS_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR" ]; then
        return 0
    fi

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
