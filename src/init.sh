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
    echo "🚀 Init OpenVAS ${PRODUCT}..."
    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        echo "Info: Using mode ${DEPLOYMENT_MODE}."
    fi

    if [ -d "${WORKING_DIR}" ]; then
        if [ "${SKIP_INIT_IF_EXIST}" == "y" ]; then
            exit 0
        fi
        echo "Warning: ${WORKING_DIR} exist! CA setup will be overwritten if continue!"
        read -r -p "Continue? (y/n)" response
        if [ "$response" != "y" ]; then
            exit 1
        fi
    fi

    init_base_folders
    if [ "${LICENSE_FILE}" ]; then
        read_license_file
        init_license_file
    else
        init_oci_certs
    fi
    init_certs
    init_settings
    init_secrets
    init_docker_oci
    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        init_jwt
        init_feed_key
        init_admin_password_scan
    fi

    echo "Init done!"
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
    mkdir -p "${CERT_DIR_PRODUCT}"
    mkdir -p "${ARTIFACT_DIR}"
    mkdir -p "${IMAGE_DIR}"
    mkdir -p "${SECRETS_DIR}"
    mkdir -p "${SETTINGS_DIR}"
}
