# =============================================================================
# init_certs_scan()
# =============================================================================
# Creates the TLS certificates used by the Enterprise Container deployment.
#
# The function generates a 2048-bit RSA certificate authority and a client
# certificate signed by that authority, each valid for 365 days. For the
# ingress server, it installs the configured certificate and private key when
# both files are available; otherwise, it generates a self-signed server
# certificate valid for 365 days. Existing output files may be replaced.
init_certs_scan() {
    # Create Enterprise-Container CA certificate
    echo "Info: Install Enterprise-Container TLS certificates..."
    openssl genrsa -out "${CERT_DIR_PRODUCT}/ca.key" 2048 2>/dev/null
    openssl req -new -x509 -key "${CERT_DIR_PRODUCT}/ca.key" -out "${CERT_DIR_PRODUCT}/ca.crt" -days 365 \
       -addext "basicConstraints=CA:TRUE" \
       -subj "/CN=enterprise-container-ca" 2>/dev/null

    # Create Enterprise-Container Client certificate
    openssl genrsa -out "${CERT_DIR_PRODUCT}/client.key" 2048 2>/dev/null
    openssl req -new -key "${CERT_DIR_PRODUCT}/client.key" -out "${CERT_DIR_PRODUCT}/client.csr" \
        -subj "/CN=enterprise-container-client" 2>/dev/null
    openssl x509 -req -in "${CERT_DIR_PRODUCT}/client.csr" -out "${CERT_DIR_PRODUCT}/client.crt" -days 365 \
        -CA "${CERT_DIR_PRODUCT}/ca.crt" -CAkey "${CERT_DIR_PRODUCT}/ca.key" \
        -extfile <(printf '%s\n' "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth" "keyUsage=digitalSignature,keyEncipherment") 2>/dev/null
}

# =============================================================================
# load_certs_scan()
# =============================================================================
# Loads the Enterprise Container ingress TLS credentials and feed key service
# JWT keys, then exports them for use by the scan deployment.
#
# Reads the ingress server certificate and private key into
# INGRESS_CERTIFICATE and INGRESS_PRIVATE_KEY. It also loads the ECDSA private
# and public keys into the corresponding feed key service JWT environment
# variables.
#
# Terminates the script when any required certificate or key file is missing.
load_certs_scan() {
    if [ -f "${CERT_DIR_PRODUCT}/ecdsa.private.pem" ]; then
        export OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_KEY="$(< "${CERT_DIR_PRODUCT}/ecdsa.private.pem")"
    else
        echo "Error: No enterprise-container feed key service ecdsa key found at ${CERT_DIR_PRODUCT}/ecdsa.private.pem! Please run --init!"
        exit 1
    fi
    if [ -f "${CERT_DIR_PRODUCT}/ecdsa.public.pem" ]; then
        export OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_PUBLIC_KEY="$(< "${CERT_DIR_PRODUCT}/ecdsa.public.pem")"
    else
        echo "Error: No enterprise-container feed key service public ecdsa key found at ${CERT_DIR_PRODUCT}/ecdsa.public.pem! Please run --init!"
        exit 1
    fi
}
