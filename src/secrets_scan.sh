# =============================================================================
# init_secrets_scan()
# =============================================================================
# Initializes the GVMD administrator password secret for the scan deployment.
#
# If GVMD_ADMIN_PASSWORD is already set, the function writes its value to the
# corresponding secret file. Otherwise, it generates a random 16-character
# alphanumeric password, stores it in the secret file, assigns it to
# GVMD_ADMIN_PASSWORD, and prints the generated password.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_secrets_scan() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${SECRETS_DIR}/GVMD_ADMIN_PASSWORD"
    else
        echo "Info: No admin password set. Create random."
        set +e
        LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 16 > "${SECRETS_DIR}/GVMD_ADMIN_PASSWORD"
        set -e
        GVMD_ADMIN_PASSWORD="$(< "${SECRETS_DIR}/GVMD_ADMIN_PASSWORD")"
        echo "Your admin password is: ${GVMD_ADMIN_PASSWORD}"
    fi
}

# =============================================================================
# load_secrets_scan()
# =============================================================================
# Loads the administrator password required for scan deployments.
#
# The function reads the persisted gvmd administrator password from the
# settings directory and exports it as GVMD_ADMIN_PASSWORD for use by
# subsequent scan deployment operations.
#
# Arguments:
#   $1
#     Secrets directory.
#     Defaults to SECRETS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the administrator password settings file is missing.
load_secrets_scan() {
    local secrets_dir="${1:-$SECRETS_DIR}"

    if [ -f "${secrets_dir}/GVMD_ADMIN_PASSWORD" ]; then
        export GVMD_ADMIN_PASSWORD="$(< "${secrets_dir}/GVMD_ADMIN_PASSWORD")"
    else
        echo "Error: No admin password found at ${secrets_dir}/GVMD_ADMIN_PASSWORD! Please run --init or --change-admin-password!"
        exit 1
    fi
}
