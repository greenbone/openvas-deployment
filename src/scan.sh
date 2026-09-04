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
# Initializes the gvmd administrator password for a scan deployment.
#
# If GVMD_ADMIN_PASSWORD is already set, the function stores the configured
# password in SETTINGS_DIR.
#
# Otherwise, the function generates a random 16-character alphanumeric
# password, stores it in SETTINGS_DIR/GVMD_ADMIN_PASSWORD, loads it into
# GVMD_ADMIN_PASSWORD, and prints the generated password.
#
# Arguments:
#   None.
#
# Returns:
#   None.
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

# =============================================================================
# init_feed_key()
# =============================================================================
# Validates and installs the feed key for the selected product.
#
# The function verifies that FEED_KEY references an existing file. If the file
# contains valid Base64-encoded data, its decoded contents are written to
# CERT_DIR_PRODUCT/feed.key. Otherwise, the file is copied directly.
#
# The installed feed key is stored with restrictive file permissions.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if FEED_KEY is not set to an existing file.
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
# Generates the ECDSA key pair used for JWT signing and verification.
#
# The function creates a private EC key using the P-256 curve and stores it in
# CERT_DIR_PRODUCT. It then derives and writes the corresponding public key in
# PEM format.
#
# Arguments:
#   None.
#
# Returns:
#   None.
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

# =============================================================================
# load_feed_key()
# =============================================================================
# Loads the feed key for volume-based feed synchronization.
#
# If FEED_MODE is set to 'volume', the function reads the feed key from the
# product certificate directory and exports its contents for use by the feed
# synchronization service.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if FEED_MODE is 'volume' and the feed key file is missing.
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
