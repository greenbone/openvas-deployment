# =============================================================================
# init_secrets_scan()
# =============================================================================
# Initializes the GVMD administrator password secret for the scan deployment.
#
# If GVMD_ADMIN_PASSWORD is set, its value is written to the secret file.
# Otherwise, a random password is generated, stored in the secret file, loaded
# into GVMD_ADMIN_PASSWORD, and displayed to the console.
#
# Arguments:
#   $1  Optional secrets directory. Defaults to SECRETS_DIR.
#
# Returns:
#   None.
init_secrets_scan() {
    local secrets_dir="${1:-$SECRETS_DIR}"

    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        init_echo_secret "GVMD_ADMIN_PASSWORD" "${GVMD_ADMIN_PASSWORD}" "${secrets_dir}" 'y'
    else
        init_secret "GVMD_ADMIN_PASSWORD" gen_password "${secrets_dir}"
        load_secret "GVMD_ADMIN_PASSWORD" "GVMD_ADMIN_PASSWORD" "${secrets_dir}"
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

    load_secret "GVMD_ADMIN_PASSWORD" "GVMD_ADMIN_PASSWORD" "${secrets_dir}"
}
