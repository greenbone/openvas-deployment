# =============================================================================
# validate_domain_name()
# =============================================================================
# Validates a DNS fully-qualified domain name without changing its spelling.
#
# Arguments:
#   $1  Domain name to validate.
#   $2  Error message to print on failure.
#
# Returns:
#   0 when valid.
#   Does not normalize or modify the supplied domain name.
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
    ((${#labels[@]} >= 2)) || { echo "${error_message}"; exit 1; }

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

    [[ "${address}" && "${address}" != *[[:space:]]* ]] || return 1
    IFS='.' read -r -a octets <<< "${address}"
    ((${#octets[@]} == 4)) || return 1
    for octet in "${octets[@]}"; do
        [[ "${octet}" =~ ^(0|[1-9][0-9]{0,2})$ ]] || return 1
        ((10#${octet} <= 255)) || return 1
    done
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
