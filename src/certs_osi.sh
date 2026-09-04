# =============================================================================
# init_certs_osi()
# =============================================================================
# Initializes the metafeed TLS certificate and private key used by OSI.
#
# If the provided metafeed certificate or private key exists, the function
# installs it into the product certificate directory with appropriate file
# permissions. Missing files produce warnings but do not terminate execution.
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
#     Product certificate directory.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
init_certs_osi() {
    local metafeed_cert="${1:-$METAFEED_CERT}"
    local metafeed_key="${2:-$METAFEED_KEY}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"

    if [ -f "${metafeed_cert}" ]; then
        install -m 0644 "${metafeed_cert}" "${cert_dir_product}/metafeed.crt"
    else
        echo "Warn: Missing argument --osi-metafeed-cert !"
    fi
    if [ -f "${metafeed_key}" ]; then
        install -m 0600 "${metafeed_key}" "${cert_dir_product}/metafeed.key"
    else
        echo "Warn: Missing argument --osi-metafeed-key !"
    fi
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
