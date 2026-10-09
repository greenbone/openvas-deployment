# =============================================================================
# valid_domain_name()
# =============================================================================
# Validates a DNS host name, including single labels and an optional final dot.
#
# Labels may contain ASCII letters, digits, and interior hyphens. Each label
# must be at most 63 characters, and the name without its final dot must be at
# most 253 characters.
#
# Arguments:
#   $1
#     DNS host name to validate.
#
# Returns:
#   0 if the host name is valid, otherwise 1.
#
# Exits:
#   1 if the host name argument is missing or empty.
valid_domain_name() {
    local name="${1:?Error: Domain name is empty}"
    local label
    local -a labels=()

    name="${name%.}"
    [ -n "${name}" ] && [ "${#name}" -le 253 ] || return 1
    [[ "${name}" != .* && "${name}" != *. && "${name}" != *..* ]] || return 1
    IFS='.' read -r -a labels <<< "${name}"
    for label in "${labels[@]}"; do
        [ "${#label}" -le 63 ] &&
            [[ "${label}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] || return 1
    done
    [[ "${name}" != *$'\n'* ]]
}

# =============================================================================
# valid_ipv4()
# =============================================================================
# Validates a dotted-decimal IPv4 address.
#
# The address must contain four octets from 0 through 255 without ambiguous
# leading zeroes.
#
# Arguments:
#   $1
#     IPv4 address to validate.
#
# Returns:
#   0 if the address is valid, otherwise 1.
#
# Exits:
#   1 if the address argument is missing or empty.
valid_ipv4() {
    local address="${1:?Error: IPv4 address is empty}"
    local octet
    local -a octets=()

    [[ "${address}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    IFS='.' read -r -a octets <<< "${address}"
    for octet in "${octets[@]}"; do
        [[ "${octet}" =~ ^(0|[1-9][0-9]{0,2})$ ]] &&
            [ "${octet}" -le 255 ] || return 1
    done
}

# =============================================================================
# valid_ipv6()
# =============================================================================
# Validates a bare IPv6 address, including compression and an embedded IPv4 tail.
#
# A dotted-decimal tail occupies two of the eight 16-bit groups. Compression
# must replace at least one group. Brackets and zone identifiers are not accepted.
#
# Arguments:
#   $1
#     IPv6 address to validate.
#
# Returns:
#   0 if the address is valid, otherwise 1.
#
# Exits:
#   1 if the address argument is missing or empty.
valid_ipv6() {
    local address="${1:?Error: IPv6 address is empty}"
    local group
    local compressed='n'
    local -a groups=()

    [[ "${address}" == *:* ]] || return 1
    if [[ "${address}" == *.* ]]; then
        valid_ipv4 "${address##*:}" || return 1
        address="${address%:*}:0:0"
    fi
    [[ "${address}" =~ ^[0-9a-fA-F:]+$ ]] || return 1
    [[ "${address}" != :* || "${address}" == ::* ]] || return 1
    [[ "${address}" != *: || "${address}" == *:: ]] || return 1
    if [[ "${address}" == *::* ]]; then
        compressed='y'
        address="${address/::/:}"
        [[ "${address}" != *::* ]] || return 1
        address="${address#:}"
        address="${address%:}"
    else
        [[ "${address}" != :* && "${address}" != *: ]] || return 1
    fi
    IFS=':' read -r -a groups <<< "${address}"
    for group in "${groups[@]}"; do
        [[ "${group}" =~ ^[0-9a-fA-F]{1,4}$ ]] || return 1
    done
    if [ "${compressed}" == 'y' ]; then
        [ "${#groups[@]}" -lt 8 ]
    else
        [ "${#groups[@]}" -eq 8 ]
    fi
}

# =============================================================================
# validate_domain_setting()
# =============================================================================
# Validates domain name and IP address settings.
#
# DOMAIN_NAME must be a valid DNS host name, and DOMAIN_IP must be a valid IPv4
# or IPv6 address. Other settings require no validation by this helper.
# Initialization and change_setting call this helper through init_setting,
# before its existing-file check so invalid input cannot silently be skipped.
#
# Arguments:
#   $1
#     Setting name.
#
#   $2
#     Setting value to validate.
#
# Returns:
#   None.
#
# Exits:
#   1 if the setting name or value is empty, or the domain name or IP address
#   is invalid.
validate_domain_setting() {
    local name="${1:?Error: Setting name is empty}"
    local value="${2:?Error: Setting $name is empty}"

    case "${name}" in
        DOMAIN_NAME)
            if ! valid_domain_name "${value}"; then
                echo "Error: Domain name ${value} must be a valid DNS host name." >&2
                exit 1
            fi
            ;;
        DOMAIN_IP)
            if ! valid_ipv4 "${value}" && ! valid_ipv6 "${value}"; then
                echo "Error: Domain IP ${value} must be a valid IPv4 or IPv6 address." >&2
                exit 1
            fi
            ;;
    esac
}
