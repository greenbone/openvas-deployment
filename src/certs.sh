# =============================================================================
# init_certs()
# =============================================================================
# Initializes the required certificate sets for the selected product and
# deployment mode.
#
# For the enterprise-container product, the function initializes scan and
# ingress certificates when running in scan mode, or OpenVASD certificates
# when running in openvasd mode.
#
# For the security-intelligence product, the function initializes ingress and
# OSI certificates.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
init_certs() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        init_certs_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_certs_osi
    fi
}

# =============================================================================
# init_certs_ingress()
# =============================================================================
# Initializes the TLS certificate and private key used by the ingress service.
#
# If both INGRESS_TLS_SERVER_CERT and INGRESS_TLS_SERVER_KEY point to existing
# files, the function installs them into CERT_DIR_PRODUCT with restrictive file
# permissions.
#
# If either file is missing, the function generates a self-signed RSA
# certificate and private key for the ingress service. The generated
# certificate is valid for 365 days and uses the common name
# "openvas-enterprise-container".
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_certs_ingress() {
    if [ -f "${INGRESS_TLS_SERVER_CERT}" ] && [ -f "${INGRESS_TLS_SERVER_KEY}" ]; then
        echo "Info: Using Ingress certs ${INGRESS_TLS_SERVER_CERT} and ${INGRESS_TLS_SERVER_KEY} ..."
        install -m 0600 "${INGRESS_TLS_SERVER_CERT}" "${CERT_DIR_PRODUCT}/ingress_server.crt"
        install -m 0600 "${INGRESS_TLS_SERVER_KEY}" "${CERT_DIR_PRODUCT}/ingress_server.key"
    else
        echo "Info: Create self sign Ingress certs!"
        openssl genrsa -out "${CERT_DIR_PRODUCT}/ingress_server.key" 2048 2>/dev/null
        openssl req -new -x509 -key "${CERT_DIR_PRODUCT}/ingress_server.key" -out "${CERT_DIR_PRODUCT}/ingress_server.crt" -days 365 \
           -addext "basicConstraints=CA:FALSE" -addext "extendedKeyUsage=serverAuth" -addext "keyUsage=digitalSignature,keyEncipherment" \
           -subj "/CN=openvas-enterprise-container" 2>/dev/null
    fi
}

# =============================================================================
# init_oci_certs()
# =============================================================================
# Validates and installs the OCI TLS client certificate and private key.
#
# The function verifies that both the configured OCI client certificate and
# private key exist, then installs them into CERT_DIR_OCI using restrictive
# file permissions.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if OCI_TLS_CLIENT_CERT is not set to an existing file.
#   1 if OCI_TLS_CLIENT_KEY is not set to an existing file.
init_oci_certs(){
    if ! [ -f "${OCI_TLS_CLIENT_CERT}" ]; then
        echo "Error: --oci-client-cert argument missing or file ${OCI_TLS_CLIENT_CERT} not found!"
        exit 1
    fi
    if ! [ -f "${OCI_TLS_CLIENT_KEY}" ]; then
        echo "Error: --oci-client-key argument missing or file ${OCI_TLS_CLIENT_KEY} not found!"
        exit 1
    fi

    install -m 0600 "${OCI_TLS_CLIENT_CERT}" "${CERT_DIR_OCI}/client.crt"
    install -m 0600 "${OCI_TLS_CLIENT_KEY}" "${CERT_DIR_OCI}/client.key"
}

