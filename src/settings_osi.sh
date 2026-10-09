# =============================================================================
# init_settings_osi()
# =============================================================================
# Initializes the domain setting required by the OSI deployment.
#
# The function validates that a DNS host name is provided and stores it in the
# product settings directory using init_setting(). Existing settings are kept
# unless explicitly forced by init_setting().
#
# Arguments:
#   $1
#     Domain name.
#     Defaults to DOMAIN_NAME.
#
#   $2
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the domain name is missing or invalid.
init_settings_osi() {
    local domain_name="${1:-$DOMAIN_NAME}"
    local settings_dir="${2:-$SETTINGS_DIR}"

    echo 'Info: Init settings OSI'

    if [ "${domain_name}" ]; then
        init_setting "DOMAIN_NAME" "${domain_name}" "${settings_dir}"
    else
        echo "Error: Domain name not set! Run --init with --domain-name!"
        exit 1
    fi
}

# =============================================================================
# load_settings_osi()
# =============================================================================
# Loads the domain setting required by the security-intelligence product.
#
# The function loads the persisted domain name from the product settings
# directory and exports it as DOMAIN_NAME using the generic load_setting()
# helper. The value is used by subsequent OSI deployment operations.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if the domain name settings file is missing or empty.
load_settings_osi() {
    echo 'Info: Load settings OSI'

    load_setting "DOMAIN_NAME" "DOMAIN_NAME"
}
