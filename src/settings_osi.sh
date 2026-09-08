# =============================================================================
# init_settings_osi()
# =============================================================================
# Initializes the domain setting required by the security-intelligence product.
#
# The function validates that a domain name is provided and stores it in the
# product settings directory for later use by the OSI deployment.
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
#   1 if the domain name is not provided.
init_settings_osi() {
    local domain_name="${1:-$DOMAIN_NAME}"
    local settings_dir="${2:-$SETTINGS_DIR}"

    if [ "${domain_name}" ]; then
        echo "${domain_name}" > "${SETTINGS_DIR}/DOMAIN_NAME"
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
# The function reads the persisted domain name from the product settings
# directory and exports it as DOMAIN_NAME for use by subsequent OSI deployment
# operations.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if the domain name settings file is missing.
load_settings_osi() {
    echo 'Info: Load settings OSI'

    if [ -f "${SETTINGS_DIR}/DOMAIN_NAME" ]; then
        export DOMAIN_NAME="$(< "${SETTINGS_DIR}/DOMAIN_NAME")"
    else
        echo "Error: No domain name found at ${SETTINGS_DIR}/DOMAIN_NAME! Please run --init!"
        exit 1
    fi
}
