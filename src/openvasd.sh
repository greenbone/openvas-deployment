# =============================================================================
# add_openvasd()
# =============================================================================
# Registers an OpenVASD instance as a scanner in the gvmd container.
#
# The function validates the required OpenVASD common name and port, verifies
# that the remote OpenVASD instance is ready using its TLS-protected readiness
# endpoint, and aborts if the endpoint does not return HTTP status 200.
#
# If the instance is ready, the function copies the Enterprise-Container client
# certificate, client private key, and CA certificate into the gvmd container,
# adjusts their permissions, and invokes gvmd to create the OpenVASD scanner.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if CN_OPENVASD is not set.
#   1 if OPENVASD_PORT is not set.
#   1 if the OpenVASD readiness endpoint does not return HTTP status 200.
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

    docker exec -u "0" "${GVMD_CONTAINER}" install -d -m 0700 \
        -o "${GVMD_CONTAINER_UID}" \
        "/tmp/openvasd_crt"

    docker cp "${CERT_DIR_PRODUCT}/client.key" "${GVMD_CONTAINER}:/tmp/openvasd_crt/client.key"
    docker cp "${CERT_DIR_PRODUCT}/client.crt" "${GVMD_CONTAINER}:/tmp/openvasd_crt/client.crt"
    docker cp "${CERT_DIR_PRODUCT}/ca.crt" "${GVMD_CONTAINER}:/tmp/openvasd_crt/ca.crt"

    docker exec -u "0" "${GVMD_CONTAINER}" \
        chown "${GVMD_CONTAINER_UID}" \
        "/tmp/openvasd_crt/client.key" \
        "/tmp/openvasd_crt/client.crt" \
        "/tmp/openvasd_crt/ca.crt"

    docker exec -u "0" "${GVMD_CONTAINER}" \
        chmod 0600 "/tmp/openvasd_crt/client.key"

    docker exec -u "0" "${GVMD_CONTAINER}" \
        chmod 0644 \
        "/tmp/openvasd_crt/client.crt" \
        "/tmp/openvasd_crt/ca.crt"

    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd \
        --create-scanner="${OPENVASD_NAME}" \
        --scanner-host="${CN_OPENVASD}" \
        --scanner-port="${OPENVASD_PORT}" \
        --scanner-type="OPENVASD" \
        --scanner-ca-pub="/tmp/openvasd_crt/ca.crt" \
        --scanner-key-pub="/tmp/openvasd_crt/client.crt" \
        --scanner-key-priv="/tmp/openvasd_crt/client.key"

    docker exec -u "0" "${GVMD_CONTAINER}" rm -rf "/tmp/openvasd_crt"
}

# =============================================================================
# create_openvasd_cert()
# =============================================================================
# Creates a TLS server certificate for a remote OpenVASD instance.
#
# The function validates the OpenVASD common name (CN), creates a dedicated
# certificate directory derived from the CN, and generates a server private
# key, certificate signing request, and server certificate signed by the
# Enterprise-Container CA. The CA certificate is copied into the OpenVASD
# certificate directory as well.
#
# After certificate generation, the function prints setup instructions for
# deploying and registering the remote OpenVASD sensor using several supported
# deployment methods.
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     Product certificate directory containing ca.crt and ca.key.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name is not provided.
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
    --product enterprise-container \\
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

Or include Docker images in the archive (no --init-openvasd-tar required):

  ${0} --create-openvasd-tar \\
    --cn-openvasd ${openvasd_cn} \\
    --openvasd-tar-with-images


Deploy the sensor from an archive:

1. Copy the archive ${openvasd_name}.tar.gz to the OpenVASD sensor host.
2. Extract the archive.
3. Initialize and start the sensor:

  ${0} --init-openvasd-tar
  ${0} --run

