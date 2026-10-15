# =============================================================================
# init_settings_osi()
# =============================================================================
# Initializes the domain setting required by the OSI deployment.
#
# The function validates that a domain name is provided and stores it in the
# product settings directory using init_setting(). Existing settings are kept
# unless explicitly forced by init_setting(). It initializes bridge subnet
# settings with the security-intelligence ingress and backends defaults; explicit
# subnet options take precedence, while existing nonempty setting files remain
# unchanged.
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
# =============================================================================
# init_bridge_subnet_settings_osi()
# =============================================================================
# Validates and initializes the OSI ingress, backends, and VI-proxy bridge
# subnet settings. IPv4/IPv6 values default to the OSI subnets; explicit
# environment values take precedence, while existing nonempty setting files
# are preserved.
#
# Arguments:
#   $1 - Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if any ingress, backends, or VI-proxy subnet CIDR is invalid.
init_bridge_subnet_settings_osi() {
    local settings_dir="${1:-$SETTINGS_DIR}"
    local bridge_ingress_subnet_ipv4="${BRIDGE_INGRESS_SUBNET_IPV4:-100.104.1.0/26}"
    local bridge_ingress_subnet_ipv6="${BRIDGE_INGRESS_SUBNET_IPV6:-fd7a:91c3:4e83:1::/64}"
    local bridge_backends_subnet_ipv4="${BRIDGE_BACKENDS_SUBNET_IPV4:-100.104.1.64/26}"
    local bridge_backends_subnet_ipv6="${BRIDGE_BACKENDS_SUBNET_IPV6:-fd7a:91c3:4e83:2::/64}"
    local bridge_vi_proxy_subnet_ipv4="${BRIDGE_VI_PROXY_SUBNET_IPV4:-100.104.1.128/26}"
    local bridge_vi_proxy_subnet_ipv6="${BRIDGE_VI_PROXY_SUBNET_IPV6:-fd7a:91c3:4e83:3::/64}"

    validate_bridge_cidr "${bridge_ingress_subnet_ipv4}" ipv4 'Error: Invalid BRIDGE_INGRESS_SUBNET_IPV4 CIDR.'
    validate_bridge_cidr "${bridge_ingress_subnet_ipv6}" ipv6 'Error: Invalid BRIDGE_INGRESS_SUBNET_IPV6 CIDR.'
    validate_bridge_cidr "${bridge_backends_subnet_ipv4}" ipv4 'Error: Invalid BRIDGE_BACKENDS_SUBNET_IPV4 CIDR.'
    validate_bridge_cidr "${bridge_backends_subnet_ipv6}" ipv6 'Error: Invalid BRIDGE_BACKENDS_SUBNET_IPV6 CIDR.'
    validate_bridge_cidr "${bridge_vi_proxy_subnet_ipv4}" ipv4 'Error: Invalid BRIDGE_VI_PROXY_SUBNET_IPV4 CIDR.'
    validate_bridge_cidr "${bridge_vi_proxy_subnet_ipv6}" ipv6 'Error: Invalid BRIDGE_VI_PROXY_SUBNET_IPV6 CIDR.'

    init_setting 'BRIDGE_INGRESS_SUBNET_IPV4' "${bridge_ingress_subnet_ipv4}" "${settings_dir}"
    init_setting 'BRIDGE_INGRESS_SUBNET_IPV6' "${bridge_ingress_subnet_ipv6}" "${settings_dir}"
    init_setting 'BRIDGE_BACKENDS_SUBNET_IPV4' "${bridge_backends_subnet_ipv4}" "${settings_dir}"
    init_setting 'BRIDGE_BACKENDS_SUBNET_IPV6' "${bridge_backends_subnet_ipv6}" "${settings_dir}"
    init_setting 'BRIDGE_VI_PROXY_SUBNET_IPV4' "${bridge_vi_proxy_subnet_ipv4}" "${settings_dir}"
    init_setting 'BRIDGE_VI_PROXY_SUBNET_IPV6' "${bridge_vi_proxy_subnet_ipv6}" "${settings_dir}"
}

# =============================================================================
# load_bridge_subnet_settings_osi()
# =============================================================================
# Loads and exports the required OSI ingress, backends, and VI-proxy bridge
# subnet settings.
#
# Arguments:
#   $1 - Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if a required bridge subnet setting is missing or empty.
load_bridge_subnet_settings_osi() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    load_setting 'BRIDGE_INGRESS_SUBNET_IPV4' 'BRIDGE_INGRESS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_INGRESS_SUBNET_IPV6' 'BRIDGE_INGRESS_SUBNET_IPV6' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV4' 'BRIDGE_BACKENDS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV6' 'BRIDGE_BACKENDS_SUBNET_IPV6' "${settings_dir}"
    load_setting 'BRIDGE_VI_PROXY_SUBNET_IPV4' 'BRIDGE_VI_PROXY_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_VI_PROXY_SUBNET_IPV6' 'BRIDGE_VI_PROXY_SUBNET_IPV6' "${settings_dir}"
}

init_settings_osi() {
    local domain_name="${1:-$DOMAIN_NAME}"
    local settings_dir="${2:-$SETTINGS_DIR}"

    echo 'Info: Init settings OSI'
    init_bridge_subnet_settings_osi "${settings_dir}"

    if ! [ "${domain_name}" ]; then
        echo "Error: Domain name not set! Run --init with --domain-name!"
        exit 1
    fi

    validate_domain_name "${domain_name}" 'Error: Invalid domain name.'
    init_setting "DOMAIN_NAME" "${domain_name}" "${settings_dir}"
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
    load_bridge_subnet_settings_osi

    load_setting "DOMAIN_NAME" "DOMAIN_NAME"
}
