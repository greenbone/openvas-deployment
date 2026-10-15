# =============================================================================
# init_setting()
# =============================================================================
# Initializes a single setting file with the provided value.
#
# The function writes the given setting value to the specified settings file
# and applies restrictive file permissions. If the setting file already exists
# and force initialization is disabled, the existing value is preserved and
# initialization is skipped.
#
# Arguments:
#   $1
#     Setting file name.
#
#   $2
#     Setting value to write.
#
#   $3
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
#   $4
#     Force initialization flag.
#     Defaults to "n".
#     If set to "n", existing non-empty setting files are not overwritten.
#
# Returns:
#   None.
#
# Exits:
#   1 if the setting file name or setting value is empty.
init_setting() {
    local file="${1:?Error: Setting file name is empty}"
    local setting="${2:?Error: Setting $file is empty}"
    local settings_dir="${3:-$SETTINGS_DIR}"
    local force="${4:-n}"

    if [ -s "${settings_dir}/${file}" ] && [ "${force}" == 'n' ]; then
        chmod 0600 "${settings_dir}/${file}"
        echo "Info: Setting ${settings_dir}/${file} exists, skip init!"
        return
    fi

    printf '%s' "${setting}" > "${settings_dir}/${file}"
    chmod 0600 "${settings_dir}/${file}"
}

# =============================================================================
# init_settings()
# =============================================================================
# Validates the selected product and initializes the product settings.
#
# The function verifies that the provided product is included in
# PRODUCT_OPTIONS. If supported, the product identifier is stored in the
# settings directory using init_setting and product-specific initialization is
# executed.
#
# For enterprise-container, init_settings_ec is called. For
# security-intelligence, init_settings_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
#   $2
#     Settings directory.
#     Defaults to WORKING_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the selected product is not included in PRODUCT_OPTIONS.
init_settings() {
    local product="${1:-$PRODUCT}"
    local working_dir="${2:-$WORKING_DIR}"

    if [[ " ${PRODUCT_OPTIONS[*]} " =~ " ${product} " ]]; then
        init_setting 'PRODUCT' "${product}" "${working_dir}"
    else
        echo "Error: Product ${product} is not supported only ${PRODUCT_OPTIONS[*]}."
        exit 1
    fi

    if [ "${product}" == 'enterprise-container' ]; then
        init_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_settings_osi
    fi
}

# =============================================================================
# load_setting()
# =============================================================================
# Loads a single setting value from a file and exports it as an environment
# variable.
#
# The function reads the content of the specified setting file from the
# settings directory and assigns it to the provided environment variable.
# If the file does not exist or is empty, the function exits with an error.
#
# Arguments:
#   $1
#     Setting file name.
#
#   $2
#     Environment variable name to export.
#
#   $3
#     Optional settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1
#     If the setting file does not exist or is empty.
load_setting() {
    local setting_file="$1"
    local env_var="$2"
    local settings_dir="${3:-$SETTINGS_DIR}"

    if [ -s "${settings_dir}/${setting_file}" ]; then
        export "${env_var}=$(< "${settings_dir}/${setting_file}")"
    else
        echo "Error: No setting file found or is empty at ${settings_dir}/${setting_file}! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# load_settings()
# =============================================================================
# Loads product-specific settings for the selected OpenVAS product.
#
# The function dispatches settings loading to the corresponding
# product-specific helper based on the provided product name.
#
# For enterprise-container, load_settings_ec is called. For
# security-intelligence, load_settings_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
load_settings() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_settings_osi
    fi
}