Or load Docker images from the archive (no --init-openvasd-tar required):

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
# Creates a tar archive containing the TLS certificate files for an OpenVASD
# instance.
#
# The function derives the OpenVASD-specific certificate directory and archive
# name from the provided common name (CN), verifies that the certificate
# directory exists, and archives its contents into a tar file in the current
# working directory.
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     Product certificate directory.
#     Defaults to CERT_DIR_PRODUCT.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name is not provided.
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

    rm -f "${openvasd_name}.tar"
    (umask 077; tar cf "${openvasd_name}.tar" -C "${openvasd_folder}" .)
}

# =============================================================================
# create_openvasd_tar()
# =============================================================================
# Creates a gzip-compressed deployment archive for an OpenVASD sensor.
#
# The function validates the OpenVASD common name, retrieves the latest
# product version, and assembles a deployment directory in a temporary
# location with restricted permissions (0700).
#
# The deployment directory contains:
#   - OCI certificates.
#   - OpenVASD-specific product certificates and the feed key.
#   - Product artifacts for the latest version.
#   - A copy of the configured settings directory.
#   - The current deployment script.
#   - Optionally, Docker images required for deployment.
#
# The settings directory is copied without modifying the source files.
# The archive's root PRODUCT setting is initialized to
# "enterprise-container", while DEPLOYMENT_MODE is set to "openvasd"
# in the product-specific settings directory.
#
# If image inclusion is enabled, the function loads the required secrets
# and certificates and exports the following Docker images:
#   - openvas-scanner
#   - gpg-data
#   - greenbone-feed-sync
#   - redis-server
#
# The feed-key-service image is additionally exported when feed_mode is
# set to "service".
#
# The resulting archive is named <openvasd_name>.tar.gz, where dots in
# the OpenVASD common name are replaced with dashes. It is written to
# the current working directory, replacing an existing archive with
# the same name.
#
# Archive creation uses a restrictive umask (077). The temporary
# deployment directory is removed after the archive command completes.
#
# Arguments:
#   1. cn_openvasd:
#      OpenVASD common name used for certificate lookup and archive naming.
#      Defaults to CN_OPENVASD.
#   2. cert_dir_product:
#      Source directory containing product certificates and the feed key.
#      Defaults to CERT_DIR_PRODUCT.
#   3. openvasd_tar_with_images:
#      Controls whether Docker images are included ('y' to enable).
#      Defaults to OPENVASD_TAR_WITH_IMAGES.
#   4. feed_mode:
#      Determines whether the feed-key-service image is included when
#      Docker image inclusion is enabled ('service' to enable).
#      Defaults to FEED_MODE.
#   5. store_dir_name:
#      Name of the deployment store directory inside the archive.
#      Defaults to STORE_DIR_NAME.
#   6. cert_dir_name:
#      Name of the certificate directory inside the archive.
#      Defaults to CERT_DIR_NAME.
#   7. cert_dir_oci:
#      Source directory containing OCI certificates.
#      Defaults to CERT_DIR_OCI.
#   8. artifact_dir:
#      Source directory containing versioned product artifacts.
#      Defaults to ARTIFACT_DIR.
#   9. artifact_dir_name:
#      Name of the artifact directory inside the archive.
#      Defaults to ARTIFACT_DIR_NAME.
#   10. image_dir_name:
#       Name of the Docker image directory inside the archive.
#       Defaults to IMAGE_DIR_NAME.
#   11. settings_dir_name:
#       Name of the settings directory inside the archive.
#       Defaults to SETTINGS_DIR_NAME.
#   12. product:
#       Product name used for the deployment directory layout and
#       product-specific settings, certificates, artifacts, and images.
#       Defaults to PRODUCT.
#   13. settings_dir:
#       Source directory containing deployment settings to be copied
#       into the product-specific settings directory.
#       Defaults to SETTINGS_DIR.
#
# Returns:
#   No explicit return value. Creates a gzip-compressed tar archive
#   in the current working directory.
#
# Exits:
#   1 if the OpenVASD common name is empty.
#   Exits if changing to the temporary or artifact directory fails.
create_openvasd_tar() {
    local cn_openvasd="${1:-$CN_OPENVASD}"
    local cert_dir_product="${2:-$CERT_DIR_PRODUCT}"
    local openvasd_tar_with_images="${3:-$OPENVASD_TAR_WITH_IMAGES}"
    local feed_mode="${4:-$FEED_MODE}"
    local store_dir_name="${5:-$STORE_DIR_NAME}"
    local cert_dir_name="${6:-$CERT_DIR_NAME}"
    local cert_dir_oci="${7:-$CERT_DIR_OCI}"
    local artifact_dir="${8:-$ARTIFACT_DIR}"
    local artifact_dir_name="${9:-$ARTIFACT_DIR_NAME}"
    local image_dir_name="${10:-$IMAGE_DIR_NAME}"
    local settings_dir_name="${11:-$SETTINGS_DIR_NAME}"
    local product="${12:-$PRODUCT}"
    local settings_dir="${13:-$SETTINGS_DIR}"

    if ! [ "${cn_openvasd}" ]; then
        echo "Error: --cn-openvasd argument missing. Required for --create-openvasd-certs !"
        exit 1
    fi

    get_latest_version

    local openvasd_name="${cn_openvasd//./-}"
    local openvasd_cert_folder="${cn_openvasd//./_}"
    openvasd_cert_folder="${cert_dir_product}/${openvasd_cert_folder}"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    chmod 0700 "${tmp_dir}"

    local tmp_images="${tmp_dir}/${store_dir_name}/${image_dir_name}/${product}"

    pushd "${tmp_dir}" > /dev/null || exit
        mkdir -p "${store_dir_name}/${settings_dir_name}/${product}"
        mkdir -p "${store_dir_name}/${cert_dir_name}/${product}"
        mkdir -p "${store_dir_name}/${artifact_dir_name}/${product}"

        cp -r "${cert_dir_oci}" "${store_dir_name}/${cert_dir_name}/"
        cp -r "${artifact_dir}/${VERSION}" "${store_dir_name}/${artifact_dir_name}/${product}/"
        cp -r "${openvasd_cert_folder}" "${store_dir_name}/${cert_dir_name}/${product}/"
        cp "${cert_dir_product}/feed.key" "${store_dir_name}/${cert_dir_name}/${product}/"
        cp -r "${settings_dir}" "${store_dir_name}/${settings_dir_name}/${product}/"

        init_setting "PRODUCT" "enterprise-container" \
            "${store_dir_name}" "y"
        init_setting "DEPLOYMENT_MODE" "openvasd" \
            "${store_dir_name}/${settings_dir_name}/${product}" "y"
    popd > /dev/null

    cp "${0}" "${tmp_dir}"

    if [ "${openvasd_tar_with_images}" == 'y' ]; then
        load_secrets
        load_certs
        mkdir -p "${tmp_images}"
        pushd "${artifact_dir}/${VERSION}" > /dev/null || exit
            docker save -o "${tmp_images}/openvas-openvasd.tar" \
                "$(docker compose images | awk '$2 ~ /openvas-scanner$/ { print $5; exit }')"

            docker save -o "${tmp_images}/openvas-gpg-data.tar" \
                "$(docker compose images | awk '$2 ~ /gpg-data$/ { print $5; exit }')"

            docker save -o "${tmp_images}/openvas-feed-sync.tar" \
                "$(docker compose images | awk '$2 ~ /greenbone-feed-sync$/ { print $5; exit }')"

            docker save -o "${tmp_images}/openvas-redis.tar" \
                "$(docker compose images | awk '$2 ~ /redis-server$/ { print $5; exit }')"

            if [ "${feed_mode}" == 'service' ]; then
                docker save -o "${tmp_images}/openvas-feed-key-service.tar" \
                    "$(docker compose images | awk '$2 ~ /feed-key-service$/ { print $5; exit }')"
            fi

        popd > /dev/null
    fi

    rm -f "${openvasd_name}.tar.gz"
    (umask 077; tar -czf "${openvasd_name}.tar.gz" -C "${tmp_dir}" .)

    rm -rf "${tmp_dir}"
}

