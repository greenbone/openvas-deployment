# =============================================================================
# init_certs_openvasd()
# =============================================================================
# Initializes the certificate directory for an OpenVASD instance and installs
# the required TLS certificates and keys.
#
# The function derives a dedicated certificate folder from the OpenVASD common
# name (CN), creates the directory, and installs the provided server
# certificate, server private key, and client CA certificate with appropriate
# file permissions.
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     OpenVASD server certificate path.
#     Defaults to OPENVASD_SERVER_CERT.
#
#   $3
#     OpenVASD server private key path.
#     Defaults to OPENVASD_SERVER_KEY.
#
#   $4
#     Product certificate directory.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD server certificate, server key, or client CA certificate
#   is missing.
init_certs_openvasd() {
    local openvasd_cn="${1:-$CN_OPENVASD}"
    local openvasd_client_ca="${1:-$OPENVASD_CLIENT_CA}"
    local openvasd_server_cert="${2:-$OPENVASD_SERVER_CERT}"
    local openvasd_server_key="${3:-$OPENVASD_SERVER_KEY}"
    local cert_dir_product="${4:-$CERT_DIR_PRODUCT}"

    local openvasd_cert_folder="${openvasd_cn//./_}"
    local cert_dir_openvasd="${cert_dir_product}/${openvasd_cert_folder}"

    mkdir -p "${cert_dir_openvasd}"

    if [ -f "${openvasd_server_cert}" ]; then
        install -m 0644 "${openvasd_server_cert}" "${cert_dir_openvasd}/server.crt"
    else
        echo "Error: Missing argument --openvasd-server-cert !"
        exit 1
    fi
    if [ -f "${openvasd_server_key}" ]; then
        install -m 0600 "${openvasd_server_key}" "${cert_dir_openvasd}/server.key"
    else
        echo "Error: Missing argument --openvasd-server-key !"
        exit 1
    fi
    if [ -f "${openvasd_client_ca}" ]; then
        install -m 0600 "${openvasd_client_ca}" "${cert_dir_openvasd}/ca.crt"
    else
        echo "Error: Missing argument --openvasd-client-ca !"
        exit 1
    fi
}

# =============================================================================
# load_certs_openvasd()
# =============================================================================
# Loads the TLS certificate, private key, and client CA certificate for an
# OpenVASD instance.
#
# The function derives the OpenVASD-specific certificate directory from the
# configured common name (CN), reads the required certificate files, and
# exports their contents for use by the OpenVAS scanner service.
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     Product certificate directory.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD server certificate, server private key, or client CA
#   certificate is missing.
load_certs_openvasd() {
    local openvasd_cn="${1:-$CN_OPENVASD}"
    local cert_dir_product="${2:-$CERT_DIR_PRODUCT}"

    local openvasd_cert_folder="${openvasd_cn//./_}"
    local cert_dir_openvasd="${cert_dir_product}/${openvasd_cert_folder}"

    if [ -f "${cert_dir_openvasd}/server.crt" ]; then
        export OPENVAS_SCANNER_TLS_CERT="$(< "${cert_dir_openvasd}/server.crt")"
    else
        echo "Error: No enterprise-container TLS certificate found at ${cert_dir_openvasd}/server.crt! Please run --init --deployment-mode openvasd!"
        exit 1
    fi
    if [ -f "${cert_dir_openvasd}/server.key" ]; then
        export OPENVAS_SCANNER_TLS_KEY="$(< "${cert_dir_openvasd}/server.key")"
    else
        echo "Error: No enterprise-container TLS private key found at ${cert_dir_openvasd}/server.key! Please run --init --deployment-mode openvasd!"
        exit 1
    fi
    if [ -f "${cert_dir_openvasd}/ca.crt" ]; then
        export OPENVAS_TLS_CLIENT_CA="$(< "${cert_dir_openvasd}/ca.crt")"
    else
        echo "Error: No enterprise-container TLS CA certificate found at ${cert_dir_openvasd}/ca.crt! Please run --init --deployment-mode openvasd!"
        exit 1
    fi
}
