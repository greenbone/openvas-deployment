# =============================================================================
# init_secrets()
# =============================================================================
# Initializes product-specific secrets for the selected OpenVAS product.
#
# The function dispatches secret initialization to the corresponding
# product-specific helper based on the provided product name.
#
# For enterprise-container, init_secrets_ec is called. For
# security-intelligence, init_secrets_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
init_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        init_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_secrets_osi
    fi
}

# =============================================================================
# load_secrets()
# =============================================================================
# Loads product-specific secrets for the selected OpenVAS product.
#
# The function dispatches secret loading to the corresponding product-specific
# helper based on the provided product name.
#
# For enterprise-container, load_secrets_ec is called. For
# security-intelligence, load_secrets_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
load_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_secrets_osi
    fi
}
