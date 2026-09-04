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
