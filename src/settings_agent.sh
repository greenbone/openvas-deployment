# =============================================================================
# init_settings_agent()
# =============================================================================
# Initializes the agent-specific settings.
#
# The function persists the configured domain name and domain IP address into
# the settings directory using the generic init_setting() helper. These values
# are required for subsequent agent deployment operations.
#
# Arguments:
#   $1
#     Domain name.
#     Defaults to DOMAIN_NAME.
#
#   $2
#     Domain IP address.
#     Defaults to DOMAIN_IP.
#
#   $3
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the domain name or domain IP address is not set.
init_settings_agent() {
    local domain_name="${1:-$DOMAIN_NAME}"
    local domain_ip="${2:-$DOMAIN_IP}"
    local settings_dir="${3:-$SETTINGS_DIR}"

    if [ "${domain_name}" ]; then
        init_setting "DOMAIN_NAME" "${domain_name}" "${settings_dir}"
    else
        echo "Error: Domain name not set! Run --init with --domain-name!"
        exit 1
    fi

    if [ "${domain_ip}" ]; then
        init_setting "DOMAIN_IP" "${domain_ip}" "${settings_dir}"
    else
        echo "Error: Domain name not set! Run --init with --domain-ip!"
        exit 1
    fi
}

# =============================================================================
# load_settings_agent()
# =============================================================================
# Loads the agent-specific settings.
#
# The function loads the persisted domain name and domain IP address from the
# settings directory and exports them as DOMAIN_NAME and DOMAIN_IP using the
# generic load_setting() helper.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if a required setting file is missing or empty.
load_settings_agent() {
    load_setting "DOMAIN_NAME" "DOMAIN_NAME"
    load_setting "DOMAIN_IP" "DOMAIN_IP"
}
