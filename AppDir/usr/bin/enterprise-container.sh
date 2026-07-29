#!/bin/bash

# =============================================================================
#  OpenVAS Enterprise-Container Deployment Script
# =============================================================================
#  This script is for demo purposes until our deployment tool
#  supports this product!
# =============================================================================

set -euo pipefail

# Global Variables
DOCKER_CERTS='/etc/docker/certs.d/packages.greenbone.net'
PACKAGE='enterprise-container'
STORE_DIR_NAME='product'
CERT_DIR_NAME='certs'
CERT_DIR_OCI_NAME='oci'
IMAGE_DIR_NAME='images'
DEPLOYMENT_MODE_OPTIONS=('scan' 'openvas')
FEED_MODE_OPTIONS=('volume' 'service' 'mount')
CCERT_MODE_OPTIONS=('ca' 'cert' 'mount')
PACKAGE_URL="packages.greenbone.net/openvas-enterprise-container-dev/testing/${PACKAGE}"
GVMD_CONTAINER='enterprise-container-scan-gvmd-1'
GVMD_CONTAINER_UID='1001'

# Working dir's
WORKING_DIR="$(pwd)/${STORE_DIR_NAME}"
CERT_DIR="${WORKING_DIR}/${CERT_DIR_NAME}"
CERT_DIR_OCI="${CERT_DIR}/${CERT_DIR_OCI_NAME}"
CERT_DIR_ENTERPRISE_CONTAINER="${CERT_DIR}/${PACKAGE}"
ARTIFACT_DIR="${WORKING_DIR}/${PACKAGE}"
IMAGE_DIR="${WORKING_DIR}/${IMAGE_DIR_NAME}"

# Runtime globals and defaults
MODE=''
FEED_KEY='None'
FEED_MODE='volume'
CCERT_MODE='ca'
FEED_PATH=''
CCERT_PATH=''
CN_OPENVASD=''
OPENVASD_PORT=''
OPENVASD_UUID=''
INGRESS_TLS_SERVER_CERT=''
INGRESS_TLS_SERVER_KEY=''
OCI_TLS_CLIENT_CERT=''
OCI_TLS_CLIENT_KEY=''
INIT_DOCKER_OCI=''
DEPLOYMENT_MODE='scan'
OPENVASD_TAR_WITH_IMAGES='n'
OPENVASD_LOAD_IMAGES_FROM_TAR='n'
GVMD_ADMIN_PASSWORD=''
GREENBONE_FEED_SYNC_JOB_HOUR='3'
declare -A LICENSE_DATA
LICENSE_FILE=''
SERVICE_NAME=''

# =============================================================================
# show_help()
# =============================================================================
# Prints help text. 
show_help() {
    less << EOF
OpenVAS Enterprise-Container Deployment


Info:
  You can move up and down with arrow keys. Press q to quit.


Usage:
  $0 ACTION [OPTIONS]
  $0 -h | --help


Actions:
  --init                         Initialize deployment, certificates, and
                                 deployment settings

  --init-openvasd                Initialize OCI client certificates for an
                                 OpenVASD deployment

  --change-admin-password        Change the gvmd administrator password

  --change-feed-sync-hour        Change the scheduled feed synchronization hour

  --force-feed-sync              Restart feed synchronization immediately

  --update                       Download the latest product version

  --run                          Start or redeploy the configured deployment

  --logs                         Show deployment logs
                                 Optional: --service-name

  --ps                           Show deployment status

  --down                         Stop the deployment

  --down-volumes                 Stop the deployment and remove volumes

  --update-ingress-certs         Replace ingress TLS certificate and key

  --create-openvasd-certs        Create TLS certificates for an OpenVASD scanner

  --create-openvasd-tar          Create an OpenVASD deployment archive

  --get-openvasds                List OpenVASD scanners registered in gvmd

  --add-openvasd                 Register an OpenVASD scanner in gvmd

  --del-openvasd                 Remove an OpenVASD scanner from gvmd


Deployment options:
  --deployment-mode MODE         Deployment mode:
                                   scan | openvas
                                 Default: ${DEPLOYMENT_MODE}

  --feed-mode MODE               Feed mode:
                                   volume | service | mount
                                 Default: ${FEED_MODE}

  --feed-key FILE                Feed key file used with volume or service mode

  --feed-path PATH               Host feed directory used with mount mode

  --feed-sync-hour HOUR          Scheduled feed synchronization hour (1-24)
                                 Default: ${GREENBONE_FEED_SYNC_JOB_HOUR}

  --ccert-mode MODE              Client certificate mode:
                                   ca | cert | mount
                                 Default: ${CCERT_MODE}

  --ccert-path PATH              Host client certificate directory used with
                                 mount mode


Administrator options:
  --admin-password PASSWORD      Administrator password used during
                                 initialization or password changes


OCI client certificate options:
  --license-file FILE            License file containing OCI registry
                                 client certificate and key

  --oci-client-cert FILE         OCI registry client certificate

  --oci-client-key FILE          OCI registry client private key

  --init-docker-oci              Install OCI credentials into dockerd using sudo

  --skip-docker-oci              Do not install OCI credentials automatically,
                                 print required commands instead


Ingress certificate options:
  --ingress-server-cert FILE     Ingress server certificate

  --ingress-server-key FILE      Ingress server private key


OpenVASD options:
  --cn-openvasd NAME             OpenVASD common name and scanner hostname

  --openvasd-port PORT           OpenVASD scanner port
                                 Default port: 443

  --openvasd-uuid UUID           Scanner UUID returned by --get-openvasds

  --openvasd-tar-with-images     Include Docker images in OpenVASD archive
                                 Default: disabled

  --openvasd-load-images-from-tar
                                 Load packaged Docker images before deployment
                                 Default: disabled


Help:
  -h, --help                     Show this help message


Examples:

Initialize a scan deployment using a Docker volume for feeds:
  $0 --init \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize a scan deployment with a predefined administrator password:
  $0 --init \\
    --admin-password 'secure-password' \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize a deployment with scheduled feed synchronization:
  $0 --init \\
    --feed-sync-hour 3 \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize with custom ingress certificates:
  $0 --init \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key \\
    --ingress-server-cert /path/to/ingress.crt \\
    --ingress-server-key /path/to/ingress.key


Update and start the deployment:
  $0 --update
  $0 --run


Change the gvmd administrator password:
  $0 --change-admin-password --admin-password 'new-secure-password'


Change the scheduled feed synchronization hour:
  $0 --change-feed-sync-hour --feed-sync-hour 4


Restart feed synchronization immediately:
  $0 --force-feed-sync


Show logs and status:
  $0 --logs
  $0 --ps


Stop the deployment:
  $0 --down


Restart the deployment:
  $0 --run


Stop deployment and remove Docker volumes:
  $0 --down-volumes


Update ingress certificates:
  $0 --update-ingress-certs --ingress-server-cert ./ingress.crt --ingress-server-key ./ingress.key


External OpenVASD sensor setup:

Create OpenVASD certificates:
  $0 --create-openvasd-certs --cn-openvasd sensor.example.com


Create an OpenVASD deployment archive:
  $0 --create-openvasd-tar --cn-openvasd sensor.example.com --openvasd-tar-with-images


Run an extracted OpenVASD archive on your openvasd(sensor) node/host:
  $0 --run --openvasd-load-images-from-tar

Run an extracted OpenVASD archive with other host port:
  $0 --run --openvasd-load-images-from-tar --openvasd-port PORT


Register an OpenVASD scanner:
  $0 --add-openvasd --cn-openvasd sensor.example.com --openvasd-port 443


List or remove registered OpenVASD scanners:
  $0 --get-openvasds

  $0 --del-openvasd --openvasd-uuid UUID


Support:
  https://www.greenbone.net/support/
EOF

    exit 0
}