# =============================================================================
# init_bridge_subnet_settings()
# =============================================================================
# Initializes and persists the four bridge subnet settings.
#
# Uses the corresponding environment value or built-in default for each
# setting. The values are passed to init_setting(), which persists them unless
# a non-empty setting file already exists and applies its standard permissions.
#
# Arguments:
#   $1  Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   The status of the final init_setting() call.
#
# Exits:
#   1 if a selected subnet value is empty.
init_bridge_subnet_settings() {
    local settings_dir="${1:-$SETTINGS_DIR}"
    local bridge_ingress_subnet_ipv4="${BRIDGE_INGRESS_SUBNET_IPV4:-100.104.0.0/26}"
    local bridge_ingress_subnet_ipv6="${BRIDGE_INGRESS_SUBNET_IPV6:-fd7a:91c3:4e82:1::/64}"
    local bridge_backends_subnet_ipv4="${BRIDGE_BACKENDS_SUBNET_IPV4:-100.104.0.64/26}"
    local bridge_backends_subnet_ipv6="${BRIDGE_BACKENDS_SUBNET_IPV6:-fd7a:91c3:4e82:2::/64}"

    validate_bridge_cidr "${bridge_ingress_subnet_ipv4}" ipv4 'Error: Invalid BRIDGE_INGRESS_SUBNET_IPV4 CIDR.'
    validate_bridge_cidr "${bridge_ingress_subnet_ipv6}" ipv6 'Error: Invalid BRIDGE_INGRESS_SUBNET_IPV6 CIDR.'
    validate_bridge_cidr "${bridge_backends_subnet_ipv4}" ipv4 'Error: Invalid BRIDGE_BACKENDS_SUBNET_IPV4 CIDR.'
    validate_bridge_cidr "${bridge_backends_subnet_ipv6}" ipv6 'Error: Invalid BRIDGE_BACKENDS_SUBNET_IPV6 CIDR.'

    init_setting 'BRIDGE_INGRESS_SUBNET_IPV4' "${bridge_ingress_subnet_ipv4}" "${settings_dir}"
    init_setting 'BRIDGE_INGRESS_SUBNET_IPV6' "${bridge_ingress_subnet_ipv6}" "${settings_dir}"
    init_setting 'BRIDGE_BACKENDS_SUBNET_IPV4' "${bridge_backends_subnet_ipv4}" "${settings_dir}"
    init_setting 'BRIDGE_BACKENDS_SUBNET_IPV6' "${bridge_backends_subnet_ipv6}" "${settings_dir}"
}

# =============================================================================
# load_bridge_subnet_settings()
# =============================================================================
# Loads and exports the four persisted bridge subnet settings.
#
# Each setting is required to have a non-empty file; loading stops at the first
# missing or empty file. Uses load_setting() for file reads and exports.
#
# Arguments:
#   $1  Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   The status of the final load_setting() call.
#
# Exits:
#   1 if any required bridge subnet setting file is missing or empty.
load_bridge_subnet_settings() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    load_setting 'BRIDGE_INGRESS_SUBNET_IPV4' 'BRIDGE_INGRESS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_INGRESS_SUBNET_IPV6' 'BRIDGE_INGRESS_SUBNET_IPV6' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV4' 'BRIDGE_BACKENDS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV6' 'BRIDGE_BACKENDS_SUBNET_IPV6' "${settings_dir}"
}

# =============================================================================
# change_bridge_subnet()
# =============================================================================
# Validates the setting name and requires a non-empty value, then forcibly
# persists the setting with init_setting().
#
# Arguments:
#   $1  One of BRIDGE_INGRESS_SUBNET_IPV4, BRIDGE_INGRESS_SUBNET_IPV6,
#       BRIDGE_BACKENDS_SUBNET_IPV4, or BRIDGE_BACKENDS_SUBNET_IPV6.
#   $2  Non-empty subnet value.
#
# Returns:
#   The status of the final informational message; apply the change with --run.
#
# Exits:
#   1 if either required argument is omitted or the setting name is invalid.
change_bridge_subnet() {
    local setting_name="${1:?Error: Bridge subnet setting name is empty}"
    local setting_value="${2:?Error: Bridge subnet IP address is empty}"

    case "${setting_name}" in
        BRIDGE_INGRESS_SUBNET_IPV4|BRIDGE_BACKENDS_SUBNET_IPV4)
            validate_bridge_cidr "${setting_value}" ipv4 "Error: Invalid ${setting_name} CIDR."
            ;;
        BRIDGE_INGRESS_SUBNET_IPV6|BRIDGE_BACKENDS_SUBNET_IPV6)
            validate_bridge_cidr "${setting_value}" ipv6 "Error: Invalid ${setting_name} CIDR."
            ;;
        *)
            echo "Error: Unsupported bridge subnet setting name: ${setting_name}" >&2
            exit 1
            ;;
    esac

    init_setting "${setting_name}" "${setting_value}" "${SETTINGS_DIR}" 'y'
    echo "Info: To apply the change, please run ${0} --run."
}