# =============================================================================
# del_openvasd()
# =============================================================================
# Deletes an OpenVASD scanner from gvmd.
#
# The function verifies that an OpenVASD scanner UUID is provided and then
# executes gvmd inside the configured gvmd container to remove the scanner
# identified by that UUID.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if OPENVASD_UUID is not set.
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
# Lists the OpenVASD scanners configured in gvmd.
#
# The function executes gvmd inside the configured gvmd container using the
# configured container user and prints the registered scanner entries.
#
# Arguments:
#   None.
#
# Returns:
#   Writes the configured scanner list to standard output.
get_openvasds() {
    docker exec -u "${GVMD_CONTAINER_UID}" "${GVMD_CONTAINER}" gvmd --get-scanners
}

# =============================================================================
# init_openvasd_tar()
# =============================================================================
# Initializes Docker OCI certificate configuration for an OpenVASD deployment
# created from an archive.
#
# The function delegates OCI client certificate installation for Docker to
# init_docker_oci.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_openvasd_tar() {
    init_docker_oci
}

# =============================================================================
# load_openvasd_images()
# =============================================================================
# Loads the Docker images required for an OpenVASD deployment from local image
# archives.
#
# The function checks for each expected Docker image archive and loads available
# images using docker load. Missing image archives are skipped and reported as
# informational messages.
#
# The feed key service image is loaded only when the feed mode is set to
# 'service'.
#
# Arguments:
#   1. image_dir:
#      Directory containing the Docker image archives.
#      Defaults to IMAGE_DIR.
#
#   2. feed_mode:
#      Feed synchronization mode. If set to 'service', the feed key service
#      image archive is also loaded.
#      Defaults to FEED_MODE.
#
# Expected files:
#   ${image_dir}/openvas-openvasd.tar
#   ${image_dir}/openvas-gpg-data.tar
#   ${image_dir}/openvas-feed-sync.tar
#   ${image_dir}/openvas-redis.tar
#   ${image_dir}/openvas-feed-key-service.tar
#       Loaded only when feed_mode is set to 'service'.
#
# Returns:
#   None.
#
# Exits:
#   Does not exit when image archives are missing. Missing files are skipped
#   with an informational message.
load_openvasd_images() {
    local image_dir="${1:-$IMAGE_DIR}"
    local feed_mode="${2:-$FEED_MODE}"

    if [ -f "${image_dir}/openvas-openvasd.tar" ]; then
        docker load -i "${image_dir}/openvas-openvasd.tar"
    else
        echo "Info: Image ${image_dir}/openvas-openvasd.tar not found. Skip!"
    fi

    if [ -f "${image_dir}/openvas-gpg-data.tar" ]; then
        docker load -i "${image_dir}/openvas-gpg-data.tar"
    else
        echo "Info: Image ${image_dir}/openvas-gpg-data.tar not found. Skip!"
    fi

    if [ -f "${image_dir}/openvas-feed-sync.tar" ]; then
        docker load -i "${image_dir}/openvas-feed-sync.tar"
    else
        echo "Info: Image ${image_dir}/openvas-feed-sync.tar not found. Skip!"
    fi

    if [ -f "${image_dir}/openvas-redis.tar" ]; then
        docker load -i "${image_dir}/openvas-redis.tar"
    else
        echo "Info: Image ${image_dir}/openvas-redis.tar not found. Skip!"
    fi

    if [ "${feed_mode}" == 'service' ]; then
        if [ -f "${image_dir}/openvas-feed-key-service.tar" ]; then
            docker load -i "${image_dir}/openvas-feed-key-service.tar"
        else
            echo "Info: Image ${image_dir}/openvas-feed-key-service.tar not found. Skip!"
        fi
    fi
}
