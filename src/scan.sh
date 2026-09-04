# =============================================================================
# change_admin_password_scan()
# =============================================================================
# Changes the Greenbone Vulnerability Manager (gvmd) administrator password.
#
# Verifies that GVMD_ADMIN_PASSWORD is set before updating the password. The
# password is written to the ADMIN_PASSWORD file in the working directory and
# then applied to the default "admin" account using the gvmd command inside
# the container. If no password is provided, the function prints an error
# message and exits with a non-zero status.
change_admin_password_scan() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${SETTINGS_DIR}/GVMD_ADMIN_PASSWORD"
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
# Updates the configured feed sync job hour and restarts the feed-sync service.
#
# The new feed sync hour is initialized and validated before triggering a
# feed-sync restart to apply the updated schedule configuration.
change_feed_sync_hour() {
    init_feed_sync_hour

    force_feed_sync
}

# =============================================================================
# force_feed_sync()
# =============================================================================
# Restarts the feed-sync container for the currently selected deployment.
#
# The latest version is resolved and the deployment environment is loaded
# before restarting the feed-sync service with Docker Compose. After the
# restart, the user is prompted whether to follow the container logs in
# real time.
force_feed_sync() {
    get_latest_version

    load_settings

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose restart feed-sync
        if [ "${FEED_SYNC_FORCE_NO_LOG}" == 'n' ]; then
            read -r -p "Info: Do you want to watch the feed sync container logs? (y/n)" response
            if [ "$response" == "y" ]; then
                docker compose logs -f feed-sync
            fi
        fi
    popd > /dev/null
}

# =============================================================================
# init_admin_password_scan()
# =============================================================================
# Initializes the Greenbone Vulnerability Manager administrator password.
#
# When GVMD_ADMIN_PASSWORD is set, the function writes it to the
# ADMIN_PASSWORD file in the working directory. Otherwise, it generates a
# random 16-character alphanumeric password, stores it in the
# GVMD_ADMIN_PASSWORD file, assigns it to GVMD_ADMIN_PASSWORD, and prints the
# generated password.
init_admin_password_scan() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${SETTINGS_DIR}/GVMD_ADMIN_PASSWORD"
    else
        echo "Info: No admin password set. Create random."
        set +e
        LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 16 > "${SETTINGS_DIR}/GVMD_ADMIN_PASSWORD"
        set -e
        GVMD_ADMIN_PASSWORD="$(< "${SETTINGS_DIR}/GVMD_ADMIN_PASSWORD")"
        echo "Your admin password is: ${GVMD_ADMIN_PASSWORD}"
    fi
}

# =============================================================================
# init_feed_sync_hour()
# =============================================================================
# Initializes the configured feed sync job hour.
#
# The configured hour is validated to ensure it is within the supported range
# from 1 to 24. A valid value is stored in the working directory for later use.
# Missing or invalid values are reported and terminate the function.
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

# =============================================================================
# init_feed_key()
# =============================================================================
# Installs the Enterprise Container feed key when the configured file exists.
#
# The function copies FEED_KEY into the Enterprise Container certificate
# directory as feed.key with permissions restricted to the file owner. If the
# source file does not exist, the function performs no action.
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
# init_jwt()
# =============================================================================
# Generates the ECDSA key pair used for Enterprise Container JWT signing.
#
# The function creates a P-256 private key in PEM format and derives the
# corresponding public key. Both keys are stored in the Enterprise Container
# certificate directory, replacing any existing files with the same names.
init_jwt() {
    echo "Info: Install JWT..."
    openssl genpkey \
        -algorithm EC \
        -outform PEM \
        -quiet \
        -out "${CERT_DIR_PRODUCT}/ecdsa.private.pem" \
        -pkeyopt ec_paramgen_curve:"P-256" \
        -pkeyopt ec_param_enc:named_curve \
        >/dev/null 2>&1
    openssl ec \
        -in "${CERT_DIR_PRODUCT}/ecdsa.private.pem" \
        -pubout \
        -outform PEM \
        -out "${CERT_DIR_PRODUCT}/ecdsa.public.pem" \
        >/dev/null 2>&1
}

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
