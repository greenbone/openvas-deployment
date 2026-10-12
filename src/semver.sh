# =============================================================================
# normalize_semver()
# =============================================================================
# Validates and normalizes a strict SemVer 2.0.0 version string.
#
# An optional lowercase "v" prefix is accepted and removed from the output.
#
# Arguments:
#   $1
#     Version string in strict SemVer 2.0.0 format, optionally prefixed with "v".
#
# Outputs:
#   The validated version string without the optional "v" prefix.
#
# Returns:
#   0 on success; 1 if the version is invalid (with an error message on stderr).
normalize_semver() {
    local version="$1"
    local semver_pattern='^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(([0-9]|[1-9][0-9]*)|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(\.(([0-9]|[1-9][0-9]*)|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

    if [[ ! "$version" =~ $semver_pattern ]]; then
        echo "Error: Invalid version '${version}'. Expected SemVer 2.0.0." >&2
        return 1
    fi
    printf '%s\n' "${version#v}"
}

# =============================================================================
# semver_greater()
# =============================================================================
# Compares two normalized SemVer version strings.
#
# Arguments:
#   $1
#     Left-hand version.
#
#   $2
#     Right-hand version.
#
# Outputs:
#   None.
#
# Returns:
#   0 if the left-hand version is greater; 1 otherwise.
semver_greater() {
    local left="$1"
    local right="$2"
    local LC_ALL=C
    local left_core left_pre right_core right_pre
    local left_part right_part
    local -a left_core_parts right_core_parts left_pre_parts right_pre_parts
    local i count

    left_core="${left%%+*}"
    right_core="${right%%+*}"
    left_pre=''
    right_pre=''
    if [[ "${left_core}" == *-* ]]; then
        left_pre="${left_core#*-}"
        left_core="${left_core%%-*}"
    fi
    if [[ "${right_core}" == *-* ]]; then
        right_pre="${right_core#*-}"
        right_core="${right_core%%-*}"
    fi

    IFS='.' read -ra left_core_parts <<< "${left_core}"
    IFS='.' read -ra right_core_parts <<< "${right_core}"
    for i in 0 1 2; do
        left_part="${left_core_parts[i]}"
        right_part="${right_core_parts[i]}"
        if [ "${#left_part}" -ne "${#right_part}" ]; then
            [ "${#left_part}" -gt "${#right_part}" ]
            return
        fi
        if [ "${left_part}" != "${right_part}" ]; then
            [[ "${left_part}" > "${right_part}" ]]
            return
        fi
    done

    if [ -z "${left_pre}" ] || [ -z "${right_pre}" ]; then
        [ -n "${left_pre}" ] && return 1
        [ -n "${right_pre}" ] && return 0
        return 1
    fi

    IFS='.' read -ra left_pre_parts <<< "${left_pre}"
    IFS='.' read -ra right_pre_parts <<< "${right_pre}"
    count="${#left_pre_parts[@]}"
    [ "${#right_pre_parts[@]}" -gt "${count}" ] && count="${#right_pre_parts[@]}"
    for ((i = 0; i < count; i++)); do
        if [ "${i}" -ge "${#left_pre_parts[@]}" ]; then
            return 1
        fi
        if [ "${i}" -ge "${#right_pre_parts[@]}" ]; then
            return 0
        fi
        left_part="${left_pre_parts[i]}"
        right_part="${right_pre_parts[i]}"
        if [[ "${left_part}" =~ ^[0-9]+$ ]] && [[ "${right_part}" =~ ^[0-9]+$ ]]; then
            if [ "${#left_part}" -ne "${#right_part}" ]; then
                [ "${#left_part}" -gt "${#right_part}" ]
                return
            fi
        elif [[ "${left_part}" =~ ^[0-9]+$ ]]; then
            return 1
        elif [[ "${right_part}" =~ ^[0-9]+$ ]]; then
            return 0
        fi
        if [ "${left_part}" != "${right_part}" ]; then
            [[ "${left_part}" > "${right_part}" ]]
            return
        fi
    done
    [ "${#left_pre_parts[@]}" -gt "${#right_pre_parts[@]}" ]
}
