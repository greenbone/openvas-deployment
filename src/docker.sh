# =============================================================================
# compose_down()
# =============================================================================
# Stops the currently deployed OpenVAS product compose stack.
#
# The function loads the deployment settings, secrets, and certificates,
# determines the latest locally available product version, and runs Docker
# Compose from the corresponding artifact directory to stop the deployment.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   Exits if changing to the artifact directory fails.
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
# Stops the currently deployed OpenVAS product compose stack and removes its
# associated Docker volumes.
#
# The function loads the deployment settings, secrets, and certificates,
# determines the latest locally available product version, and runs Docker
# Compose from the corresponding artifact directory with orphan and volume
# removal enabled.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   Exits if changing to the artifact directory fails.
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
# Prints Docker Compose logs for the selected OpenVAS product deployment.
#
# The function loads the deployment settings, secrets, and certificates,
# determines the latest locally available product version, and prints logs
# from the corresponding Docker Compose stack.
#
# If SERVICE_NAME is set, only logs for that service are shown. Otherwise,
# logs for all services in the compose stack are printed.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   Exits if changing to the artifact directory fails.
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
# Prints the status of containers for the selected OpenVAS product deployment.
#
# The function loads the deployment settings, secrets, and certificates,
# determines the latest locally available product version, and runs Docker
# Compose from the corresponding artifact directory to list all containers,
# including stopped containers.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   Exits if changing to the artifact directory fails.
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
# Installs the OCI TLS client certificate and private key for Docker daemon
# access to the configured OCI registry.
#
# If INIT_DOCKER_OCI is set to 'y', the function creates the Docker certificate
# directory and installs the configured OCI client certificate and private key
# using sudo and restrictive file permissions.
#
# Otherwise, the function prints the commands required to install the
# certificates manually with root privileges.
#
# Arguments:
#   None.
#
# Returns:
#   None.
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
