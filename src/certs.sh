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
# Initializes the TLS certificate and private key pair for the ingress server.
#
# The source certificate and private key paths can be provided as function
# arguments. If omitted or empty, the corresponding environment variables are
# used. The destination directory can also be overridden and defaults to the
# product certificate directory.
#
# The certificate pair is initialized by init_certs_ingress_pair() using
# "ingress_server" as the destination certificate name.
#
# Arguments:
#   $1 - Optional path to the ingress TLS server certificate.
#        Default: $INGRESS_TLS_SERVER_CERT.
#   $2 - Optional path to the ingress TLS server private key.
#        Default: $INGRESS_TLS_SERVER_KEY.
#   $3 - Optional destination directory for the certificate pair.
#        Default: $CERT_DIR_PRODUCT.
#
# Returns:
#   None.
init_certs_ingress() {
    local ingress_tls_server_cert="${1:-$INGRESS_TLS_SERVER_CERT}"
    local ingress_tls_server_key="${2:-$INGRESS_TLS_SERVER_KEY}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"

    init_certs_ingress_pair "${ingress_tls_server_cert}" "${ingress_tls_server_key}" "${cert_dir_product}" 'ingress_server'
}

# =============================================================================
# init_certs_ingress_pair()
# =============================================================================
# Initializes a TLS certificate and private key pair for an ingress endpoint.
#
# If both source certificate and private key files exist and are non-empty,
# installs them into the destination directory as <cert_name>.crt and
# <cert_name>.key with file mode 0600.
#
# Otherwise, if either destination file is missing or empty, generates a
# self-signed certificate and EC private key using the prime256v1 curve. The
# certificate is valid for 365 days, uses "openvas-enterprise-container" as
# its common name, is restricted to TLS server authentication, and includes
# "openvas-enterprise-container", "localhost", and "127.0.0.1" as subject
# alternative names. The generated files are assigned mode 0600.
#
# If neither usable source files are provided and both destination files
# already exist and are non-empty, leaves the existing files unchanged.
#
# Arguments:
#   $1 - Path to the source TLS server certificate.
#   $2 - Path to the source TLS server private key.
#   $3 - Optional destination directory. Defaults to $CERT_DIR_PRODUCT.
#   $4 - Required base name for the destination files. The resulting files are
#        <cert_name>.crt and <cert_name>.key.
#
# Returns:
#   None.
init_certs_ingress_pair() {
    local ingress_tls_server_cert="${1}"
    local ingress_tls_server_key="${2}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"
    local cert_name="${4:?Error: certificate name is required}"

    if [ -s "${ingress_tls_server_cert}" ] && [ -s "${ingress_tls_server_key}" ]; then
        echo "Info: Using Ingress certs ${ingress_tls_server_cert} and ${ingress_tls_server_key} ..."
        install -m 0600 "${ingress_tls_server_cert}" "${cert_dir_product}/${cert_name}.crt"
        install -m 0600 "${ingress_tls_server_key}" "${cert_dir_product}/${cert_name}.key"
    else
        if [ ! -s "${cert_dir_product}/${cert_name}.key" ] || [ ! -s "${cert_dir_product}/${cert_name}.crt" ]; then
            echo "Info: Create self sign Ingress certs (${cert_name})!"
            openssl ecparam \
                -name prime256v1 \
                -genkey \
                -noout \
                -out "${cert_dir_product}/${cert_name}.key" \
            2>/dev/null

            openssl req \
                -new \
                -x509 \
                -key "${cert_dir_product}/${cert_name}.key" \
                -out "${cert_dir_product}/${cert_name}.crt" \
                -sha256 \
                -days 365 \
                -subj "/CN=openvas-enterprise-container" \
                -addext "basicConstraints=CA:FALSE" \
                -addext "extendedKeyUsage=serverAuth" \
                -addext "keyUsage=digitalSignature" \
                -addext "subjectAltName=DNS:openvas-enterprise-container,DNS:localhost,IP:127.0.0.1" \
            2>/dev/null
            chmod 0600 "${cert_dir_product}/${cert_name}.key" "${cert_dir_product}/${cert_name}.crt"
        else
            echo "Info: Ingress certs ${cert_dir_product}/${cert_name}.key ${cert_dir_product}/${cert_name}.crt exists, skip init!"
        fi
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
# Loads the ingress server TLS certificate and private key.
#
# The certificate and private key are loaded from the product certificate
# directory using load_cert() and assigned to INGRESS_CERTIFICATE and
# INGRESS_PRIVATE_KEY, respectively.
#
# Arguments:
#   $1 - Optional directory containing the ingress certificate and private key.
#        Default: $CERT_DIR_PRODUCT.
#
# Returns:
#   None.
load_certs_ingress() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    load_cert "ingress_server.crt" "INGRESS_CERTIFICATE" "${cert_dir_product}"
    load_cert "ingress_server.key" "INGRESS_PRIVATE_KEY" "${cert_dir_product}"
}

