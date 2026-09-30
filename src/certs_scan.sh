# =============================================================================
# init_ca_gvmd_openvasd_auth()
# =============================================================================
# Creates the certificate authority and client certificates used for
# authentication between gvmd and openvasd.
#
# The function creates a self-signed CA certificate and a client certificate
# signed by that CA. Existing complete CA and client certificate/key pairs are
# detected and reused to avoid unnecessary regeneration. Generated certificates
# and private keys are stored in the specified certificate directory and are
# valid for 365 days.
#
# Arguments:
#   $1  Optional product certificate directory (defaults to CERT_DIR_PRODUCT).
#
# Returns:
#   None.
#
# Exits:
#   None.
init_ca_gvmd_openvasd_auth() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    if [ -s "${cert_dir_product}/client.key" ] && \
       [ -s "${cert_dir_product}/client.crt" ] && \
       [ -s "${cert_dir_product}/ca.key" ] && \
       [ -s "${cert_dir_product}/ca.crt" ]; then
        echo "Info: GVMD client/CA certificate and key already exist in ${cert_dir_product}/client.key|client.crt|ca.key|ca.crt. Skipping generation."
        return
    fi

    openssl genrsa -out "${cert_dir_product}/ca.key" 2048 2>/dev/null
    openssl req -new -x509 -key "${cert_dir_product}/ca.key" -out "${cert_dir_product}/ca.crt" -days 365 \
       -addext "basicConstraints=CA:TRUE" \
       -subj "/CN=enterprise-container-ca" 2>/dev/null

    openssl genrsa -out "${cert_dir_product}/client.key" 2048 2>/dev/null
    openssl req -new -key "${cert_dir_product}/client.key" -out "${cert_dir_product}/client.csr" \
        -subj "/CN=enterprise-container-client" 2>/dev/null
    openssl x509 -req -in "${cert_dir_product}/client.csr" -out "${cert_dir_product}/client.crt" -days 365 \
        -CA "${cert_dir_product}/ca.crt" -CAkey "${cert_dir_product}/ca.key" \
        -extfile <(printf '%s\n' "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth" "keyUsage=digitalSignature,keyEncipherment") 2>/dev/null
}

# =============================================================================
# init_certs_scan()
# =============================================================================
# Initializes certificates and authentication material required for scanning.
#
# The function creates the CA and client certificates used for gvmd/openvasd
# authentication and initializes the JWT material.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_certs_scan() {
    init_ca_gvmd_openvasd_auth
    init_jwt
}

# =============================================================================
# init_jwt()
# =============================================================================
# Generates the ECDSA key pair used for JWT signing and verification.
#
# The function creates an ECDSA private key using the P-256 curve and derives
# the corresponding public key in PEM format. Existing JWT ECDSA private and
# public keys are detected and reused to avoid unnecessary regeneration. The
# generated keys are stored in the specified certificate directory.
#
# Arguments:
#   $1  Optional product certificate directory (defaults to CERT_DIR_PRODUCT).
#
# Returns:
#   None.
#
# Exits:
#   None.
init_jwt() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    if [ -s "${cert_dir_product}/ecdsa.private.pem" ] && [ -s "${cert_dir_product}/ecdsa.public.pem" ]; then
        echo "Info: JWT ECDSA key pair already exists in ${cert_dir_product}/ecdsa.private.pem|ecdsa.public.pem. Skipping generation."
        return
    fi

    openssl genpkey \
        -algorithm EC \
        -outform PEM \
        -quiet \
        -out "${cert_dir_product}/ecdsa.private.pem" \
        -pkeyopt ec_paramgen_curve:"P-256" \
        -pkeyopt ec_param_enc:named_curve \
        >/dev/null 2>&1

    openssl ec \
        -in "${cert_dir_product}/ecdsa.private.pem" \
        -pubout \
        -outform PEM \
        -out "${cert_dir_product}/ecdsa.public.pem" \
        >/dev/null 2>&1
}

# =============================================================================
# load_certs_scan()
# =============================================================================
# Loads the ECDSA key pair required by the feed key service for scan
# deployments.
#
# The function loads the private and public ECDSA keys from the product
# certificate directory using the generic load_cert() helper and exports their
# contents as environment variables for use by the feed key service JWT
# configuration.
#
# Arguments:
#   $1  Optional product certificate directory (defaults to CERT_DIR_PRODUCT).
#
# Returns:
#   None.
#
# Exits:
#   1 if the ECDSA private key file does not exist or is empty.
#   1 if the ECDSA public key file does not exist or is empty.
load_certs_scan() {
    local cert_dir_product="${1:-$CERT_DIR_PRODUCT}"

    load_cert "ecdsa.private.pem" "OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_KEY" "${cert_dir_product}"
    load_cert "ecdsa.public.pem" "OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_PUBLIC_KEY" "${cert_dir_product}"
}
