# =============================================================================
# validate_logging_backend()
# =============================================================================
# Checks exact, case-sensitive membership in LOGGING_BACKEND_OPTIONS (currently
# default, json, journald). Does not normalize selectors or translate Docker
# drivers; the artifact interprets the logical selector.
#
# Arguments:
#   $1  Required nonempty backend. No default.
#
# Returns:
#   0 silently when valid.
#
# Exits:
#   1 with a stderr diagnostic for missing, empty, or unsupported input under
#   project execution.
#
# Side effects:
#   No persistence or global mutation.
validate_logging_backend() {
    local backend="${1:?Error: Logging backend is a empty value}"
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
# validate_logging_setting()
# =============================================================================
# Validates logging changes independently of product, mode, or persistence.
# Delegates backend validation and accepts opaque nonempty rotation strings.
# Rejects keys other than the three logging settings.
#
# Arguments:
#   $1  Required key: LOGGING_BACKEND, LOGGING_BACKEND_JSON_FILE_MAX_SIZE,
#       or LOGGING_BACKEND_JSON_FILE_MAX_FILE. No default.
#   $2  Required nonempty value. No default.
#
# Returns:
#   0 silently when valid.
#
# Exits:
#   1 with a stderr diagnostic for missing/empty arguments, an unsupported key,
#   or an invalid backend under project execution.
#
# Side effects:
#   No persistence or global mutation.
validate_logging_setting() {
    local setting_name="${1:?Error: Logging setting name is empty}"
    local setting_value="${2:?Error: Logging setting value is empty}"

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

# =============================================================================
# validate_domain_name()
# =============================================================================
# Validates a DNS-style hostname, including single-label names such as
# "localhost" and "server", without changing its spelling.
#
# Hostnames must contain one or more dot-separated labels consisting of ASCII
# letters, digits, or hyphens. Each label must start and end with a letter or
# digit and must not exceed 63 characters. The complete hostname must not
# exceed 253 characters. Empty labels, whitespace, and trailing dots are
# not permitted.
#
# Arguments:
#   $1  Hostname to validate.
#   $2  Error message to print on failure.
#
# Returns:
#   0 when valid.
#   Does not normalize or modify the supplied hostname.
#
# Exits:
#   1 when invalid; prints the supplied error message.
#   1 if the error-message argument is unset or empty.
validate_domain_name() {
    local domain_name="${1-}"
    local error_message="${2:?Error: Validation error message is empty}"
    local label
    local -a labels

    [[ "${domain_name}" && "${#domain_name}" -le 253 && "${domain_name}" != *[[:space:]]* && "${domain_name}" != *. ]] || { echo "${error_message}"; exit 1; }

    IFS='.' read -r -a labels <<< "${domain_name}"

    for label in "${labels[@]}"; do
        [[ "${#label}" -le 63 && "${label}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || { echo "${error_message}"; exit 1; }
    done
}

# =============================================================================
# validate_ipv4_address()
# =============================================================================
# Validates a strict dotted-decimal IPv4 literal.
#
# Arguments:
#   $1  IPv4 address to validate.
#   $2  Error message to print on failure.
#
# Returns:
#   0 when valid.
#
# Exits:
#   1 when invalid; prints the supplied error message.
#   1 if the error-message argument is unset or empty.
validate_ipv4_address() {
    local address="${1-}"
    local error_message="${2:?Error: Validation error message is empty}"

    ipv4_valid "${address}" || { echo "${error_message}"; exit 1; }
}

# =============================================================================
# validate_ipv6_address()
# =============================================================================
# Validates an IPv6 literal, including valid IPv4-mapped IPv6 forms.
#
# Arguments:
#   $1  IPv6 address to validate.
#   $2  Error message to print on failure.
#
# Returns:
#   0 when valid.
#
# Exits:
#   1 when invalid; prints the supplied error message.
#   1 if the error-message argument is unset or empty.
validate_ipv6_address() {
    local address="${1-}"
    local error_message="${2:?Error: Validation error message is empty}"

    ipv6_valid "${address}" || { echo "${error_message}"; exit 1; }
}

# =============================================================================
# validate_domain_ip()
# =============================================================================
# Validates an IPv4 or IPv6 address literal.
#
# Arguments:
#   $1  Address literal to validate.
#   $2  Error message to print on failure.
#
# Returns:
#   0 when valid.
#
# Exits:
#   1 when invalid; prints the supplied error message.
#   1 if the error-message argument is unset or empty.
validate_domain_ip() {
    local address="${1-}"
    local error_message="${2:?Error: Validation error message is empty}"

    if ipv4_valid "${address}"; then
        return 0
    fi
    ipv6_valid "${address}" || { echo "${error_message}"; exit 1; }
}

# =============================================================================
# validate_bridge_cidr()
# =============================================================================
# Validates a CIDR address and prefix, allowing host bits to be set.
#
# Arguments:
#   $1  CIDR value.
#   $2  Required address family (ipv4 or ipv6).
#   $3  Error message to print on failure.
#
# Returns:
#   0 when valid.
#
# Exits:
#   1 when invalid; prints the supplied error message.
#   1 if the error-message argument is unset or empty.
validate_bridge_cidr() {
    local cidr="${1-}"
    local family="${2-}"
    local error_message="${3:?Error: Validation error message is empty}"
    local address prefix maximum_prefix

    [[ "${cidr}" && "${cidr}" != *[[:space:]]* && ( "${family}" == ipv4 || "${family}" == ipv6 ) ]] || { echo "${error_message}"; exit 1; }
    [[ "${cidr}" == */* && "${cidr#*/}" != */* ]] || { echo "${error_message}"; exit 1; }
    address="${cidr%/*}"
    prefix="${cidr#*/}"

    if [[ "${family}" == ipv4 ]]; then
        ipv4_valid "${address}" || { echo "${error_message}"; exit 1; }
        maximum_prefix=32
    else
        ipv6_valid "${address}" || { echo "${error_message}"; exit 1; }
        maximum_prefix=128
    fi

    [[ "${prefix}" =~ ^(0|[1-9][0-9]{0,2})$ ]] || { echo "${error_message}"; exit 1; }
    ((10#${prefix} <= maximum_prefix)) || { echo "${error_message}"; exit 1; }
}

# =============================================================================
# ipv4_valid()
# =============================================================================
# Returns whether the argument is a strict dotted-decimal IPv4 address: four
# decimal octets from 0 through 255, with no leading zeroes except for zero.
#
# Arguments:
#   $1  IPv4 address to validate; unset defaults to empty.
#
# Returns:
#   0 when valid; 1 when invalid. Does not print an error or exit.
ipv4_valid() {
    local address="${1-}"
    local octet
    local -a octets

    [[ -n "${address}" &&
       "${address}" != *[[:space:]]* &&
       "${address}" != *. ]] || return 1

    IFS='.' read -r -a octets <<< "${address}"
    ((${#octets[@]} == 4)) || return 1

    for octet in "${octets[@]}"; do
        [[ "${octet}" =~ ^(0|[1-9][0-9]{0,2})$ ]] || return 1
        ((10#${octet} <= 255)) || return 1
    done

    return 0
}

# =============================================================================
# ipv6_valid()
# =============================================================================
# Returns whether the argument is a valid IPv6 literal, including IPv4-mapped
# forms with a strict dotted-decimal IPv4 suffix. Compressed forms must use one
# `::` and omit at least one of the eight address groups.
#
# Arguments:
#   $1  IPv6 address to validate; unset defaults to empty.
#
# Returns:
#   0 when valid; 1 when invalid. Does not print an error or exit.
ipv6_valid() {
    local address="${1-}"
    local left right ipv4_part group left_count=0 right_count=0
    local -a groups

    [[ "${address}" && "${address}" == *:* && "${address}" != *[[:space:]]* ]] || return 1
    [[ "${address}" != *::* || "${address#*::}" != *::* ]] || return 1
    [[ "${address}" != *:::* ]] || return 1

    if [[ "${address}" == *.* ]]; then
        ipv4_part="${address##*:}"
        ipv4_valid "${ipv4_part}" || return 1
        address="${address%:*}:0:0"
    fi

    if [[ "${address}" == *::* ]]; then
        left="${address%%::*}"
        right="${address#*::}"
        [[ -z "${left}" || "${left}" != :* && "${left}" != *: ]] || return 1
        [[ -z "${right}" || "${right}" != :* && "${right}" != *: ]] || return 1

        if [[ "${left}" ]]; then
            IFS=':' read -r -a groups <<< "${left}"
            left_count=${#groups[@]}
            for group in "${groups[@]}"; do
                [[ "${group}" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
            done
        fi

        if [[ "${right}" ]]; then
            IFS=':' read -r -a groups <<< "${right}"
            right_count=${#groups[@]}
            for group in "${groups[@]}"; do
                [[ "${group}" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
            done
        fi

        ((left_count + right_count < 8))
        return
    fi

    [[ "${address}" != :* && "${address}" != *: ]] || return 1
    IFS=':' read -r -a groups <<< "${address}"
    ((${#groups[@]} == 8)) || return 1
    for group in "${groups[@]}"; do
        [[ "${group}" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
    done
}

# =============================================================================
# validate_port()
# =============================================================================
# Validates a canonical decimal port without normalization or writes.
# Arguments: $1 - Port (unset defaults to empty); $2 - Required error message.
# Returns: 0 silently when valid; 1 with the supplied message on stderr otherwise.
# Exits: 1 if the error-message argument is unset or empty.
validate_port() {
    local port="${1-}"
    local error_message="${2:?Error: Validation error message is empty}"

    # Bound the string before arithmetic to avoid overflow and octal ambiguity.
    if [[ ! "${port}" =~ ^[1-9][0-9]{0,4}$ ]] ||
        (( 10#${port} > 65535 )); then
        printf '%s\n' "${error_message}" >&2
        return 1
    fi
    return 0
}

# Shares ingress rules between initialization, loading, and changes.
# Arguments: $1 - ingress setting name; $2 - value. Exits: 1 on invalid input.
validate_ingress_setting() {
    local setting_name="${1:?Error: Ingress setting name is empty}"
    local setting_value="${2:?Error: Ingress setting value is empty}"

    case "${setting_name}" in
    INGRESS_LISTEN_ADDR)
        validate_ipv4_address "${setting_value}" 'Error: INGRESS_LISTEN_ADDR must be an IPv4 literal.'
        ;;
    INGRESS_LISTEN_ADDR_IPV6)
        validate_ipv6_address "${setting_value}" 'Error: INGRESS_LISTEN_ADDR_IPV6 must be an IPv6 literal.'
        ;;
    INGRESS_LISTEN_PORT)
        validate_port "${setting_value}" 'Error: INGRESS_LISTEN_PORT must be a canonical decimal port from 1 to 65535.' || exit 1
        ;;
    *)
        printf 'Error: Unsupported ingress setting: %s\n' "${setting_name}" >&2
        exit 1
        ;;
    esac
}
