load_certs_ec() {
    echo 'Info: Load certs EC'

    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        load_certs_openvasd
        # Todo: put me into file
        if [ "${OPENVASD_PORT}" ]; then
            export OPENVAS_SCANNER_HOST_LISTEN_PORT="${OPENVASD_PORT}"
        fi
    elif [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        load_certs_scan
        load_certs_ingress
    fi
}
