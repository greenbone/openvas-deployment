# =============================================================================
# init_settings_ec()
# =============================================================================
# Validates and stores the settings required for EC scan deployments.
#
# The function verifies that DEPLOYMENT_MODE, FEED_MODE, and CCERT_MODE are
# included in their respective supported option lists and persists the selected
# values in SETTINGS_DIR using init_setting().
#
# Mount-based feed and CCERT modes are currently rejected. Depending on
# CCERT_MODE, the function stores the corresponding CCERT_TYPE and then
# initializes the configured feed synchronization hour.
#
# If DEPLOYMENT_MODE is set to 'openvasd', the corresponding openvasd settings
# are initialized as well.
# Bridge subnet settings are initialized with EC ingress and backends defaults;
# EC does not initialize VI-proxy subnets.
#
# Arguments:
#   $1  Deployment mode. Defaults to DEPLOYMENT_MODE.
#   $2  Feed mode. Defaults to FEED_MODE.
#   $3  CCERT mode. Defaults to CCERT_MODE.
#   $4  Feed path. Defaults to FEED_PATH.
#   $5  CCERT path. Defaults to CCERT_PATH.
#   $6  Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if DEPLOYMENT_MODE is not supported.
#   1 if FEED_MODE is not supported.
#   1 if CCERT_MODE is not supported.
#   1 if FEED_MODE is set to 'mount'.
#   1 if CCERT_MODE is set to 'mount'.
# =============================================================================
# init_bridge_subnet_settings_ec()
# =============================================================================
# Validates and initializes the EC ingress and backends bridge subnet settings.
# IPv4/IPv6 values default to the EC subnets; explicit environment values take
# precedence, while existing nonempty setting files are preserved.
# EC does not initialize VI-proxy subnet settings.
#
# Arguments:
#   $1 - Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if any ingress or backends subnet CIDR is invalid.
# =============================================================================
init_bridge_subnet_settings_ec() {
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
# load_bridge_subnet_settings_ec()
# =============================================================================
# Loads and exports the required EC ingress and backends bridge subnet settings.
# VI-proxy subnet settings are not read or exported for EC.
#
# Arguments:
#   $1 - Settings directory. Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if a required bridge subnet setting is missing or empty.
load_bridge_subnet_settings_ec() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    load_setting 'BRIDGE_INGRESS_SUBNET_IPV4' 'BRIDGE_INGRESS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_INGRESS_SUBNET_IPV6' 'BRIDGE_INGRESS_SUBNET_IPV6' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV4' 'BRIDGE_BACKENDS_SUBNET_IPV4' "${settings_dir}"
    load_setting 'BRIDGE_BACKENDS_SUBNET_IPV6' 'BRIDGE_BACKENDS_SUBNET_IPV6' "${settings_dir}"
}

init_settings_ec() {
    local deployment_mode="${1:-$DEPLOYMENT_MODE}"
    local feed_mode="${2:-$FEED_MODE}"
    local ccert_mode="${3:-$CCERT_MODE}"
    local feed_path="${4:-$FEED_PATH}"
    local ccert_path="${5:-$CCERT_PATH}"
    local settings_dir="${6:-$SETTINGS_DIR}"

    echo 'Info: Init settings EC'
    init_bridge_subnet_settings_ec "${settings_dir}"

    if [[ " ${DEPLOYMENT_MODE_OPTIONS[*]} " =~ " ${deployment_mode} " ]]; then
        init_setting "DEPLOYMENT_MODE" "${deployment_mode}" "${settings_dir}"
    else
        echo "Error: Deployment mode ${deployment_mode} is not supported only ${DEPLOYMENT_MODE_OPTIONS[*]}."
        exit 1
    fi

    if [[ " ${FEED_MODE_OPTIONS[*]} " =~ " ${feed_mode} " ]]; then
        init_setting "FEED_MODE" "${feed_mode}" "${settings_dir}"
    else
        echo "Error: feed mode option ${feed_mode} is not supported only ${FEED_MODE_OPTIONS[*]}."
        exit 1
    fi

    if [[ " ${CCERT_MODE_OPTIONS[*]} " =~ " ${ccert_mode} " ]]; then
        init_setting "CCERT_MODE" "${ccert_mode}" "${settings_dir}"
    else
        echo "Error: feed mode option ${ccert_mode} is not supported only ${CCERT_MODE_OPTIONS[*]}."
        exit 1
    fi

    if [ "${feed_mode}" == 'mount' ]; then
        if [ -d "${feed_path}" ]; then
            echo "Error: feed mode option mount is not supported currently!"
        else
            echo "Error: feed path ${feed_path} does not exist!"
        fi
        exit 1
    fi

    if [ "${ccert_mode}" == 'mount' ]; then
        if [ -d "${ccert_path}" ]; then
            echo "Error: ccert mode option mount is not supported currently!"
        else
            echo "Error: ccert path ${ccert_path} does not exist!"
        fi
        exit 1
    fi

    if [ "${ccert_mode}" == 'ca' ] || [ "${ccert_mode}" == 'cert' ]; then
        init_setting "CCERT_TYPE" "env" "${settings_dir}"
    else
        init_setting "CCERT_TYPE" "mount" "${settings_dir}"
    fi

    init_feed_sync_hour

    if [ "${deployment_mode}" == 'openvasd' ]; then
        init_settings_openvasd
    else
        init_settings_agent
    fi
}

# =============================================================================
# load_settings_ec()
# =============================================================================
# Loads the enterprise-container deployment settings.
#
# The function loads and exports EC ingress and backends bridge subnet settings;
# VI-proxy subnet settings are not loaded or exported for EC.
#
# The function loads the persisted deployment configuration values from the
# settings directory and exports them as environment variables using the
# generic load_setting() helper.
#
# Depending on the selected feed and certificate modes, additional mount paths
# are loaded. If the deployment mode is openvasd, the OpenVASD-specific settings
# are loaded using load_settings_openvasd().
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if a required setting file is missing or empty.
load_settings_ec() {
    echo 'Info: Load settings EC'
    load_bridge_subnet_settings_ec

    load_setting "DEPLOYMENT_MODE" "DEPLOYMENT_MODE"
    load_setting "FEED_MODE" "FEED_MODE"
    load_setting "CCERT_MODE" "CCERT_MODE"

    if [ "${FEED_MODE}" == 'mount' ]; then
        load_setting "FEED_PATH" "FEED_PATH"
    fi

    if [ "${CCERT_MODE}" == 'mount' ]; then
        load_setting "CCERT_PATH" "CCERT_PATH"
    fi

    load_setting "CCERT_TYPE" "CCERT_TYPE"
    load_setting "GREENBONE_FEED_SYNC_JOB_HOUR" "GREENBONE_FEED_SYNC_JOB_HOUR"

    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_settings_openvasd
    else
        load_settings_agent
    fi
}
