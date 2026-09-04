# =============================================================================
# init_certs_scan()
# =============================================================================
# Generates the CA and client TLS certificates required for scan deployments.
#
# The function creates a self-signed Enterprise-Container CA certificate and
# private key, then generates a client certificate and private key signed by
# that CA. The client certificate is configured for TLS client authentication.
#
# Generated certificates are valid for 365 days and are stored in
# CERT_DIR_PRODUCT.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_certs_scan() {
    echo "Info: Install Enterprise-Container TLS certificates..."
    openssl genrsa -out "${CERT_DIR_PRODUCT}/ca.key" 2048 2>/dev/null
    openssl req -new -x509 -key "${CERT_DIR_PRODUCT}/ca.key" -out "${CERT_DIR_PRODUCT}/ca.crt" -days 365 \
       -addext "basicConstraints=CA:TRUE" \
       -subj "/CN=enterprise-container-ca" 2>/dev/null

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
# Loads the ECDSA key pair required by the feed key service for scan
# deployments.
#
# The function reads the private and public ECDSA keys from CERT_DIR_PRODUCT
# and exports their contents for use by the feed key service JWT
# configuration.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if the ECDSA private key is missing.
#   1 if the ECDSA public key is missing.
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
