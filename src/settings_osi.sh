init_settings_osi() {
    local domain_name="${1:-$DOMAIN_NAME}"
    local settings_dir="${2:-$SETTINGS_DIR}"

    if [ "${domain_name}" ]; then
        echo "${domain_name}" > "${SETTINGS_DIR}/DOMAIN_NAME"
    else
        echo "Error: Domain name not set! Run --init with --domain-name!"
        exit 1
    fi
}

load_settings_osi() {
    echo 'Info: Load settings OSI'

    if [ -f "${SETTINGS_DIR}/DOMAIN_NAME" ]; then
        export DOMAIN_NAME="$(< "${SETTINGS_DIR}/DOMAIN_NAME")"
    else
        echo "Error: No domain name found at ${SETTINGS_DIR}/DOMAIN_NAME! Please run --init!"
        exit 1
    fi
}
