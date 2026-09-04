
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
    OPENVASD_FOLDER="${CERT_DIR_PRODUCT}/${OPENVASD_FOLDER}"

    set +e

    status_code=$(curl -sS -o /dev/null \
        --cacert "${CERT_DIR_PRODUCT}/ca.crt" \
        --cert "${CERT_DIR_PRODUCT}/client.crt" \
        --key "${CERT_DIR_PRODUCT}/client.key" \
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

    docker cp "${CERT_DIR_PRODUCT}/client.key" "${GVMD_CONTAINER}:/tmp/client.key"
    docker cp "${CERT_DIR_PRODUCT}/client.crt" "${GVMD_CONTAINER}:/tmp/client.crt"
    docker cp "${CERT_DIR_PRODUCT}/ca.crt" "${GVMD_CONTAINER}:/tmp/ca.crt"

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
# create_openvasd_cert()
# =============================================================================
# Creates a server certificate, private key, and CA certificate bundle for an
# OpenVASD scanner using the configured OpenVASD common name. Stores the generated
# files in a certificate directory derived from the common name and prints the
# target paths where the files should be copied on the remote OpenVASD machine.
create_openvasd_cert() {
    local openvasd_cn="${1:-$CN_OPENVASD}"
    local cert_dir_product="${2:-$CERT_DIR_PRODUCT}"

    if ! [ "${openvasd_cn}" ]; then
        echo "Error: --cn-openvasd argument missing. Required for --create-openvasd-certs !"
        exit 1
    fi

    local openvas_folder_name="${openvasd_cn//./_}"
    local openvas_folder="${cert_dir_product}/${openvas_folder_name}"
    local openvasd_name="${openvasd_cn//./-}"

    mkdir -p "${openvas_folder}"

    # Create a Openvasd Server certificate
    openssl genrsa -out "${openvas_folder}/server.key" 2048 2>/dev/null
    openssl req -new -key "${openvas_folder}/server.key" -out "${openvas_folder}/server.csr" \
       -subj "/CN=${openvasd_cn}" 2>/dev/null
    openssl x509 -req -in "${openvas_folder}/server.csr" -out "${openvas_folder}/server.crt" -days 365 \
       -CA "${cert_dir_product}/ca.crt" -CAkey "${cert_dir_product}/ca.key" \
       -extfile <(printf '%s\n' "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "keyUsage=digitalSignature,keyEncipherment") 2>/dev/null
    cp "${cert_dir_product}/ca.crt" "${openvas_folder}/ca.crt"

    cat << EOF
Remote OpenVASD sensor setup:

Option 1:

Use ${0} to deploy OpenVASD on another host/node.

  ${0} --create-openvasd-certs --cn-openvasd ${openvasd_cn}
  ${0} --create-openvasd-cert-tar --cn-openvasd ${openvasd_cn}

Copy the following files to the new host:
  - ${0}
  - ./${openvasd_name}.tar
  - your feed key
  - your oci client certs

Extract the archive.

Initialize the remote OpenVASD deployment:
  ${0} --init --deployment-mode openvasd \\
    --cn-openvasd ${openvasd_cn} \\
    --oci-client-cert oci.crt \\
    --oci-client-key oci.key \\
    --feed-key key \\
    --openvasd-server-cert server.crt \\
    --openvasd-server-key server.key \\
    --openvasd-client-ca ca.crt

  ${0} --update
  ${0} --run

Register an OpenVASD scanner on an enterprise-container
(SCAN deployment mode) node/host:

  ${0} --add-openvasd \\
    --cn-openvasd ${openvasd_cn}\\
    --openvasd-port 443

========================================================================
Option 2:

Create an OpenVASD deployment archive for an external sensor:

  ${0} --create-openvasd-tar --cn-openvasd ${openvasd_cn}

Include Docker images in the archive (no --init-openvasd required):

  ${0} --create-openvasd-tar \\
    --cn-openvasd ${openvasd_cn} \\
    --openvasd-tar-with-images


Deploy the sensor from an archive:

1. Copy the archive ${openvasd_name}.tar.gz to the OpenVASD sensor host.
2. Extract the archive.
3. Initialize and start the sensor:

  ${0} --init-openvasd
  ${0} --run


Load packaged Docker images before starting the sensor
(no --init-openvasd required):

  ${0} --run --openvasd-load-images-from-tar


Optionally, use a custom OpenVASD listen port:

  ${0} --run \\
    --openvasd-load-images-from-tar \\
    --openvasd-port <PORT>


Register an OpenVASD scanner on an enterprise-container
(SCAN deployment mode) node/host:

  ${0} --add-openvasd \\
    --cn-openvasd ${openvasd_cn} \\
    --openvasd-port 443

========================================================================
Option 3:

Alternatively, copy the generated certificate files to the OpenVASD sensor host:

  ${openvas_folder}/server.crt -> <config-folder>/server.crt
  ${openvas_folder}/server.key -> <config-folder>/server.key
  ${openvas_folder}/ca.crt     -> <config-folder>/clients/ca.crt


Configure OpenVASD to use the TLS certificates and restart the
OpenVASD service.

Register an OpenVASD scanner on an enterprise-container
(SCAN deployment mode) node/host:

  ${0} --add-openvasd \\
    --cn-openvasd ${openvasd_cn} \\
    --openvasd-port 443
EOF
}

# =============================================================================
# create_openvasd_cert_tar()
# =============================================================================
# Creates a tar archive containing the OpenVASD certificate directory for the
# configured OpenVASD common name (CN).
#
# The certificate directory name is derived from the OpenVASD CN by replacing
# dots with underscores.
#
# Arguments:
#   $1
#     OpenVASD common name (CN) used to identify the certificate directory.
#     Defaults to CN_OPENVASD.
#
#   $2
#     Base certificate directory containing the OpenVASD certificate folders.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name is missing.
#   1 if the OpenVASD certificate directory does not exist.
create_openvasd_cert_tar() {
    local openvasd_cn="${1:-$CN_OPENVASD}"
    local cert_dir_product="${2:-$CERT_DIR_PRODUCT}"

    if ! [ "${openvasd_cn}" ]; then
        echo "Error: --cn-openvasd argument missing!"
        exit 1
    fi

    local openvasd_folder_name="${openvasd_cn//./_}"
    local openvasd_folder="${cert_dir_product}/${openvasd_folder_name}"
    local openvasd_name="${openvasd_cn//./-}"

    if ! [ -d "${openvasd_folder}" ]; then
        echo "Error: ${openvasd_folder} does not exist!"
        exit 1
    fi
    tar cf "${openvasd_name}.tar" -C "${openvasd_folder}" .
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

    load_settings

    local openvasd_name="${CN_OPENVASD//./-}"
    local openvasd_cert_folder="${CN_OPENVASD//./_}"
    openvasd_cert_folder="${CERT_DIR_PRODUCT}/${openvasd_cert_folder}"
    local tmp_dir="$(mktemp -d)"
    local tmp_images="${tmp_dir}/${STORE_DIR_NAME}/${IMAGE_DIR_NAME}/${PRODUCT}"
    pushd "${tmp_dir}" > /dev/null || exit
        mkdir -p "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}"
        mkdir -p "${STORE_DIR_NAME}/${CERT_DIR_NAME}/${PRODUCT}"
        mkdir -p "${STORE_DIR_NAME}/${ARTIFACT_DIR_NAME}"
        cp -r "${CERT_DIR_OCI}" "${STORE_DIR_NAME}/${CERT_DIR_NAME}/"
        cp -r "${ARTIFACT_DIR}" "${STORE_DIR_NAME}/${ARTIFACT_DIR_NAME}/"
        cp -r "${openvasd_cert_folder}" "${STORE_DIR_NAME}/${CERT_DIR_NAME}/${PRODUCT}/"
        cp "${CERT_DIR_PRODUCT}/feed.key" "${STORE_DIR_NAME}/${CERT_DIR_NAME}/${PRODUCT}/"
        echo 'enterprise-container' > "${STORE_DIR_NAME}/PRODUCT"
        echo 'openvasd' > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/DEPLOYMENT_MODE"
        echo "${GREENBONE_FEED_SYNC_JOB_HOUR}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/GREENBONE_FEED_SYNC_JOB_HOUR"
        echo "${CN_OPENVASD}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/OPENVASD_CN"
        echo "${FEED_MODE}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/FEED_MODE"
        echo "${CCERT_MODE}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/CCERT_MODE"
        echo "${FEED_PATH}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/FEED_PATH"
        echo "${CCERT_PATH}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/CCERT_PATH"
        echo "${CCERT_TYPE}" > "${STORE_DIR_NAME}/${SETTINGS_DIR_NAME}/${PRODUCT}/CCERT_TYPE"
    popd > /dev/null

    cp "${0}" "${tmp_dir}"

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
# init_openvasd()
# =============================================================================
# Initializes the OpenVASD deployment by configuring the OCI client
# certificates used by dockerd.
init_openvasd_tar() {
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
