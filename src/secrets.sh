init_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        init_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_secrets_osi
    fi
}

load_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_secrets_osi
    fi
}
