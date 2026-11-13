# =============================================================================
# change_gmp_sshd_setting()
# =============================================================================
# Changes one existing scan SSHD setting without loading unrelated settings.
# Arguments: $1 - SSHD key; $2 - nonempty value.
# Exits: 1 on invalid input/context or missing settings.
# Side effects: overwrites only the target with mode 0600; prints --run advice.
change_gmp_sshd_setting() {
    local setting_name="${1-}"
    local setting_value="${2-}"
    local persisted_deployment_mode

    validate_gmp_sshd_setting "${setting_name}" "${setting_value}"
    # Persisted mode, not a CLI override, controls eligibility.
    load_setting DEPLOYMENT_MODE persisted_deployment_mode "${SETTINGS_DIR}"
    if [ "${persisted_deployment_mode}" != scan ]; then
        printf 'Error: Scan setting changes require scan deployment mode.\n' >&2
        exit 1
    fi

    init_setting "${setting_name}" "${setting_value}" "${SETTINGS_DIR}" y
    echo "Info: To apply the change, please run ${0} --run."
}

# =============================================================================
# init_settings_scan()
# =============================================================================
# Validates and persists EC scan configuration without overwriting an
# existing nonempty setting.
# Arguments: $1 - SSHD enable, default: true.
#            $2 - Settings directory, defaults to SETTINGS_DIR.
#            $3–$5 - SSHD IPv4, IPv6, port; defaults: 0.0.0.0, ::, 2222.
# Inputs prefer positional values, then CLI/global values, then init-only
# defaults; unset or empty inputs are treated as unspecified.
# Exits: 1 if SSHD inputs are invalid or empty.
init_settings_scan() {
    local settings_dir="${2:-$SETTINGS_DIR}"
    local gmp_sshd_enable="${1:-${GMP_SSHD_ENABLE:-true}}"
    local openvas_gmp_sshd_listen_addr="${3:-${OPENVAS_GMP_SSHD_LISTEN_ADDR:-0.0.0.0}}"
    local openvas_gmp_sshd_listen_addr_ipv6="${4:-${OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6:-::}}"
    local openvas_gmp_sshd_listen_port="${5:-${OPENVAS_GMP_SSHD_LISTEN_PORT:-2222}}"
    validate_gmp_sshd_setting 'GMP_SSHD_ENABLE' "${gmp_sshd_enable}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR' "${openvas_gmp_sshd_listen_addr}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' "${openvas_gmp_sshd_listen_addr_ipv6}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_PORT' "${openvas_gmp_sshd_listen_port}"

    init_setting 'GMP_SSHD_ENABLE' "${gmp_sshd_enable}" "${settings_dir}"
    init_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR' "${openvas_gmp_sshd_listen_addr}" "${settings_dir}"
    init_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' "${openvas_gmp_sshd_listen_addr_ipv6}" "${settings_dir}"
    init_setting 'OPENVAS_GMP_SSHD_LISTEN_PORT' "${openvas_gmp_sshd_listen_port}" "${settings_dir}"
}

# =============================================================================
# load_settings_scan()
# =============================================================================
# Loads, exports, and validates persisted EC scan configuration. Requiring files
# makes initialization or migration explicit through --init.
# Arguments: $1 - Settings directory, defaults to SETTINGS_DIR.
# Exits: 1 for a missing, empty, or unsupported setting.
load_settings_scan() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    load_setting 'GMP_SSHD_ENABLE' 'GMP_SSHD_ENABLE' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR' 'OPENVAS_GMP_SSHD_LISTEN_ADDR' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_PORT' 'OPENVAS_GMP_SSHD_LISTEN_PORT' "${settings_dir}"

    validate_gmp_sshd_setting 'GMP_SSHD_ENABLE' "${GMP_SSHD_ENABLE}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR' "${OPENVAS_GMP_SSHD_LISTEN_ADDR}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' "${OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6}"
    validate_gmp_sshd_setting 'OPENVAS_GMP_SSHD_LISTEN_PORT' "${OPENVAS_GMP_SSHD_LISTEN_PORT}"
}
