# =============================================================================
# compose_down()
# =============================================================================
# Stops the configured OpenVAS Enterprise Container deployment.
#
# Loads the persisted environment and selects the latest downloaded product
# version. Executes Docker Compose shutdown from the corresponding deployment
# directory, stopping and removing the deployment containers while preserving
# associated Docker volumes and stored data.
compose_down() {
    echo "🚀 Stopping OpenVAS ${PRODUCT}..."

    load_settings
    load_secrets
    load_certs

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down
    popd > /dev/null

    echo "OpenVAS ${PRODUCT} stopped."
}

# =============================================================================
# compose_down_volumes()
# =============================================================================
# Stops the configured OpenVAS Enterprise Container deployment and removes
# associated Docker volumes.
#
# Loads the persisted environment and selects the latest downloaded product
# version. Executes Docker Compose shutdown from the corresponding deployment
# directory, removing orphaned containers and all associated volumes. This
# operation permanently deletes container volumes and their stored data.
compose_down_volumes() {
    echo "🚀 Stopping OpenVAS ${PRODUCT} and removing Docker volumes..."

    load_settings
    load_secrets
    load_certs

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down --remove-orphans --volumes
    popd > /dev/null

    echo "OpenVAS ${PRODUCT} stopped and Docker volumes removed."
}

# =============================================================================
# compose_logs()
# =============================================================================
# Prints logs from the configured OpenVAS Enterprise Container deployment.
#
# Loads the persisted environment and selects the latest downloaded product
# version. Executes Docker Compose log retrieval from the corresponding
# deployment directory. If SERVICE_NAME is configured, only logs for the
# specified container are displayed; otherwise, logs for all services are shown.
compose_logs() {
    echo "🚀 Print ${PRODUCT} Logs..."

    load_settings
    load_secrets
    load_certs

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        if [ "${SERVICE_NAME}" ]; then
            docker compose logs "${SERVICE_NAME}"
        else
            docker compose logs
        fi
    popd > /dev/null
}

# =============================================================================
# compose_ps()
# =============================================================================
# Prints the status of the configured OpenVAS Enterprise Container deployment.
#
# Loads the persisted environment and selects the latest downloaded product
# version. Executes Docker Compose status retrieval from the corresponding
# deployment directory and displays the state of all configured services.
compose_ps() {
    echo "🚀 Print ${PRODUCT} Container..."

    load_settings
    load_secrets
    load_certs

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose ps -a
    popd > /dev/null
}

# =============================================================================
# init_docker_oci()
# =============================================================================
# Installs the OCI client TLS certificate and private key into the dockerd
# certificate directory.
#
# When INIT_DOCKER_OCI is set to "y", the function creates the destination
# directory with sudo and installs the credentials with permissions set to
# 0600. Otherwise, it prints the equivalent commands for manual execution in
# a root shell.
init_docker_oci() {
    if [ "${INIT_DOCKER_OCI}" == 'y' ]; then
        echo "Info: Install OCI TLS certificates into dockerd..."
        sudo mkdir -p "${DOCKER_CERTS}"
        sudo install -m 0600 "${OCI_TLS_CLIENT_CERT}" "${DOCKER_CERTS}/client.cert"
        sudo install -m 0600 "${OCI_TLS_CLIENT_KEY}" "${DOCKER_CERTS}/client.key"
    else
        echo "Info: Please Install the dockerd OCI TLS certificates with a root shell:"
        echo "mkdir -p ${DOCKER_CERTS}"
        echo "install -m 0600 ${OCI_TLS_CLIENT_CERT} ${DOCKER_CERTS}/client.cert"
        echo "install -m 0600 ${OCI_TLS_CLIENT_KEY} ${DOCKER_CERTS}/client.key"
    fi
}
