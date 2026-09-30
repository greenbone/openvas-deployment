# =============================================================================
# init_secrets_agent()
# =============================================================================
# Initializes the secrets required by the OpenVAS agent service.
#
# The function creates missing secrets in the specified secrets directory.
# Database passwords are generated automatically using the configured password
# generation method.
#
# Arguments:
#   $1  Optional path to the secrets directory. If omitted, SECRETS_DIR is used.
#
# Returns:
#   None.
init_secrets_agent() {
    local secrets_dir="${1:-$SECRETS_DIR}"

    init_secret "OPENVAS_AGENT_CONTROL_DB_PASSWORD" gen_password "${secrets_dir}"
    init_secret "OPENVAS_SKIRON_DB_PASSWORD" gen_password "${secrets_dir}"
}

# =============================================================================
# load_secrets_agent()
# =============================================================================
# Loads the secrets required by the OpenVAS agent service into the environment.
#
# The function reads the agent service database passwords from the specified
# secrets directory and exports them under their corresponding environment
# variable names.
#
# Arguments:
#   $1  Optional path to the secrets directory. If omitted, SECRETS_DIR is used.
#
# Returns:
#   None.
load_secrets_agent() {
    local secrets_dir="${1:-$SECRETS_DIR}"

    load_secret "OPENVAS_AGENT_CONTROL_DB_PASSWORD" "OPENVAS_AGENT_CONTROL_DB_PASSWORD" "${secrets_dir}"
    load_secret "OPENVAS_SKIRON_DB_PASSWORD" "OPENVAS_SKIRON_DB_PASSWORD" "${secrets_dir}"
}
