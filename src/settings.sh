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
#   1 if the setting file name or setting value is empty.
init_setting() {
    local file="${1:?Error: Setting file name is empty}"
    local setting="${2:?Error: Setting $file is empty}"
    local settings_dir="${3:-$SETTINGS_DIR}"
    local force="${4:-n}"

    if [ -s "${settings_dir}/${file}" ] && [ "${force}" == "n" ]; then
        chmod 0600 "${settings_dir}/${file}"
        echo "Info: Setting ${settings_dir}/${file} exists, skip init!"
        return
    fi

    printf '%s' "${setting}" > "${settings_dir}/${file}"
    chmod 0600 "${settings_dir}/${file}"
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
    local working_dir="${1:-$WORKING_DIR}"

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
