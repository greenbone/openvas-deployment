# =============================================================================
# init_settings_scan()
# =============================================================================
# Validates and persists EC scan configuration without overwriting an
# existing nonempty setting. Explicit empty input must not select the default.
# Arguments: $1 - Backend, default: default.
#            $2 - Settings directory, defaults to SETTINGS_DIR.
#            $3 - JSON max size, default: 50m.
#            $4 - JSON max files, default: 3.
#            $5–$8 - SSHD enable, IPv4, IPv6, port; defaults: true, 0.0.0.0, ::, 2222.
# Scan inputs prefer positional values, then CLI/global values, then init-only
# defaults. Only unset values fall through, preserving empties for validation.
# Exits: 1 if the selector or SSHD inputs are invalid, or a setting is empty.
init_settings_scan() {
    local logging_backend="${1-${LOGGING_BACKEND-default}}"
    local settings_dir="${2:-$SETTINGS_DIR}"
    local logging_backend_json_file_max_size="${3-${LOGGING_BACKEND_JSON_FILE_MAX_SIZE-50m}}"
    local logging_backend_json_file_max_file="${4-${LOGGING_BACKEND_JSON_FILE_MAX_FILE-3}}"
    local gmp_sshd_enable="${5-${GMP_SSHD_ENABLE-true}}"
    local openvas_gmp_sshd_listen_addr="${6-${OPENVAS_GMP_SSHD_LISTEN_ADDR-0.0.0.0}}"
    local openvas_gmp_sshd_listen_addr_ipv6="${7-${OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6-::}}"
    local openvas_gmp_sshd_listen_port="${8-${OPENVAS_GMP_SSHD_LISTEN_PORT-2222}}"

    validate_logging_backend "${logging_backend}"
    validate_gmp_sshd_settings "${gmp_sshd_enable}" "${openvas_gmp_sshd_listen_addr}" \
        "${openvas_gmp_sshd_listen_addr_ipv6}" "${openvas_gmp_sshd_listen_port}"
    init_setting 'LOGGING_BACKEND' "${logging_backend}" "${settings_dir}"

    init_setting 'LOGGING_BACKEND_JSON_FILE_MAX_SIZE' "${logging_backend_json_file_max_size}" "${settings_dir}"
    init_setting 'LOGGING_BACKEND_JSON_FILE_MAX_FILE' "${logging_backend_json_file_max_file}" "${settings_dir}"
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

    load_setting 'LOGGING_BACKEND' 'LOGGING_BACKEND' "${settings_dir}"
    validate_logging_backend "${LOGGING_BACKEND}"

    load_setting 'GMP_SSHD_ENABLE' 'GMP_SSHD_ENABLE' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR' 'OPENVAS_GMP_SSHD_LISTEN_ADDR' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' 'OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6' "${settings_dir}"
    load_setting 'OPENVAS_GMP_SSHD_LISTEN_PORT' 'OPENVAS_GMP_SSHD_LISTEN_PORT' "${settings_dir}"
    validate_gmp_sshd_settings "${GMP_SSHD_ENABLE}" "${OPENVAS_GMP_SSHD_LISTEN_ADDR}" \
        "${OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6}" "${OPENVAS_GMP_SSHD_LISTEN_PORT}"

    # Only json requires rotation files, load_setting enforces explicit migration.
    if [ "${LOGGING_BACKEND}" == 'json' ]; then
        load_setting 'LOGGING_BACKEND_JSON_FILE_MAX_SIZE' 'LOGGING_BACKEND_JSON_FILE_MAX_SIZE' "${settings_dir}"
        load_setting 'LOGGING_BACKEND_JSON_FILE_MAX_FILE' 'LOGGING_BACKEND_JSON_FILE_MAX_FILE' "${settings_dir}"
    fi
}