# =============================================================================
# load_cert()
# =============================================================================
# Loads a certificate or key file into an environment variable.
#
# The function verifies that the specified file exists and is not empty, then
# exports its contents to the requested environment variable. The certificate
# directory can be overridden by passing a custom directory path.
#
# Arguments:
#   $1  File name to load from the certificate directory.
#   $2  Environment variable name to export the file contents to.
#   $3  Optional certificate directory (defaults to CERT_DIR).
#
# Returns:
#   None.
#
# Exits:
#   1 if the specified certificate/key file does not exist or is empty.
load_cert() {
    local cert_file="$1"
    local env_var="$2"
    local certs_dir="${3:-$CERT_DIR}"

    if [ -s "${certs_dir}/${cert_file}" ]; then
        export "${env_var}=$(< "${certs_dir}/${cert_file}")"
    else
        echo "Error: No certificate found or is empty at ${certs_dir}/${cert_file}! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# load_certs()
# =============================================================================
# Loads the certificate configuration required for the selected product.
#
# The function dispatches certificate loading to the product-specific helper
# based on PRODUCT.
#
# For enterprise-container, load_certs_ec is called. For security-intelligence,
# load_certs_osi is called.
#
# Arguments:
#   None.
#
# Returns:
#   None.
load_certs() {
    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        load_certs_ec
    elif [ "${PRODUCT}" == 'security-intelligence' ]; then
        load_certs_osi
    fi
}

# =============================================================================
# load_certs_ingress()
# =============================================================================
# Loads the ingress TLS certificate and private key from the product
# certificate directory.
#
# The function loads the ingress server certificate and private key using the
# generic load_cert() helper and exports their contents as environment
# variables for use by ingress TLS configuration and agent control
# communication.
#
# The same ingress TLS certificate and private key are exported for both the
# ingress service and the OpenVAS ingress agent control configuration.
#
# Arguments:
#   $1  Optional product certificate directory (defaults to CERT_DIR_PRODUCT).
#
# Returns:
#   None.
#
# Exits:
#   1 if the ingress TLS certificate file does not exist or is empty.
#   1 if the ingress TLS private key file does not exist or is empty.
load_certs_ingress() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    load_cert "ingress_server.crt" "INGRESS_CERTIFICATE" "${cert_dir_product}"
    load_cert "ingress_server.key" "INGRESS_PRIVATE_KEY" "${cert_dir_product}"
    load_cert "ingress_server.crt" "OPENVAS_INGRESS_AGENT_CONTROL_CERTIFICATE" "${cert_dir_product}"
    load_cert "ingress_server.key" "OPENVAS_INGRESS_AGENT_CONTROL_KEY" "${cert_dir_product}"
}

# =============================================================================
# update_ingress_certs()
# =============================================================================
# Updates the ingress TLS certificate and private key.
#
# The function validates the configured ingress server certificate and private
# key, then installs them into CERT_DIR_PRODUCT with restrictive permissions.
#
# The first argument controls whether the ingress container is recreated after
# the certificates are installed and defaults to UPDATE_INGRESS_CERT_REDEPLOY.
# If neither value is set, the user is prompted whether to recreate the ingress
# container. The container is recreated only when the resulting value is "y".
#
# Arguments:
#   $1
#     Optional ingress container redeploy setting.
#     Defaults to UPDATE_INGRESS_CERT_REDEPLOY.
#
# Returns:
#   None.
#
# Exits:
#   1 if INGRESS_TLS_SERVER_CERT does not reference an existing file.
#   1 if INGRESS_TLS_SERVER_KEY does not reference an existing file.
update_ingress_certs() {
    local update_ingress_cert_redeploy="${1:-$UPDATE_INGRESS_CERT_REDEPLOY}"

    if ! [ -f "${INGRESS_TLS_SERVER_CERT}" ]; then
        echo "Error: --ingress-server-cert argument missing or file ${INGRESS_TLS_SERVER_CERT} not found! Required for --update-ingress-certs !"
        exit 1
    fi
    if ! [ -f "${INGRESS_TLS_SERVER_KEY}" ]; then
        echo "Error: --ingress-server-key argument missing or file ${INGRESS_TLS_SERVER_KEY} not found! Required for --update-ingress-certs !"
        exit 1
    fi
    install -m 0600 "${INGRESS_TLS_SERVER_CERT}" "${CERT_DIR_PRODUCT}/ingress_server.crt"
    install -m 0600 "${INGRESS_TLS_SERVER_KEY}" "${CERT_DIR_PRODUCT}/ingress_server.key"

    if ! [ "${update_ingress_cert_redeploy}" ]; then
        read -r -p "Info: Redeploy the ingress container, to activate the new Ingress certificates? (y/n)" update_ingress_cert_redeploy
    fi
    if [ "${update_ingress_cert_redeploy}" == "y" ]; then
        compose_recreate_container 'ingress'
    fi
}
