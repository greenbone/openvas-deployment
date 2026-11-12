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