# =============================================================================
# check_requirements()
# =============================================================================
# Checks if the required tools (docker, oras, openssl, etc.) are installed and 
# if Docker and Docker Compose are running. If any are missing or not running, 
# the script exits with an error.
check_requirements() {
    echo "🚀 Checking system requirements..."
    
    for tool in docker oras openssl tar install grep sed sort tail ls curl cp less tar awk tr cat; do
        if ! command -v $tool > /dev/null 2>&1; then
            echo "Missing: $tool"
            exit 1
        fi
    done

    if ! docker compose version > /dev/null 2>&1; then
        echo "Docker Compose not available"
        exit 1
    fi
    
    if ! docker ps > /dev/null 2>&1; then
        echo "Docker not running"
        exit 1
    fi
}

# =============================================================================
# read_license_file()
# =============================================================================
# Reads license data from a section-based configuration file.
#
# The first argument specifies the input file and defaults to LICENSE_FILE. The
# second argument names the output array and defaults to LICENSE. Parsed values
# are stored using "section.key" as the array key. The function supports
# comments, blank lines, quoted values, and triple-quoted multiline values.
#
# Returns a non-zero status if a multiline value reaches the end of the file
# before its closing triple quotes are found.
read_license_file() {
    local file="${1:-$LICENSE_FILE}"
    local -n out="${2:-LICENSE_DATA}"
    local section key value line

    while IFS= read -r line; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue

        if [[ $line =~ ^\[([^]]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"

        elif [[ $line =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*\"\"\"(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            key="${key//[[:space:]]/}"
            value="${BASH_REMATCH[2]}"

            while [[ $value != *'"""' ]]; do
                IFS= read -r line || return 1
                value+="${value:+$'\n'}${line}"
            done

            value=${value%\"\"\"}
            out["${section}.${key}"]="${value}"

        elif [[ $line =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            key="${key//[[:space:]]/}"

            [[ $value == \'*\' || $value == \"*\" ]] &&
                value="${value:1:-1}"

            out["${section}.${key}"]="${value}"
        fi
    done < "$file"
}

# =============================================================================
# create_openvasd_cert()
# =============================================================================
# Creates a server certificate, private key, and CA certificate bundle for an
# OpenVASD scanner using the configured OpenVASD common name. Stores the generated
# files in a certificate directory derived from the common name and prints the
# target paths where the files should be copied on the remote OpenVASD machine.
create_openvasd_cert() {

    if ! [ "${CN_OPENVASD}" ]; then
        echo "Error: --cn-openvasd argument missing. Required for --create-openvasd-certs !"
        exit 1
    fi

    local OPENVASD_FOLDER="${CN_OPENVASD//./_}"
    OPENVASD_FOLDER="${CERT_DIR_ENTERPRISE_CONTAINER}/${OPENVASD_FOLDER}"

    mkdir -p "${OPENVASD_FOLDER}"

    # Create a Openvasd Server certificate
    openssl genrsa -out "${OPENVASD_FOLDER}/server.key" 2048 2>/dev/null
    openssl req -new -key "${OPENVASD_FOLDER}/server.key" -out "${OPENVASD_FOLDER}/server.csr" \
       -subj "/CN=${CN_OPENVASD}" 2>/dev/null
    openssl x509 -req -in "${OPENVASD_FOLDER}/server.csr" -out "${OPENVASD_FOLDER}/server.crt" -days 365 \
       -CA "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" -CAkey "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.key" \
       -extfile <(printf '%s\n' "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "keyUsage=digitalSignature,keyEncipherment") 2>/dev/null
    cp "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" "${OPENVASD_FOLDER}/ca.crt"

    cat << EOF
Remote OpenVASD sensor setup:

Copy the generated certificate files to the OpenVASD sensor host:

  ${OPENVASD_FOLDER}/server.crt -> <config-folder>/server.crt
  ${OPENVASD_FOLDER}/server.key -> <config-folder>/server.key
  ${OPENVASD_FOLDER}/ca.crt     -> <config-folder>/clients/ca.crt

Configure OpenVASD to use these TLS certificates and restart the
OpenVASD service.

Or

OpenVASD Docker Compose TLS configuration:

  export DEPLOYMENT_MODE=openvasd
  export FEED_KEY=\$(< "gsf.key")
  export OPENVAS_SCANNER_TLS_CERT=\$(< "server.crt")
  export OPENVAS_SCANNER_TLS_KEY=\$(< "server.key")
  export OPENVAS_TLS_CLIENT_CA=\$(< "clients/ca.crt")
  docker compose up

Or

Create an OpenVASD deployment archive for an external sensor:

  ${0} --create-openvasd-tar --cn-openvasd ${CN_OPENVASD}

Include Docker images in the archive (no --init-openvasd required):

  ${0} --create-openvasd-tar --cn-openvasd ${CN_OPENVASD} --openvasd-tar-with-images

Copy the archive to the OpenVASD sensor host, extract it, and start
the sensor deployment:

  ${0} --init-openvasd
  ${0} --run

To load packaged Docker images before starting the sensor
(no --init-openvasd required):

  ${0} --run --openvasd-load-images-from-tar

Optionally, use a different OpenVASD listen port:

  ${0} --run --openvasd-load-images-from-tar --openvasd-port <PORT>

Then

Register an OpenVASD scanner on enterprise-container(SCAN deployment mode) node/host:

  ${0} --add-openvasd --cn-openvasd sensor.example.com --openvasd-port 443

EOF
}

# =============================================================================
# del_openvasd()
# =============================================================================
# Deletes the configured OpenVASD scanner from gvmd using the scanner UUID
# provided by --openvasd-uuid. Fails if no UUID is configured, because gvmd
# requires the scanner UUID to identify the OpenVASD scanner to remove.
del_openvasd() {
    if ! [ "${OPENVASD_UUID}" ]; then
        echo "Error: --openvasd-uuid argument missing. Required for --del-openvasd !"
        exit 1
    fi

    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd --delete-scanner="${OPENVASD_UUID}"
}

# =============================================================================
# get_openvasds()
# =============================================================================
# Lists the scanners currently registered in gvmd. Runs gvmd inside the configured
# gvmd container and prints the scanner entries returned by --get-scanners.
get_openvasds() {
    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd --get-scanners
}

# =============================================================================
# add_openvasd()
# =============================================================================
# Registers an OpenVASD scanner in the GVMD container after verifying that the
# OpenVASD endpoint is ready.
#
# The function requires the OpenVASD common name and port, derives the scanner
# name and certificate directory from the common name, and checks the OpenVASD
# readiness endpoint with the configured client certificate, client key, and CA
# certificate. If the endpoint is ready, it copies the scanner credentials into
# the GVMD container, sets read-only permissions, and creates the scanner entry
# with `gvmd --create-scanner`.
add_openvasd() {
    if ! [ "${CN_OPENVASD}" ]; then
        echo "Error: --cn-openvasd argument missing. Required for --add-openvasd !"
        exit 1
    fi
    if ! [ "${OPENVASD_PORT}" ]; then
        echo "Error: --openvasd-port argument missing, normaly 443. Required for --add-openvasd !"
        exit 1
    fi

    local OPENVASD_FOLDER="${CN_OPENVASD//./_}"
    local OPENVASD_NAME="${CN_OPENVASD//./-}"
    OPENVASD_FOLDER="${CERT_DIR_ENTERPRISE_CONTAINER}/${OPENVASD_FOLDER}"

    set +e

    status_code=$(curl -sS -o /dev/null \
        --cacert "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" \
        --cert "${CERT_DIR_ENTERPRISE_CONTAINER}/client.crt" \
        --key "${CERT_DIR_ENTERPRISE_CONTAINER}/client.key" \
        -w "%{http_code}" \
        "https://${CN_OPENVASD}:${OPENVASD_PORT}/health/ready"
    )

    set -e

    if [ "${status_code}" = "200" ]; then
        echo "openvasd is ready"
    else
        echo "openvasd is not ready, HTTP status: ${status_code}"
        exit 1
    fi

    docker cp "${CERT_DIR_ENTERPRISE_CONTAINER}/client.key" "${GVMD_CONTAINER}:/tmp/client.key"
    docker cp "${CERT_DIR_ENTERPRISE_CONTAINER}/client.crt" "${GVMD_CONTAINER}:/tmp/client.crt"
    docker cp "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" "${GVMD_CONTAINER}:/tmp/ca.crt"

    docker exec -u "0" "${GVMD_CONTAINER}" chmod 0644 "/tmp/client.key"
    docker exec -u "0" "${GVMD_CONTAINER}" chmod 0644 "/tmp/client.crt"
    docker exec -u "0" "${GVMD_CONTAINER}" chmod 0644 "/tmp/ca.crt"

    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd \
        --create-scanner="${OPENVASD_NAME}" \
        --scanner-host="${CN_OPENVASD}" \
        --scanner-port="${OPENVASD_PORT}" \
        --scanner-type="OPENVASD" \
        --scanner-ca-pub="/tmp/ca.crt" \
        --scanner-key-pub="/tmp/client.crt" \
        --scanner-key-priv="/tmp/client.key"
}

# =============================================================================
# change_admin_password()
# =============================================================================
# Changes the Greenbone Vulnerability Manager (gvmd) administrator password.
#
# Verifies that GVMD_ADMIN_PASSWORD is set before updating the password. The
# password is written to the ADMIN_PASSWORD file in the working directory and
# then applied to the default "admin" account using the gvmd command inside
# the container. If no password is provided, the function prints an error
# message and exits with a non-zero status.
change_admin_password() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${WORKING_DIR}/GVMD_ADMIN_PASSWORD"
    else
        echo 'Error: No admin password set. Please use --change-admin-password with --admin-password'
        exit 1
    fi

    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd \
        --user=admin --new-password="${GVMD_ADMIN_PASSWORD}"
}

# =============================================================================
# init_admin_password()
# =============================================================================
# Initializes the Greenbone Vulnerability Manager administrator password.
#
# When GVMD_ADMIN_PASSWORD is set, the function writes it to the
# ADMIN_PASSWORD file in the working directory. Otherwise, it generates a
# random 16-character alphanumeric password, stores it in the
# GVMD_ADMIN_PASSWORD file, assigns it to GVMD_ADMIN_PASSWORD, and prints the
# generated password.
init_admin_password() {
    if [ "${GVMD_ADMIN_PASSWORD}" ]; then
        echo "${GVMD_ADMIN_PASSWORD}" > "${WORKING_DIR}/GVMD_ADMIN_PASSWORD"
    else
        echo "Info: No admin password set. Create random."
        echo "$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)" > "${WORKING_DIR}/GVMD_ADMIN_PASSWORD"
        GVMD_ADMIN_PASSWORD="$(< "${WORKING_DIR}/GVMD_ADMIN_PASSWORD")"
        echo "Your admin password is: ${GVMD_ADMIN_PASSWORD}"
    fi
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

# =============================================================================
# init_openvasd()
# =============================================================================
# Initializes the OpenVASD deployment by configuring the OCI client
# certificates used by dockerd.
init_openvasd() {
    init_docker_oci
}

# =============================================================================
# load_openvasd_images()
# =============================================================================
# Loads the packaged OpenVASD Docker images from IMAGE_DIR.
#
# Each expected image archive is checked independently before being passed to
# docker load. Missing archives are skipped and reported without terminating
# the function.
load_openvasd_images() {
    if [ -f "${IMAGE_DIR}/openvas-openvasd.tar" ]; then
        docker load -i "${IMAGE_DIR}/openvas-openvasd.tar"
    else
        echo "Info: Image ${IMAGE_DIR}/openvas-openvasd.tar not found. Skip!"
    fi
    if [ -f "${IMAGE_DIR}/openvas-gpg-data.tar" ]; then
        docker load -i "${IMAGE_DIR}/openvas-gpg-data.tar"
    else
        echo "Info: Image ${IMAGE_DIR}/openvas-gpg-data.tar not found. Skip!"
    fi
    if [ -f "${IMAGE_DIR}/openvas-feed-sync.tar" ]; then
        docker load -i "${IMAGE_DIR}/openvas-feed-sync.tar"
    else
        echo "Info: Image ${IMAGE_DIR}/openvas-feed-sync.tar not found. Skip!"
    fi
    if [ -f "${IMAGE_DIR}/openvas-feed-sync.tar" ]; then
        docker load -i "${IMAGE_DIR}/openvas-feed-sync.tar"
    else
        echo "Info: Image ${IMAGE_DIR}/openvas-feed-sync.tar not found. Skip!"
    fi
    if [ -f "${IMAGE_DIR}/openvas-redis.tar" ]; then
        docker load -i "${IMAGE_DIR}/openvas-redis.tar"
    else
        echo "Info: Image ${IMAGE_DIR}/openvas-redis.tar not found. Skip!"
    fi
}

# =============================================================================
# create_openvasd_tar()
# =============================================================================
# Creates a deployment archive for the OpenVASD instance identified by
# CN_OPENVASD.
#
# Validates the required common name, loads the saved environment, and assembles
# a temporary deployment tree containing the OCI credentials, product
# artifacts, instance-specific certificates, feed key, deployment metadata,
# and a copy of this script.
#
# When OPENVASD_TAR_WITH_IMAGES is set to "y", the archive also includes the
# Docker images used by the latest downloaded product version. The feed key
# service image is added only when FEED_MODE is set to "service".
#
# Writes the resulting gzip-compressed tar archive to the current directory.
# The archive name is derived from CN_OPENVASD with periods replaced by hyphens.
create_openvasd_tar() {
    if ! [ "${CN_OPENVASD}" ]; then
        echo "Error: --cn-openvasd argument missing. Required for --create-openvasd-certs !"
        exit 1
    fi

    load_env

    local openvasd_name="${CN_OPENVASD//./-}"
    local openvasd_cert_folder="${CN_OPENVASD//./_}"
    openvasd_cert_folder="${CERT_DIR_ENTERPRISE_CONTAINER}/${openvasd_cert_folder}"
    local sh_file="$(pwd)/${0}"
    local tmp_dir="$(mktemp -d)"
    local tmp_images="${tmp_dir}/${STORE_DIR_NAME}/${IMAGE_DIR_NAME}"
    pushd "${tmp_dir}" > /dev/null || exit
        local tmp_cert_dir_enterprise_container="${STORE_DIR_NAME}/${CERT_DIR_NAME}/${PACKAGE}"
        mkdir -p "${tmp_cert_dir_enterprise_container}"
        cp -r "${CERT_DIR_OCI}" "${STORE_DIR_NAME}/${CERT_DIR_NAME}/"
        cp -r "${ARTIFACT_DIR}" "${STORE_DIR_NAME}/"
        cp -r "${openvasd_cert_folder}" "${tmp_cert_dir_enterprise_container}/"
        cp "${CERT_DIR_ENTERPRISE_CONTAINER}/feed.key" "${tmp_cert_dir_enterprise_container}/"
        echo 'openvasd' > "${STORE_DIR_NAME}/DEPLOYMENT_MODE"
        echo "${GREENBONE_FEED_SYNC_JOB_HOUR}" > "${STORE_DIR_NAME}/GREENBONE_FEED_SYNC_JOB_HOUR"
        echo "${CN_OPENVASD}" > "${STORE_DIR_NAME}/OPENVASD_CN"
        echo "${FEED_MODE}" > "${STORE_DIR_NAME}/FEED_MODE"
        echo "${CCERT_MODE}" > "${STORE_DIR_NAME}/CCERT_MODE"
        echo "${FEED_PATH}" > "${STORE_DIR_NAME}/FEED_PATH"
        echo "${CCERT_PATH}" > "${STORE_DIR_NAME}/CCERT_PATH"
        echo "${CCERT_TYPE}" > "${STORE_DIR_NAME}/CCERT_TYPE"
        cp "${sh_file}" .
    popd > /dev/null

    if [ "${OPENVASD_TAR_WITH_IMAGES}" == 'y' ]; then
        get_latest_version
        mkdir -p "${tmp_images}"
        pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
            docker save -o "${tmp_images}/openvas-openvasd.tar" \
                "$(docker compose images | awk '$2 ~ /openvas-scanner$/ { print $5; exit }')"
            docker save -o "${tmp_images}/openvas-gpg-data.tar" \
                "$(docker compose images | awk '$2 ~ /gpg-data$/ { print $5; exit }')"
            docker save -o "${tmp_images}/openvas-feed-sync.tar" \
                "$(docker compose images | awk '$2 ~ /greenbone-feed-sync$/ { print $5; exit }')"
            docker save -o "${tmp_images}/openvas-redis.tar" \
                "$(docker compose images | awk '$2 ~ /redis-server$/ { print $5; exit }')"
        if [ "${FEED_MODE}" == 'service' ]; then
                docker save -o "${tmp_images}/openvas-feed-key-service.tar" \
                    "$(docker compose images | awk '$2 ~ /feed-key-service$/ { print $5; exit }')"
        fi
        popd > /dev/null
    fi
    tar -czf "${openvasd_name}.tar.gz" -C "${tmp_dir}" .
}

# =============================================================================
# force_feed_sync()
# =============================================================================
# Restarts the feed-sync container for the currently selected deployment.
#
# The latest version is resolved and the deployment environment is loaded
# before restarting the feed-sync service with Docker Compose. After the
# restart, the user is prompted whether to follow the container logs in
# real time.
force_feed_sync() {
    get_latest_version

    load_env

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose restart feed-sync
        read -r -p "Info: Do you want to watch the feed sync container logs? (y/n)" response
        if [ "$response" == "y" ]; then
            docker compose logs -f feed-sync
        fi
    popd > /dev/null
}

# =============================================================================
# init_feed_sync_hour()
# =============================================================================
# Initializes the configured feed sync job hour.
#
# The configured hour is validated to ensure it is within the supported range
# from 1 to 24. A valid value is stored in the working directory for later use.
# Missing or invalid values are reported and terminate the function.
init_feed_sync_hour() {
    if [ "${GREENBONE_FEED_SYNC_JOB_HOUR}" ]; then
        if (( GREENBONE_FEED_SYNC_JOB_HOUR >= 1 && GREENBONE_FEED_SYNC_JOB_HOUR <= 24 )); then
            echo "${GREENBONE_FEED_SYNC_JOB_HOUR}" > "${WORKING_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR"
        else
            echo "Error: No feed sync hour ${GREENBONE_FEED_SYNC_JOB_HOUR} needs to be between 1 and 24. Please run --change-feed-sync-hour or --init with --feed-sync-hour."
            exit 1
        fi
    else
        echo "Error: No feed sync hour set. Please run --change-feed-sync-hour and --init with --feed-sync-hour."
        exit 1
    fi
}

# =============================================================================
# change_feed_sync_hour()
# =============================================================================
# Updates the configured feed sync job hour and restarts the feed-sync service.
#
# The new feed sync hour is initialized and validated before triggering a
# feed-sync restart to apply the updated schedule configuration.
change_feed_sync_hour() {
    init_feed_sync_hour

    force_feed_sync
}

# =============================================================================
# init_env()
# =============================================================================
# Validates the deployment, feed, and client-certificate configuration and
# writes the selected values to the working directory.
#
# DEPLOYMENT_MODE, FEED_MODE, and CCERT_MODE must match their corresponding
# supported-option arrays. Unsupported values terminate the script.
#
# Mount-based feed and client-certificate modes are currently rejected. For
# client-certificate modes "ca" and "cert", CCERT_TYPE is stored as "env";
# otherwise, it is stored as "mount".
init_env() {
    if [[ " ${DEPLOYMENT_MODE_OPTIONS[*]} " =~ " ${DEPLOYMENT_MODE} " ]]; then
        echo "${DEPLOYMENT_MODE}" > "${WORKING_DIR}/DEPLOYMENT_MODE"
    else
        echo "Error: feed mode option ${DEPLOYMENT_MODE} is not supported only ${DEPLOYMENT_MODE_OPTIONS[*]}."
    exit 1
    fi
    if [[ " ${FEED_MODE_OPTIONS[*]} " =~ " ${FEED_MODE} " ]]; then
        echo "${FEED_MODE}" > "${WORKING_DIR}/FEED_MODE"
    else
        echo "Error: feed mode option ${FEED_MODE} is not supported only ${FEED_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [[ " ${CCERT_MODE_OPTIONS[*]} " =~ " ${CCERT_MODE} " ]]; then
        echo "${CCERT_MODE}" > "${WORKING_DIR}/CCERT_MODE"
    else
        echo "Error: feed mode option ${CCERT_MODE} is not supported only ${CCERT_MODE_OPTIONS[*]}."
        exit 1
    fi
    if [ "${FEED_MODE}" == 'mount' ] && [ -d "${FEED_PATH}" ]; then
        echo "Error: feed mode option mount is not supported currently!."
        exit 1
        echo "${FEED_PATH}" > "${WORKING_DIR}/FEED_PATH"
    elif [ "${FEED_MODE}" == 'mount' ]; then
        echo " Error: feed path ${FEED_PATH} does not exist!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'mount' ] && [ -d "${CCERT_PATH}" ]; then
        echo "Error: ccert mode option mount is not supported currently!."
        exit 1
        echo "${CCERT_PATH}" > "${WORKING_DIR}/CCERT_PATH"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
        echo " Error: ccert path ${CCERT_PATH} does not exist!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'ca' ] || [ "${CCERT_MODE}" == 'cert' ]; then
        echo 'env' > "${WORKING_DIR}/CCERT_TYPE"
    else
        echo 'mount' > "${WORKING_DIR}/CCERT_TYPE"
    fi
    init_feed_sync_hour
}

# =============================================================================
# load_env()
# =============================================================================
# Loads the deployment configuration from files in the working directory and
# exports the corresponding environment variables.
#
# The function requires deployment, feed, CCERT mode, and CCERT type files.
# It also loads mount paths when the corresponding mode is set to "mount" and
# loads the gvmd administrator password for scan deployments. If a required
# configuration file is missing, it prints an error message and exits with a
# non-zero status.
load_env() {
    if [ -f "${WORKING_DIR}/DEPLOYMENT_MODE" ]; then
        export DEPLOYMENT_MODE="$(< "${WORKING_DIR}/DEPLOYMENT_MODE")"
    else
        echo "Error: No deployment mode found at ${WORKING_DIR}/DEPLOYMENT_MODE! Please run --init!"
        exit 1
    fi
    if [ -f "${WORKING_DIR}/FEED_MODE" ]; then
        export FEED_MODE="$(< "${WORKING_DIR}/FEED_MODE")"
    else
        echo "Error: No feed mode found at ${WORKING_DIR}/FEED_MODE! Please run --init!"
        exit 1
    fi
    if [ -f "${WORKING_DIR}/CCERT_MODE" ]; then
        export CCERT_MODE="$(< "${WORKING_DIR}/CCERT_MODE")"
    else
        echo "Error: No ccert mode found at ${WORKING_DIR}/CCERT_MODE! Please run --init!"
        exit 1
    fi
    if [ "${FEED_MODE}" == 'mount' ] && [ -f "${WORKING_DIR}/FEED_PATH" ]; then
        export CCERT_PATH="$(< "${WORKING_DIR}/FEED_PATH")"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
        echo "Error: No feed path found at ${WORKING_DIR}/FEED_PATH! Please run --init!"
        exit 1
    fi
    if [ "${CCERT_MODE}" == 'mount' ] && [ -f "${WORKING_DIR}/CCERT_PATH" ]; then
        export CCERT_PATH="$(< "${WORKING_DIR}/CCERT_PATH")"
    elif [ "${CCERT_MODE}" == 'mount' ]; then
        echo "Error: No ccert path found at ${WORKING_DIR}/CCERT_PATH! Please run --init!"
        exit 1
    fi
    if [ -f "${WORKING_DIR}/CCERT_TYPE" ]; then
        export CCERT_TYPE="$(< "${WORKING_DIR}/CCERT_TYPE")"
    else
        echo "Error: No ccert type found at ${WORKING_DIR}/CCERT_TYPE! Please run --init!"
        exit 1
    fi
    if [ "${DEPLOYMENT_MODE}" == 'scan' ] && [ -f "${WORKING_DIR}/GVMD_ADMIN_PASSWORD" ]; then
        export GVMD_ADMIN_PASSWORD="$(< "${WORKING_DIR}/GVMD_ADMIN_PASSWORD")"
    elif [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        echo "Error: No admin password found at ${WORKING_DIR}/GVMD_ADMIN_PASSWORD! Please run --init or --change-admin-password!"
        exit 1
    fi
    if [ -f "${WORKING_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR" ]; then
        export GREENBONE_FEED_SYNC_JOB_HOUR="$(< "${WORKING_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR")"
    else
        echo "Error: No FEED_SYNC_JOB_HOUR found at ${WORKING_DIR}/GREENBONE_FEED_SYNC_JOB_HOUR! Please run --init or --change-feed-sync-hour with --feed-sync-hour!"
        exit 1
    fi
}

# =============================================================================
# init_base_folders()
# =============================================================================
# Creates the directories used to store TLS certificates.
#
# The function creates the standard certificate directory and the certificate
# directories used by the OCI and enterprise container deployments. Existing
# directories are left unchanged.
init_base_folders() {
    echo "Info: Create TLS certificate folder..."
    mkdir -p "${CERT_DIR}"
    mkdir -p "${CERT_DIR_OCI}"
    mkdir -p "${CERT_DIR_ENTERPRISE_CONTAINER}"
}

# =============================================================================
# init_jwt()
# =============================================================================
# Generates the ECDSA key pair used for Enterprise Container JWT signing.
#
# The function creates a P-256 private key in PEM format and derives the
# corresponding public key. Both keys are stored in the Enterprise Container
# certificate directory, replacing any existing files with the same names.
init_jwt() {
    echo "Info: Install Enterprise-Container JWT..."
    openssl genpkey \
        -algorithm EC \
        -outform PEM \
        -quiet \
        -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.private.pem" \
        -pkeyopt ec_paramgen_curve:"P-256" \
        -pkeyopt ec_param_enc:named_curve
    openssl ec \
        -in "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.private.pem" \
        -pubout \
        -outform PEM \
        -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.public.pem"
}

# =============================================================================
# init_certs()
# =============================================================================
# Creates the TLS certificates used by the Enterprise Container deployment.
#
# The function generates a 2048-bit RSA certificate authority and a client
# certificate signed by that authority, each valid for 365 days. For the
# ingress server, it installs the configured certificate and private key when
# both files are available; otherwise, it generates a self-signed server
# certificate valid for 365 days. Existing output files may be replaced.
init_certs() {
    # Create Enterprise-Container CA certificate
    echo "Info: Install Enterprise-Container TLS certificates..."
    openssl genrsa -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.key" 2048 2>/dev/null
    openssl req -new -x509 -key "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.key" -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" -days 365 \
       -addext "basicConstraints=CA:TRUE" \
       -subj "/CN=enterprise-container-ca" 2>/dev/null

    # Create Enterprise-Container Client certificate
    openssl genrsa -out "${CERT_DIR_ENTERPRISE_CONTAINER}/client.key" 2048 2>/dev/null
    openssl req -new -key "${CERT_DIR_ENTERPRISE_CONTAINER}/client.key" -out "${CERT_DIR_ENTERPRISE_CONTAINER}/client.csr" \
        -subj "/CN=enterprise-container-client" 2>/dev/null
    openssl x509 -req -in "${CERT_DIR_ENTERPRISE_CONTAINER}/client.csr" -out "${CERT_DIR_ENTERPRISE_CONTAINER}/client.crt" -days 365 \
        -CA "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.crt" -CAkey "${CERT_DIR_ENTERPRISE_CONTAINER}/ca.key" \
        -extfile <(printf '%s\n' "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth" "keyUsage=digitalSignature,keyEncipherment") 2>/dev/null

    # Create Enterprise-Container Ingress Server certificate
    echo "Info: Install Enterprise-Container Ingress TLS certificates..."
    if [ -f "${INGRESS_TLS_SERVER_CERT}" ] && [ -f "${INGRESS_TLS_SERVER_KEY}" ]; then
        echo "Info: Using Ingress certs ${INGRESS_TLS_SERVER_CERT} and ${INGRESS_TLS_SERVER_KEY} ..."
        install -m 0600 "${INGRESS_TLS_SERVER_CERT}" "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt"
        install -m 0600 "${INGRESS_TLS_SERVER_KEY}" "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key"
    else
        echo "Create self sign Ingress certs!"
        openssl genrsa -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key" 2048 2>/dev/null
        openssl req -new -x509 -key "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key" -out "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt" -days 365 \
           -addext "basicConstraints=CA:FALSE" -addext "extendedKeyUsage=serverAuth" -addext "keyUsage=digitalSignature,keyEncipherment" \
           -subj "/CN=openvas-enterprise-container" 2>/dev/null
    fi
}

# =============================================================================
# install_oci_certs()
# =============================================================================
# Installs the TLS client certificate and private key for OCI deployments.
#
# The function copies the configured OCI client certificate and private key
# into the OCI certificate directory with permissions restricted to the file
# owner. Existing files with the same names are replaced.
install_oci_certs(){
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
# install_license_file()
# =============================================================================
# Installs the license file and extracts its embedded OCI client credentials.
#
# The first argument names the associative array containing the parsed license
# data and defaults to LICENSE_DATA. The second and third arguments name the
# variables that receive the generated OCI client certificate and key paths.
#
# The function verifies that LICENSE_FILE exists, installs it in the OCI
# certificate directory with owner-only permissions, writes the embedded
# certificate and private key to separate files, and updates the referenced
# path variables. It exits with a non-zero status when the license file is
# missing.
install_license_file() {
    local -n license_data="${1:-LICENSE_DATA}"
    local -n oci_tls_client_cert="${2:-OCI_TLS_CLIENT_CERT}"
    local -n oci_tls_client_key="${3:-OCI_TLS_CLIENT_KEY}"

    if ! [ -f "${LICENSE_FILE}" ]; then
        echo "Error: --license-file argument missing or file ${LICENSE_FILE} not found!"
        exit 1
    fi

    install -m 0600 "${LICENSE_FILE}" "${CERT_DIR_OCI}/license.toml"

    echo "${license_data[license.certificate.cert]}" > "${CERT_DIR_OCI}/client.crt"
    oci_tls_client_cert="${CERT_DIR_OCI}/client.crt"
    echo "${license_data[license.certificate.key]}" > "${CERT_DIR_OCI}/client.key"
    oci_tls_client_key="${CERT_DIR_OCI}/client.key"
}

# =============================================================================
# install_feed_key()
# =============================================================================
# Installs the Enterprise Container feed key when the configured file exists.
#
# The function copies FEED_KEY into the Enterprise Container certificate
# directory as feed.key with permissions restricted to the file owner. If the
# source file does not exist, the function performs no action.
install_feed_key(){
    if [ -f "${FEED_KEY}" ]; then
        echo "Info: Install Enterprise-Container Feed Key..."
        install -m 0600 "${FEED_KEY}" "${CERT_DIR_ENTERPRISE_CONTAINER}/feed.key"
    fi
}

# =============================================================================
# init()
# =============================================================================
# Initializes the Enterprise Container scan deployment.
#
# The function validates the required OCI client certificate and key, warns
# before overwriting an existing working directory, and prompts for confirmation
# when the feed key is unavailable. It also determines
# whether Docker OCI certificates should be installed with elevated privileges.
#
# After validation, the function creates the required directories, initializes
# the environment, installs or generates certificates and keys, configures
# Docker OCI access, and initializes the administrator password. It exits with
# a non-zero status when required files are missing or the user cancels.
init() {
    echo "🚀 Init Enterprise Container Mode Scan..."

    if [ -d "${WORKING_DIR}" ]; then
        echo "Warning: ${WORKING_DIR} exist! CA setup will be overwritten if continue!"
        read -r -p "Continue? (y/n)" response
        if [ "$response" != "y" ]; then
            exit 1
        fi
    fi
    if ! [ -f "${FEED_KEY}" ]; then
        echo "Error: --feed-key argument missing!"
        echo "Info: Feed Mount options are not implemented."
        exit 1
    fi
    if ! [ "${INIT_DOCKER_OCI}" ]; then
        echo "Info: Do you want to install dockerd OCI certs with sudo? Otherwise the commands are printed here."
        read -r -p "Install? (y/n)" INIT_DOCKER_OCI
    fi

    init_base_folders
    init_env

    if [ "${LICENSE_FILE}" ]; then
        read_license_file
        install_license_file
    else
        echo "Info: No --license-file set, try to use --oci-client-cert and --oci-client-key."
        install_oci_certs
    fi

    init_certs
    init_jwt
    install_feed_key
    init_docker_oci
    init_admin_password

    echo "Init done!"
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
    install -m 0600 "${INGRESS_TLS_SERVER_CERT}" "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt"
    install -m 0600 "${INGRESS_TLS_SERVER_KEY}" "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key"

    read -r -p "Info: We need to redeploy the compose stack, to activate the new Ingress certificates. (y/n)" response
    if [ "$response" == "y" ]; then
        deploy
    fi
}

# =============================================================================
# artifact_download()
# =============================================================================
# Downloads the latest OpenVAS Enterprise-Container artifact using `oras`, extracts it, and
# prepares it for deployment.
artifact_download() {
    echo "🚀 Downloading product..."

    # Check certs exist
    if ! [ -f "${CERT_DIR_OCI}/client.crt" ]; then
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_ENTERPRISE_CONTAINER}/server.crt! Please run --init!"
        exit 1
    fi
    if ! [ -f "${CERT_DIR_OCI}/client.key" ]; then
        echo "Error: No OCI TLS certificate found at ${CERT_DIR_ENTERPRISE_CONTAINER}/server.crt! Please run --init!"
        exit 1
    fi

    # Get latest version
    set +e
    VERSION="$(oras repo tags --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PACKAGE_URL}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sed '/-/! s/$/_/' | sort -Vu | sed 's/_$//' | tail -1)"
    set -e

    # Check if VERSION exist
    if ! [ "${VERSION}" ]; then
        echo "Error: No product release found in registry ${PACKAGE_URL}!"
        echo "For support, visit: https://www.greenbone.net/support/"
        exit 1
    fi

    # Check if compose files already exist
    if [ -f "$ARTIFACT_DIR/${VERSION}/compose.yaml" ]; then
        echo "Info: Latest version ${VERSION} already downloaded."
        return 0
    fi

    # Create artifact dir
    mkdir -p "$ARTIFACT_DIR/${VERSION}"

    # Download artifact
    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        oras pull --cert-file "${CERT_DIR_OCI}/client.crt" --key-file "${CERT_DIR_OCI}/client.key" "${PACKAGE_URL}:${VERSION}"
        tar  xzf "${PACKAGE}.tar.gz"
        rm -f "${PACKAGE}.tar.gz"
    popd > /dev/null
}


# =============================================================================
# get_latest_version()
# =============================================================================
# Gets the latest downloaded OpenVAS Enterprise-Container artifact version.
get_latest_version() {
    if [ -d "${ARTIFACT_DIR}" ]; then
        set +e
        VERSION="$(ls "${ARTIFACT_DIR}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sed '/-/! s/$/_/' | sort -Vu | sed 's/_$//' | tail -1)"
        set -e
        if ! [ "${VERSION}" ]; then
            echo "Error: No product downloaded! Please run --update!"
            exit 1
        fi
    else
        echo "Error: No working directory exist! Please run --init and/or --update!"
        exit 1
    fi
}

# =============================================================================
# deploy_load_certs_openvasd()
# =============================================================================
# Loads the OpenVASD TLS credentials for the configured instance and exports
# them for use by the deployment environment.
#
# Reads the OpenVASD common name from WORKING_DIR, derives the corresponding
# certificate directory, and loads the server certificate, server private key,
# and trusted client CA certificate into OPENVAS_SCANNER_TLS_CERT,
# OPENVAS_SCANNER_TLS_KEY, and OPENVAS_TLS_CLIENT_CA.
#
# Terminates the script when the common name or any required certificate file
# is missing.
deploy_load_certs_openvasd() {
    if [ -f "${WORKING_DIR}/OPENVASD_CN" ]; then
        local openvasd_cn="$(< "${WORKING_DIR}/OPENVASD_CN")"
    else
        echo "Error: No Openvasd cn found at ${WORKING_DIR}/OPENVASD_CN! Please run --init-openvasd!"
        exit 1
    fi
    local openvasd_cert_folder="${openvasd_cn//./_}"
    local cert_dir_openvasd="${CERT_DIR_ENTERPRISE_CONTAINER}/${openvasd_cert_folder}"

    if [ -f "${cert_dir_openvasd}/server.crt" ]; then
        export OPENVAS_SCANNER_TLS_CERT="$(< "${cert_dir_openvasd}/server.crt")"
    else
        echo "Error: No enterprise-container TLS certificate found at ${cert_dir_openvasd}/server.crt! Please run --init-openvasd!"
        exit 1
    fi
    if [ -f "${cert_dir_openvasd}/server.key" ]; then
        export OPENVAS_SCANNER_TLS_KEY="$(< "${cert_dir_openvasd}/server.key")"
    else
        echo "Error: No enterprise-container TLS private key found at ${cert_dir_openvasd}/server.key! Please run --init-openvasd!"
        exit 1
    fi
    if [ -f "${cert_dir_openvasd}/ca.crt" ]; then
        export OPENVAS_TLS_CLIENT_CA="$(< "${cert_dir_openvasd}/ca.crt")"
    else
        echo "Error: No enterprise-container TLS CA certificate found at ${cert_dir_openvasd}/ca.crt! Please run --init-openvasd!"
        exit 1
    fi
}

# =============================================================================
# deploy_load_certs_scan()
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
deploy_load_certs_scan() {
    if [ -f "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt" ]; then
        export INGRESS_CERTIFICATE="$(< "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt")"
    else
        echo "Error: No enterprise-container Ingress TLS certificate found at ${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.crt! Please run --init!"
        exit 1
    fi
    if [ -f "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key" ]; then
        export INGRESS_PRIVATE_KEY="$(< "${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key")"
    else
        echo "Error: No enterprise-container Ingress TLS private key found at ${CERT_DIR_ENTERPRISE_CONTAINER}/ingress_server.key! Please run --init!"
        exit 1
    fi

    if [ -f "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.private.pem" ]; then
        export OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_KEY="$(< "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.private.pem")"
    else
        echo "Error: No enterprise-container feed key service ecdsa key found at ${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.private.pem! Please run --init!"
        exit 1
    fi
    if [ -f "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.public.pem" ]; then
        export OPENVAS_FEED_KEY_SERVICE_JWT_ECDSA_PUBLIC_KEY="$(< "${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.public.pem")"
    else
        echo "Error: No enterprise-container feed key service public ecdsa key found at ${CERT_DIR_ENTERPRISE_CONTAINER}/ecdsa.public.pem! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# deploy()
# =============================================================================
# Starts the configured OpenVAS Enterprise Container deployment.
#
# Loads the persisted environment, selects the latest downloaded product
# version, and prepares deployment-specific credentials. For volume-based feed
# operation, it exports the feed synchronization key. Depending on
# DEPLOYMENT_MODE, it also loads either the OpenVASD TLS credentials or the scan
# ingress and JWT credentials. Packaged OpenVASD images are loaded when
# OPENVASD_LOAD_IMAGES_FROM_TAR is set to "y".
#
# Restarts the selected Docker Compose deployment, removes orphaned containers,
# and waits for the services to become ready. Terminates the script when
# required credentials are missing or the deployment fails.
deploy() {
    load_env

    echo "🚀 Starting OpenVAS Enterprise-Container ${DEPLOYMENT_MODE}..."

    get_latest_version

    echo "Info: Using OpenVAS Enterprise-Container mode ${DEPLOYMENT_MODE} in version ${VERSION}."

    if [ "$FEED_MODE" == 'volume' ]; then
        if [ -f "${CERT_DIR_ENTERPRISE_CONTAINER}/feed.key" ]; then
            export FEED_SYNC_GSF_KEY="$(< "${CERT_DIR_ENTERPRISE_CONTAINER}/feed.key")"
        else
            echo "Error: No Feed key found at ${CERT_DIR_ENTERPRISE_CONTAINER}/feed.key! Please run --init!"
            exit 1
        fi
    fi

    if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
        deploy_load_certs_openvasd
        # Todo: put me into file
        if [ "${OPENVASD_PORT}" ]; then
            export OPENVAS_SCANNER_HOST_LISTEN_PORT="${OPENVASD_PORT}"
        fi
        if [ "${OPENVASD_LOAD_IMAGES_FROM_TAR}" == 'y' ]; then
            load_openvasd_images
        fi
    elif [ "${DEPLOYMENT_MODE}" == 'scan' ]; then
        deploy_load_certs_scan
    fi

    # Run deployment
    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down --remove-orphans 2>/dev/null || true
        if docker compose --env-file settings.env up -d --wait --wait-timeout 7200 --quiet-pull --remove-orphans ; then
            echo "OpenVAS Enterprise-Container deployment successful!"
            echo "Service status: $0 --ps"
            echo "For support, visit: https://www.greenbone.net/support/"
        else
            echo "Deployment failed!"
            echo "Troubleshooting: $0 --logs"
            echo "For support, visit: https://www.greenbone.net/support/"
            exit 1
        fi
    popd > /dev/null
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
    echo "🚀 Stopping OpenVAS Enterprise-Container and removing Docker volumes..."

    load_env

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down --remove-orphans --volumes
    popd > /dev/null

    echo "OpenVAS Enterprise-Container stopped and Docker volumes removed."
}

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
    echo "🚀 Stopping OpenVAS Enterprise-Container..."

    load_env

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down
    popd > /dev/null

    echo "OpenVAS Enterprise-Container stopped."
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
    echo "🚀 Print Enterprise-Container Logs..."

    load_env

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
    echo "🚀 Print Enterprise-Container Container..."

    load_env

    get_latest_version

    echo "Info: Using version ${VERSION}."

    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose ps
    popd > /dev/null
}

# =============================================================================
# run()
# =============================================================================
# The run function orchestrates the execution of the script.
run() {
    check_requirements

    if [ "${MODE}" == 'init' ]; then
        init
    fi
    if [ "${MODE}" == 'init-openvasd' ]; then
        init_openvasd
    fi
    if [ "${MODE}" == 'create-openvasd-tar' ]; then
        create_openvasd_tar
    fi
    if [ "${MODE}" == 'update' ]; then
        artifact_download
    fi
    if [ "${MODE}" == 'run' ]; then
        deploy
    fi
    if [ "${MODE}" == 'down' ]; then
        compose_down
    fi
    if [ "${MODE}" == 'down-volumes' ]; then
        compose_down_volumes
    fi
    if [ "${MODE}" == 'create-openvasd-cert' ]; then
        create_openvasd_cert
    fi
    if [ "${MODE}" == 'get-openvasds' ]; then
        get_openvasds
    fi
    if [ "${MODE}" == 'add-openvasd' ]; then
        add_openvasd
    fi
    if [ "${MODE}" == 'del-openvasd' ]; then
        del_openvasd
    fi
    if [ "${MODE}" == 'update-ingress-certs' ]; then
        update_ingress_certs
    fi
    if [ "${MODE}" == 'change-admin-password' ]; then
        change_admin_password
    fi
    if [ "${MODE}" == 'force-feed-sync' ]; then
        force_feed_sync
    fi
    if [ "${MODE}" == 'change-feed-sync-hour' ]; then
        change_feed_sync_hour
    fi
    if [ "${MODE}" == 'logs' ]; then
        compose_logs
    fi
    if [ "${MODE}" == 'ps' ]; then
        compose_ps
    fi
    if [ "${MODE}" == '' ]; then
        show_help
    fi
}

# =============================================================================
# parse_args()
# =============================================================================
# Parses the command-line arguments and initializes the corresponding global
# variables that control the script's behavior.
#
# Supported options include:
#   - Selecting the execution mode (MODE)
#   - Configuring deployment settings
#   - Providing certificate, key, and license file paths
#   - Configuring feed synchronization options
#   - Managing OpenVASD instances and certificates
#   - Controlling Docker OCI initialization
#
# If no arguments are provided, or if --help is specified, the help message is
# displayed via show_help().
#
# Globals modified:
#   MODE
#   DEPLOYMENT_MODE
#   LICENSE_FILE
#   OCI_TLS_CLIENT_CERT
#   OCI_TLS_CLIENT_KEY
#   INIT_DOCKER_OCI
#   GREENBONE_FEED_SYNC_JOB_HOUR
#   GVMD_ADMIN_PASSWORD
#   INGRESS_TLS_SERVER_CERT
#   INGRESS_TLS_SERVER_KEY
#   FEED_KEY
#   FEED_MODE
#   CCERT_MODE
#   FEED_PATH
#   CCERT_PATH
#   OPENVASD_TAR_WITH_IMAGES
#   OPENVASD_LOAD_IMAGES_FROM_TAR
#   CN_OPENVASD
#   OPENVASD_UUID
#   OPENVASD_PORT
#
# Arguments:
#   All command-line arguments passed to the script ("$@").
#
# Returns:
#   None.
parse_args() {
    if [ $# -eq 0 ]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --init)
                MODE='init'
                shift 1
                ;;
            --init-openvasd)
                MODE='init-openvasd'
                shift 1
                ;;
            --deployment-mode)
                DEPLOYMENT_MODE="$2"
                shift 2
                ;;
            --license-file)
                LICENSE_FILE="$2"
                shift 2
                ;;
            --oci-client-cert)
                OCI_TLS_CLIENT_CERT="$2"
                shift 2
                ;;
            --oci-client-key)
                OCI_TLS_CLIENT_KEY="$2"
                shift 2
                ;;
            --init-docker-oci)
                INIT_DOCKER_OCI='y'
                shift 1
                ;;
            --skip-docker-oci)
                INIT_DOCKER_OCI='n'
                shift 1
                ;;
            --force-feed-sync)
                MODE='force-feed-sync'
                shift 1
                ;;
            --change-feed-sync-hour)
                MODE='change-feed-sync-hour'
                shift 1
                ;;
            --feed-sync-hour)
                GREENBONE_FEED_SYNC_JOB_HOUR="$2"
                shift 2
                ;;
            --change-admin-password)
                MODE='change-admin-password'
                shift 1
                ;;
            --admin-password)
                GVMD_ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --update-ingress-certs)
                MODE='update-ingress-certs'
                shift 1
                ;;
            --ingress-server-cert)
                INGRESS_TLS_SERVER_CERT="$2"
                shift 2
                ;;
            --ingress-server-key)
                INGRESS_TLS_SERVER_KEY="$2"
                shift 2
                ;;
            --feed-key)
                FEED_KEY="$2"
                shift 2
                ;;
            --feed-mode)
                FEED_MODE="$2"
                shift 2
                ;;
            --ccert-mode)
                CCERT_MODE="$2"
                shift 2
                ;;
            --feed-path)
                FEED_PATH="$2"
                shift 2
                ;;
            --ccert-path)
                CCERT_PATH="$2"
                shift 2
                ;;
            --create-openvasd-tar)
                MODE='create-openvasd-tar'
                shift 1
                ;;
            --openvasd-tar-with-images)
                OPENVASD_TAR_WITH_IMAGES='y'
                shift 1
                ;;
            --openvasd-load-images-from-tar)
                OPENVASD_LOAD_IMAGES_FROM_TAR='y'
                shift 1
                ;;
            --create-openvasd-certs)
                MODE='create-openvasd-cert'
                shift 1
                ;;
            --get-openvasds)
                MODE='get-openvasds'
                shift 1
                ;;
            --add-openvasd)
                MODE='add-openvasd'
                shift 1
                ;;
            --del-openvasd)
                MODE='del-openvasd'
                shift 1
                ;;
            --cn-openvasd)
                CN_OPENVASD="$2"
                shift 2
                ;;
            --openvasd-uuid)
                OPENVASD_UUID="$2"
                shift 2
                ;;
            --openvasd-port)
                OPENVASD_PORT="$2"
                shift 2
                ;;
            --run)
                MODE='run'
                shift 1
                ;;
            --down)
                MODE='down'
                shift 1
                ;;
            --down-volumes)
                MODE='down-volumes'
                shift 1
                ;;
            --update)
                MODE='update'
                shift 1
                ;;
            --logs)
                MODE='logs'
                shift 1
                ;;
            --service-name)
                SERVICE_NAME="$2"
                shift 2
                ;;
            --ps)
                MODE='ps'
                shift 1
                ;;
            -h|--help)
                show_help
                ;;
            *)
                shift
                ;;
        esac
    done
}

# =============================================================================
# main()
# =============================================================================
# Entry point of the script.
#
# Parses the command-line arguments and then invokes the main execution
# routine based on the selected mode and configuration.
main() {
    parse_args "$@"
    run
}

main "$@"
