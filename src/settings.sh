# =============================================================================
# init_settings()
# =============================================================================
# Validates the selected product and initializes its product-specific settings.
#
# The function verifies that the provided product is included in
# PRODUCT_OPTIONS. If supported, the product name is stored in WORKING_DIR and
# initialization is dispatched to the corresponding product-specific settings
# function.
#
# For enterprise-container, init_settings_ec is called. For
# security-intelligence, init_settings_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the selected product is not included in PRODUCT_OPTIONS.
init_settings() {
    local product="${1:-$PRODUCT}"

    if [[ " ${PRODUCT_OPTIONS[*]} " =~ " ${product} " ]]; then
        echo "${product}" > "${WORKING_DIR}/PRODUCT"
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
