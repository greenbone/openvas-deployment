# =============================================================================
# validate_logging_backend()
# =============================================================================
# Checks exact membership in LOGGING_BACKEND_OPTIONS; no whitespace or composite
# selectors are accepted. The logical selector is interpreted by the artifact.
# Arguments: $1 - Backend selector (required).
# Exits: 1 if the selector is unsupported, including empty.
validate_logging_backend() {
    local backend="${1-}"
    local option

    for option in "${LOGGING_BACKEND_OPTIONS[@]}"; do
        if [ "${backend}" == "${option}" ]; then
            return 0
        fi
    done
    printf 'Error: Unsupported logging backend: %s. Expected one of: %s.\n' \
        "${backend}" "${LOGGING_BACKEND_OPTIONS[*]}" >&2
    exit 1
}

# =============================================================================
# validate_gmp_sshd_settings()
# =============================================================================
# Validate all four explicit inputs even when disabled: persisted configuration
# must remain complete for a compatible artifact and later enablement.
# Arguments: $1 boolean, $2 IPv4, $3 IPv6, $4 canonical decimal port (1–65535).
# Exits: 1 on invalid input.
validate_gmp_sshd_settings() {
    local gmp_sshd_enable="${1-}"
    local openvas_gmp_sshd_listen_addr="${2-}"
    local openvas_gmp_sshd_listen_addr_ipv6="${3-}"
    local openvas_gmp_sshd_listen_port="${4-}"

    if [[ "${gmp_sshd_enable}" != true && "${gmp_sshd_enable}" != false ]]; then
        printf 'Error: GMP_SSHD_ENABLE must be true or false.\n' >&2
        exit 1
    fi
    validate_ipv4_address "${openvas_gmp_sshd_listen_addr}" 'Error: OPENVAS_GMP_SSHD_LISTEN_ADDR must be an IPv4 literal.'
    validate_ipv6_address "${openvas_gmp_sshd_listen_addr_ipv6}" 'Error: OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6 must be an IPv6 literal.'
    # Bound the string before arithmetic to avoid overflow and octal ambiguity.
    if [[ ! "${openvas_gmp_sshd_listen_port}" =~ ^[1-9][0-9]{0,4}$ ]] ||
        (( 10#${openvas_gmp_sshd_listen_port} > 65535 )); then
        printf 'Error: OPENVAS_GMP_SSHD_LISTEN_PORT must be a canonical decimal port from 1 to 65535.\n' >&2
        exit 1
    fi
}

# =============================================================================
# init_settings_scan()
# =============================================================================
# Validates and persists EC scan configuration without overwriting an
# existing nonempty setting. Explicit empty input must not select the default.
# Arguments: $1 - Backend, defaults to LOGGING_BACKEND only when omitted.
#            $2 - Settings directory, defaults to SETTINGS_DIR.
#            $3 - JSON max size, defaults to LOGGING_BACKEND_JSON_FILE_MAX_SIZE.
#            $4 - JSON max files, defaults to LOGGING_BACKEND_JSON_FILE_MAX_FILE.
#            $5–$8 - GMP_SSHD_ENABLE, OPENVAS_GMP_SSHD_LISTEN_ADDR,
#                     OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6, OPENVAS_GMP_SSHD_LISTEN_PORT.
# New inputs default to their globals only when omitted, preserving empties.
# Exits: 1 if the selector or SSHD inputs are invalid, or a setting is empty.
init_settings_scan() {
    local logging_backend="${1-${LOGGING_BACKEND}}"
    local settings_dir="${2:-$SETTINGS_DIR}"
    local logging_backend_json_file_max_size="${3-${LOGGING_BACKEND_JSON_FILE_MAX_SIZE}}"
    local logging_backend_json_file_max_file="${4-${LOGGING_BACKEND_JSON_FILE_MAX_FILE}}"
    local gmp_sshd_enable="${5-${GMP_SSHD_ENABLE}}"
    local openvas_gmp_sshd_listen_addr="${6-${OPENVAS_GMP_SSHD_LISTEN_ADDR}}"
    local openvas_gmp_sshd_listen_addr_ipv6="${7-${OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6}}"
    local openvas_gmp_sshd_listen_port="${8-${OPENVAS_GMP_SSHD_LISTEN_PORT}}"

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
# even with runtime defaults makes migration explicit through --init.
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
