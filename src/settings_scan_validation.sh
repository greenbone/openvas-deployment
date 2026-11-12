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

    validate_gmp_sshd_setting GMP_SSHD_ENABLE "${gmp_sshd_enable}"
    validate_gmp_sshd_setting OPENVAS_GMP_SSHD_LISTEN_ADDR "${openvas_gmp_sshd_listen_addr}"
    validate_gmp_sshd_setting OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6 "${openvas_gmp_sshd_listen_addr_ipv6}"
    validate_gmp_sshd_setting OPENVAS_GMP_SSHD_LISTEN_PORT "${openvas_gmp_sshd_listen_port}"
}

# Shares rules between initialization and single-setting changes.
# Arguments: $1 - SSHD setting name; $2 - value. Exits: 1 on invalid input.
validate_gmp_sshd_setting() {
    local setting_name="${1-}"
    local setting_value="${2-}"

    case "${setting_name}" in
    GMP_SSHD_ENABLE)
        if [[ "${setting_value}" != true && "${setting_value}" != false ]]; then
            printf 'Error: GMP_SSHD_ENABLE must be true or false.\n' >&2
            exit 1
        fi
        ;;
    OPENVAS_GMP_SSHD_LISTEN_ADDR)
        validate_ipv4_address "${setting_value}" 'Error: OPENVAS_GMP_SSHD_LISTEN_ADDR must be an IPv4 literal.'
        ;;
    OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6)
        validate_ipv6_address "${setting_value}" 'Error: OPENVAS_GMP_SSHD_LISTEN_ADDR_IPV6 must be an IPv6 literal.'
        ;;
    OPENVAS_GMP_SSHD_LISTEN_PORT)
        # Bound the string before arithmetic to avoid overflow and octal ambiguity.
        if [[ ! "${setting_value}" =~ ^[1-9][0-9]{0,4}$ ]] ||
            (( 10#${setting_value} > 65535 )); then
            printf 'Error: OPENVAS_GMP_SSHD_LISTEN_PORT must be a canonical decimal port from 1 to 65535.\n' >&2
            exit 1
        fi
        ;;
    *)
        printf 'Error: Unsupported SSHD setting: %s\n' "${setting_name}" >&2
        exit 1
        ;;
    esac
}

# =============================================================================
# validate_logging_setting()
# =============================================================================
# Validate change inputs independently of persistence context before any writes.
# Arguments: $1 - Logging setting name; $2 - Nonempty setting value.
# Exits: 1 on missing, empty, unsupported, or invalid input.
validate_logging_setting() {
    local setting_name="${1-}"
    local setting_value="${2-}"

    if [ -z "${setting_name}" ]; then
        printf 'Error: Logging setting name is empty\n' >&2
        exit 1
    fi
    if [ -z "${setting_value}" ]; then
        printf 'Error: Logging setting value is empty\n' >&2
        exit 1
    fi
    case "${setting_name}" in
        LOGGING_BACKEND)
            validate_logging_backend "${setting_value}"
            ;;
        LOGGING_BACKEND_JSON_FILE_MAX_SIZE|LOGGING_BACKEND_JSON_FILE_MAX_FILE)
            # Rotation values remain opaque nonempty strings, as during init.
            ;;
        *)
            printf 'Error: Unsupported logging setting: %s\n' "${setting_name}" >&2
            exit 1
            ;;
    esac
}
