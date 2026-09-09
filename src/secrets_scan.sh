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
