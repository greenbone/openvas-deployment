# =============================================================================
# init_certs_osi()
# =============================================================================
# Initializes the metafeed TLS certificate and private key used by OSI.
#
# The function first installs the explicitly configured metafeed certificate
# and private key, if both files exist. Otherwise, it falls back to the OCI
# client certificate and private key, if both are available.
#
# The selected certificate and key are installed into the product certificate
# directory as metafeed.crt and metafeed.key with appropriate file permissions.
# If neither certificate/key pair is complete, a warning is emitted and
# execution continues.
#
# After handling the OSI metafeed certificate and key, the function initializes
# the ingress certificates by calling init_certs_ingress.
#
# Arguments:
#   $1
#     Metafeed certificate path.
#     Defaults to METAFEED_CERT.
#
#   $2
#     Metafeed private key path.
#     Defaults to METAFEED_KEY.
#
#   $3
#     OCI certificate directory containing client.crt and client.key.
#     Defaults to CERT_DIR_OCI.
#
#   $4
#     Product certificate directory.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
init_certs_osi() {
    local metafeed_cert="${1:-$METAFEED_CERT}"
    local metafeed_key="${2:-$METAFEED_KEY}"
    local cert_dir_oci="${3:-$CERT_DIR_OCI}"
    local cert_dir_product="${4:-$CERT_DIR_PRODUCT}"

    echo 'Info: Init certs OSI'

    if [ -f "${metafeed_cert}" ] && [ -f "${metafeed_key}" ]; then
        install -m 0644 "${metafeed_cert}" "${cert_dir_product}/metafeed.crt"
        install -m 0600 "${metafeed_key}" "${cert_dir_product}/metafeed.key"
    elif [ -f "${cert_dir_oci}/client.crt" ] && [ -f "${cert_dir_oci}/client.key" ]; then
        install -m 0644 "${cert_dir_oci}/client.crt" "${cert_dir_product}/metafeed.crt"
        install -m 0600 "${cert_dir_oci}/client.key" "${cert_dir_product}/metafeed.key"
    else
        echo "Warn: Metafeed certificate and key not found. Provide both --metafeed-cert and --metafeed-key, or install client.crt and client.key in ${cert_dir_oci}."
    fi
    init_certs_ingress
}

# =============================================================================
# load_certs_osi()
# =============================================================================
# Loads the TLS certificate configuration required for OSI.
#
# The function reads the metafeed client certificate and private key from the
# product certificate directory and exports their contents for use by OSI.
# If either metafeed certificate file is missing, a warning is printed and the
# corresponding environment variable is exported as an empty string.
#
# The function also loads the ingress TLS certificate configuration.
#
# Arguments:
#   None.
#
# Returns:
#   None.
load_certs_osi() {
    local cert_dir_product="${2:-$CERT_DIR_PRODUCT}"

    echo 'Info: Load certs OSI'

    if [ -f "${cert_dir_product}/metafeed.crt" ]; then
        export METAFEED_CLIENT_CERT="$(< "${cert_dir_product}/metafeed.crt")"
    else
        echo "Warn: No Metafeed TLS certificate found at ${cert_dir_product}/metafeed.crt! Please run --init!"
        export METAFEED_CLIENT_CERT=''
    fi
    if [ -f "${cert_dir_product}/metafeed.key" ]; then
        export METAFEED_CLIENT_KEY="$(< "${cert_dir_product}/metafeed.key")"
    else
        echo "Warn: No Metafeed TLS key found at ${cert_dir_product}/metafeed.key! Please run --init!"
        export METAFEED_CLIENT_KEY=''
    fi
    load_certs_ingress
}
