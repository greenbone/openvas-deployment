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

init_certs_ingress() {
    # Create Ingress Server certificate
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
# Installs the TLS client certificate and private key for OCI deployments.
#
# The function copies the configured OCI client certificate and private key
# into the OCI certificate directory with permissions restricted to the file
# owner. Existing files with the same names are replaced.
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

load_certs() {
    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        load_certs_ec
    elif [ "${PRODUCT}" == 'security-intelligence' ]; then
        load_certs_osi
    fi
}

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
# Installs updated ingress server TLS credentials for the Enterprise Container.
#
# The function requires both the ingress TLS certificate and key to exist,
# installs them into the OCI certificate directory with restricted permissions,
# and prompts whether to redeploy the compose stack so the new certificates are
# activated.
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
