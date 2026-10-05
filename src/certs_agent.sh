# =============================================================================
# init_certs_agent()
# =============================================================================
# Initializes the TLS certificate and private key pair for ingress agent control.
#
# The source certificate and private key paths can be provided as function
# arguments. If omitted or empty, the corresponding environment variables are
# used. The destination directory can also be overridden and defaults to the
# product certificate directory.
#
# The certificate pair is initialized by init_certs_ingress_pair() using
# "ingress_agent_control" as the destination certificate name.
#
# Arguments:
#   $1 - Optional path to the ingress agent-control certificate.
#        Default: $INGRESS_AGENT_CONTROL_CERT.
#   $2 - Optional path to the ingress agent-control private key.
#        Default: $INGRESS_AGENT_CONTROL_KEY.
#   $3 - Optional destination directory for the certificate pair.
#        Default: $CERT_DIR_PRODUCT.
#
# Returns:
#   None.
init_certs_agent() {
    local ingress_agent_control_cert="${1:-$INGRESS_AGENT_CONTROL_CERT}"
    local ingress_agent_control_key="${2:-$INGRESS_AGENT_CONTROL_KEY}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"

    init_certs_ingress_pair "${ingress_agent_control_cert}" "${ingress_agent_control_key}" "${cert_dir_product}" 'ingress_agent_control'
}

# =============================================================================
# load_certs_agent()
# =============================================================================
# Loads the ingress agent-control TLS certificate and private key.
#
# The certificate and private key are loaded from the product certificate
# directory using load_cert() and assigned to
# OPENVAS_INGRESS_AGENT_CONTROL_CERTIFICATE and
# OPENVAS_INGRESS_AGENT_CONTROL_KEY, respectively.
#
# Arguments:
#   $1 - Optional directory containing the ingress agent-control certificate
#        and private key. Default: $CERT_DIR_PRODUCT.
#
# Returns:
#   None.
load_certs_agent() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    load_cert "ingress_agent_control.crt" "OPENVAS_INGRESS_AGENT_CONTROL_CERTIFICATE" "${cert_dir_product}"
    load_cert "ingress_agent_control.key" "OPENVAS_INGRESS_AGENT_CONTROL_KEY" "${cert_dir_product}"
}

# =============================================================================
# update_ingress_certs_agent()
# =============================================================================
# Updates the ingress agent-control TLS certificate and private key.
#
# The source certificate and private key paths can be provided as function
# arguments. If omitted or empty, the corresponding environment variables are
# used. The certificate pair is installed in the product certificate directory
# using init_certs_ingress_pair() with "ingress_agent_control" as the
# destination certificate name.
#
# Both source files must exist and be non-empty. Otherwise, the function exits
# with an error.
#
# The fourth argument controls whether the ingress agent-control container is
# recreated after the certificates are installed. If omitted or empty, it
# defaults to UPDATE_INGRESS_CERT_REDEPLOY. If that value is also empty, the
# user is prompted whether to recreate the container. The container is
# recreated only when the resulting value is "y".
#
# Arguments:
#   $1 - Optional path to the ingress agent-control certificate.
#        Default: $INGRESS_AGENT_CONTROL_CERT.
#   $2 - Optional path to the ingress agent-control private key.
#        Default: $INGRESS_AGENT_CONTROL_KEY.
#   $3 - Optional destination directory for the certificate pair.
#        Default: $CERT_DIR_PRODUCT.
#   $4 - Optional ingress agent-control container redeploy setting.
#        Default: $UPDATE_INGRESS_CERT_REDEPLOY.
#
# Returns:
#   None.
#
# Exits:
#   1 if the ingress agent-control certificate is missing or empty.
#   1 if the ingress agent-control private key is missing or empty.
update_ingress_certs_agent() {
    local ingress_agent_control_cert="${1:-$INGRESS_AGENT_CONTROL_CERT}"
    local ingress_agent_control_key="${2:-$INGRESS_AGENT_CONTROL_KEY}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"
    local update_ingress_cert_redeploy="${4:-$UPDATE_INGRESS_CERT_REDEPLOY}"

    if [ -s "${ingress_agent_control_cert}" ] && [ -s "${ingress_agent_control_key}" ]; then
        init_certs_ingress_pair "${ingress_agent_control_cert}" "${ingress_agent_control_key}" "${cert_dir_product}" 'ingress_agent_control'
    elif [ ! -s "${ingress_agent_control_cert}" ]; then
        echo "Error: --ingress-agent-control-cert argument missing or file ${ingress_agent_control_cert} not found! Required for --update-ingress-certs-agent !"
        exit 1
    elif [ ! -s "${ingress_agent_control_key}" ]; then
        echo "Error: --ingress-agent-control-key argument missing or file ${ingress_agent_control_key} not found! Required for --update-ingress-certs-agent !"
        exit 1
    fi

    if ! [ "${update_ingress_cert_redeploy}" ]; then
        read -r -p "Info: Redeploy the ingress container, to activate the new Ingress certificates? (y/n)" update_ingress_cert_redeploy
    fi
    if [ "${update_ingress_cert_redeploy}" == "y" ]; then
        compose_recreate_container 'ingress-agent-control'
    fi
}
