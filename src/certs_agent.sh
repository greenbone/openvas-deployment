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
