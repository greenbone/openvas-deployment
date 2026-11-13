# Shares rules between initialization and single-setting changes.
# Arguments: $1 - SSHD setting name; $2 - value. Exits: 1 on invalid input.
validate_gmp_sshd_setting() {
    local setting_name="${1:?Error: Gmp sshd setting name is empty}"
    local setting_value="${2:?Error: Gmp sshd  setting value is empty}"

    case "${setting_name}" in
    GMP_SSHD_ENABLE)
        if [[ "${setting_value}" != 'true' && "${setting_value}" != 'false' ]]; then
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
        validate_port "${setting_value}" 'Error: OPENVAS_GMP_SSHD_LISTEN_PORT must be a canonical decimal port from 1 to 65535.' || exit 1
        ;;
    *)
        printf 'Error: Unsupported SSHD setting: %s\n' "${setting_name}" >&2
        exit 1
        ;;
    esac
}
