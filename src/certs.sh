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
#   $2
#     Deployment mode.
#     Defaults to DEPLOYMENT_MODE.
#
# Returns:
#   None.
init_certs() {
    local product="${1:-$PRODUCT}"
    local deployment_mode="${2:-$DEPLOYMENT_MODE}"

    if [ "${product}" == 'enterprise-container' ]; then
        if [ "${deployment_mode}" == 'scan' ]; then
            init_certs_scan
            init_certs_ingress
        elif [ "${deployment_mode}" == 'openvasd' ]; then
            init_certs_openvasd
        fi
    elif [ "${product}" == 'security-intelligence' ]; then
        init_certs_ingress
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
    echo "Info: Install Ingress TLS certificates..."
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

    echo "Info: Install OCI TLS certificates..."
    install -m 0600 "${OCI_TLS_CLIENT_CERT}" "${CERT_DIR_OCI}/client.crt"
    install -m 0600 "${OCI_TLS_CLIENT_KEY}" "${CERT_DIR_OCI}/client.key"
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
# The function reads the ingress server certificate and private key from
# CERT_DIR_PRODUCT and exports their contents for use by subsequent deployment
# operations.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if the ingress TLS certificate is missing.
#   1 if the ingress TLS private key is missing.
load_certs_ingress() {
    if [ -f "${CERT_DIR_PRODUCT}/ingress_server.crt" ]; then
        export INGRESS_CERTIFICATE="$(< "${CERT_DIR_PRODUCT}/ingress_server.crt")"
    else
        echo "Error: No enterprise-container Ingress TLS certificate found at ${CERT_DIR_PRODUCT}/ingress_server.crt! Please run --init!"
        exit 1
    fi
    if [ -f "${CERT_DIR_PRODUCT}/ingress_server.key" ]; then
        export INGRESS_PRIVATE_KEY="$(< "${CERT_DIR_PRODUCT}/ingress_server.key")"
    else
        echo "Error: No enterprise-container Ingress TLS private key found at ${CERT_DIR_PRODUCT}/ingress_server.key! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# update_ingress_certs()
# =============================================================================
# Updates the ingress TLS certificate and private key.
#
# The function validates the provided ingress server certificate and private
# key, then installs them into CERT_DIR_PRODUCT using restrictive file
# permissions.
#
# After installing the certificates, the function prompts the user to redeploy
# the compose stack so the new certificates become active. If confirmed,
# deploy is called.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if INGRESS_TLS_SERVER_CERT is not set to an existing file.
#   1 if INGRESS_TLS_SERVER_KEY is not set to an existing file.
update_ingress_certs() {
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

    read -r -p "Info: We need to redeploy the compose stack, to activate the new Ingress certificates. (y/n)" response
    if [ "$response" == "y" ]; then
        deploy
    fi
}