# =============================================================================
# change_domain_name()
# =============================================================================
# Persists DOMAIN_NAME, then deploys the configuration.
#
# Checks that the selected domain name is valid, then loads product settings
# before writing DOMAIN_NAME with forced initialization. For
# enterprise-container, the deployment mode must be scan. On success, deploy
# is called; a deployment failure does not undo the write.
#
# Arguments:
#   $1
#     Optional domain name.
#     Defaults to DOMAIN_NAME.
#
#   Also uses MODE, DOMAIN_NAME, DOMAIN_IP, PRODUCT, and loaded product
#   configuration globals.
#
# Returns:
#   The status returned by deploy when deployment completes; does not return
#   after a validation or settings-loading error.
#
# Exits:
#   1 for an empty selected value, unsupported action/product or deployment
#   mode, or a settings-loading error.
change_domain_name() {
    local setting_value="${1:-${DOMAIN_NAME}}"
    if ! [ "${setting_value}" ]; then
        echo 'Error: Domain name is empty! Provide --domain-name.' >&2
        exit 1
    fi
    validate_domain_name "${setting_value}" 'Error: Invalid domain name.'

    load_settings "${PRODUCT}"

    if [ "${PRODUCT}" == 'enterprise-container' ] && [ "${DEPLOYMENT_MODE}" != 'scan' ]; then
        echo "Info: Mode ${MODE} not supported for enterprise-container deployment mode ${DEPLOYMENT_MODE}" >&2
        exit 1
    fi

    init_setting 'DOMAIN_NAME' "${setting_value}" "${SETTINGS_DIR}" 'y'
    deploy
}

# =============================================================================
# change_domain_ip()
# =============================================================================
# Persists DOMAIN_IP, then deploys the configuration.
#
# Checks that the selected value is a valid IP literal, then loads product
# settings and requires scan deployment mode before writing DOMAIN_IP with
# forced initialization. On success, deploy is called; a deployment failure
# does not undo the write.
#
# Arguments:
#   $1
#     Optional domain IP.
#     Defaults to DOMAIN_IP.
#
#   Also uses MODE, DOMAIN_IP, PRODUCT, and loaded product configuration
#   globals.
#
# Returns:
#   The status returned by deploy when deployment completes; does not return
#   after a validation or settings-loading error.
#
# Exits:
#   1 for an empty DOMAIN_IP, unsupported product or deployment mode, or a
#   settings-loading error.
change_domain_ip() {
    local setting_value="${1:-${DOMAIN_IP}}"
    if ! [ "${setting_value}" ]; then
        echo 'Error: Domain IP is empty! Provide --domain-ip.' >&2
        exit 1
    fi
    validate_domain_ip "${setting_value}" 'Error: Invalid domain IP address.'

    load_settings "${PRODUCT}"

    if [ "${DEPLOYMENT_MODE}" != 'scan' ]; then
        echo "Info: Mode ${MODE} not supported for enterprise-container deployment mode ${DEPLOYMENT_MODE}" >&2
        exit 1
    fi

    init_setting 'DOMAIN_IP' "${setting_value}" "${SETTINGS_DIR}" 'y'
    deploy
}