# =============================================================================
# update_ingress_certs()
# =============================================================================
# Updates the ingress server TLS certificate and private key.
#
# The source certificate and private key paths can be provided as function
# arguments. If omitted or empty, the corresponding environment variables are
# used. The certificate pair is installed in the product certificate directory
# using init_certs_ingress_pair() with "ingress_server" as the destination
# certificate name.
#
# Both source files must exist and be non-empty. Otherwise, the function exits
# with an error.
#
# The fourth argument controls whether the ingress container is recreated after
# the certificates are installed. If omitted or empty, it defaults to
# UPDATE_INGRESS_CERT_REDEPLOY. If that value is also empty, the user is
# prompted whether to recreate the container. The container is recreated only
# when the resulting value is "y".
#
# Arguments:
#   $1 - Optional path to the ingress server certificate.
#        Default: $INGRESS_TLS_SERVER_CERT.
#   $2 - Optional path to the ingress server private key.
#        Default: $INGRESS_TLS_SERVER_KEY.
#   $3 - Optional destination directory for the certificate pair.
#        Default: $CERT_DIR_PRODUCT.
#   $4 - Optional ingress container redeploy setting.
#        Default: $UPDATE_INGRESS_CERT_REDEPLOY.
#
# Returns:
#   None.
#
# Exits:
#   1 if the ingress server certificate is missing or empty.
#   1 if the ingress server private key is missing or empty.
update_ingress_certs() {
    local ingress_tls_server_cert="${1:-$INGRESS_TLS_SERVER_CERT}"
    local ingress_tls_server_key="${2:-$INGRESS_TLS_SERVER_KEY}"
    local cert_dir_product="${3:-$CERT_DIR_PRODUCT}"
    local update_ingress_cert_redeploy="${4:-$UPDATE_INGRESS_CERT_REDEPLOY}"


    if [ -s "${ingress_tls_server_cert}" ] && [ -s "${ingress_tls_server_key}" ]; then
        init_certs_ingress_pair "${ingress_tls_server_cert}" "${ingress_tls_server_key}" "${cert_dir_product}" 'ingress_server'
    elif [ ! -s "${ingress_tls_server_cert}" ]; then
        echo "Error: --ingress-server-cert argument missing or file ${ingress_tls_server_cert} not found! Required for --update-ingress-certs !"
        exit 1
    elif [ ! -s "${ingress_tls_server_key}" ]; then
        echo "Error: --ingress-server-key argument missing or file ${ingress_tls_server_key} not found! Required for --update-ingress-certs !"
        exit 1
    fi

    if ! [ "${update_ingress_cert_redeploy}" ]; then
        read -r -p "Info: Redeploy the ingress container, to activate the new Ingress certificates? (y/n)" update_ingress_cert_redeploy
    fi
    if [ "${update_ingress_cert_redeploy}" == "y" ]; then
        compose_recreate_container 'ingress'
    fi
}
