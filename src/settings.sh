# =============================================================================
# init_setting()
# =============================================================================
# Initializes a single setting file with the provided value.
#
# The function writes the given setting value to the specified settings file
# and applies restrictive file permissions. If the setting file already exists
# and force initialization is disabled, the existing value is preserved and
# initialization is skipped.
#
# Arguments:
#   $1
#     Setting file name.
#
#   $2
#     Setting value to write.
#
#   $3
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
#   $4
#     Force initialization flag.
#     Defaults to "n".
#     If set to "n", existing non-empty setting files are not overwritten.
#
# Returns:
#   None.
#
# Exits:
#   1 if the setting file name or setting value is empty, or a domain is invalid.
init_setting() {
    local file="${1:?Error: Setting file name is empty}"
    local setting="${2:?Error: Setting $file is empty}"
    local settings_dir="${3:-$SETTINGS_DIR}"
    local force="${4:-n}"

    validate_domain_setting "${file}" "${setting}"

    if [ -s "${settings_dir}/${file}" ] && [ "${force}" == 'n' ]; then
        chmod 0600 "${settings_dir}/${file}"
        echo "Info: Setting ${settings_dir}/${file} exists, skip init!"
        return
    fi

    printf '%s' "${setting}" > "${settings_dir}/${file}"
    chmod 0600 "${settings_dir}/${file}"
}

# =============================================================================
# list_settings()
# =============================================================================
# Prints saved settings as NAME=VALUE pairs in filename order. Only regular,
# non-symlink files with valid setting names are included. An empty settings
# directory produces no output.
#
# Arguments:
#   $1
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the settings directory does not exist or a setting cannot be read.
list_settings() {
    local settings_dir="${1:-$SETTINGS_DIR}"
    local file
    local name
    local value

    if [ ! -d "${settings_dir}" ]; then
        echo "Error: No settings directory found at ${settings_dir}! Please run --init!" >&2
        exit 1
    fi

    for file in "${settings_dir}"/*; do
        name="${file##*/}"
        if [[ "${name}" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [ -f "${file}" ] && [ ! -L "${file}" ]; then
            value=$(< "${file}")
            printf '%s=%s\n' "${name}" "${value}"
        fi
    done
}

# =============================================================================
# change_setting()
# =============================================================================
# Replaces an existing setting for the selected product. Names must be uppercase
# environment variable identifiers; values are stored literally and must not be
# empty. Product and mode values must be supported, and the feed synchronization
# hour must be an integer from 0 through 23. Domain names and IPv4/IPv6 addresses
# are validated by init_setting. Only regular, non-symlink setting
# files may be updated.
#
# Arguments:
#   $1
#     Setting name.
#     Defaults to SETTING_NAME.
#
#   $2
#     Setting value.
#     Defaults to SETTING_VALUE.
#
#   $3
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the name or value is invalid, or the setting does not exist.
change_setting() {
    local name="${1:-$SETTING_NAME}"
    local value="${2:-$SETTING_VALUE}"
    local settings_dir="${3:-$SETTINGS_DIR}"
    local option
    local supported='n'
    local -a options=()

    if [[ ! "${name}" =~ ^[A-Z_][A-Z0-9_]*$ ]] || [ -z "${value}" ]; then
        echo "Error: A valid setting NAME and a non-empty VALUE are required." >&2
        exit 1
    fi

    if [ ! -f "${settings_dir}/${name}" ] || [ -L "${settings_dir}/${name}" ]; then
        echo "Error: No regular setting file found at ${settings_dir}/${name}! Use an existing setting name." >&2
        exit 1
    fi

    case "${name}" in
        PRODUCT) options=("${PRODUCT_OPTIONS[@]}") ;;
        DEPLOYMENT_MODE) options=("${DEPLOYMENT_MODE_OPTIONS[@]}") ;;
        FEED_MODE) options=("${FEED_MODE_OPTIONS[@]}") ;;
        CCERT_MODE) options=("${CCERT_MODE_OPTIONS[@]}") ;;
        GREENBONE_FEED_SYNC_JOB_HOUR)
            if [[ ! "${value}" =~ ^([01]?[0-9]|2[0-3])$ ]]; then
                echo "Error: Feed sync hour ${value} needs to be an integer between 0 and 23." >&2
                exit 1
            fi
            ;;
    esac

    if [ "${#options[@]}" -gt 0 ]; then
        for option in "${options[@]}"; do
            if [ "${value}" == "${option}" ]; then
                supported='y'
                break
            fi
        done
        if [ "${supported}" != 'y' ]; then
            echo "Error: ${name} value ${value} is not supported, only ${options[*]}." >&2
            exit 1
        fi
    fi

    init_setting "${name}" "${value}" "${settings_dir}" 'y'
    echo "Info: Setting ${name} updated. Run --run to apply the change."
}

# =============================================================================
# init_settings()
# =============================================================================
# Validates the selected product and initializes the product settings.
#
# The function verifies that the provided product is included in
# PRODUCT_OPTIONS. If supported, the product identifier is stored in the
# settings directory using init_setting and product-specific initialization is
# executed.
#
# For enterprise-container, init_settings_ec is called. For
# security-intelligence, init_settings_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
#   $2
#     Settings directory.
#     Defaults to WORKING_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the selected product is not included in PRODUCT_OPTIONS.
init_settings() {
    local product="${1:-$PRODUCT}"
    local working_dir="${2:-$WORKING_DIR}"

    if [[ " ${PRODUCT_OPTIONS[*]} " =~ " ${product} " ]]; then
        init_setting 'PRODUCT' "${product}" "${working_dir}"
    else
        echo "Error: Product ${product} is not supported only ${PRODUCT_OPTIONS[*]}."
        exit 1
    fi

    if [ "${product}" == 'enterprise-container' ]; then
        init_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_settings_osi
    fi
}

# =============================================================================
# load_setting()
# =============================================================================
# Loads a single setting value from a file and exports it as an environment
# variable.
#
# The function reads the content of the specified setting file from the
# settings directory and assigns it to the provided environment variable.
# If the file does not exist or is empty, the function exits with an error.
#
# Arguments:
#   $1
#     Setting file name.
#
#   $2
#     Environment variable name to export.
#
#   $3
#     Optional settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1
#     If a required argument is missing or empty, or the setting file does not
#     exist or is empty.
load_setting() {
    local setting_file="${1:?Error: Setting file name is empty}"
    local env_var="${2:?Error: Environment variable name is empty}"
    local settings_dir="${3:-$SETTINGS_DIR}"

    if [ -s "${settings_dir}/${setting_file}" ]; then
        export "${env_var}=$(< "${settings_dir}/${setting_file}")"
    else
        echo "Error: No setting file found or is empty at ${settings_dir}/${setting_file}! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# load_settings()
# =============================================================================
# Loads product-specific settings for the selected OpenVAS product.
#
# The function dispatches settings loading to the corresponding
# product-specific helper based on the provided product name.
#
# For enterprise-container, load_settings_ec is called. For
# security-intelligence, load_settings_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
load_settings() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_settings_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_settings_osi
    fi
}
