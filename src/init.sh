# =============================================================================
# init()
# =============================================================================
# Initializes the working environment for the selected OpenVAS product.
#
# The function verifies whether WORKING_DIR already exists and optionally skips
# initialization or asks for confirmation before overwriting existing setup
# data. It then creates the required base directories and initializes product
# credentials, certificates, settings, secrets, and Docker OCI configuration.
#
# If LICENSE_FILE is provided, license-based initialization is used; otherwise,
# OCI client certificates are initialized.
#
# For enterprise-container, the function additionally initializes JWT keys,
# feed key configuration, and the scan administrator password.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   0 if WORKING_DIR exists and SKIP_INIT_IF_EXIST is set to 'y'.
#   1 if WORKING_DIR exists and the user declines to continue.
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
# Creates the base directory structure required for product initialization.
#
# The function ensures that the common certificate directory, OCI certificate
# directory, product-specific certificate directory, artifact directory, image
# directory, secrets directory, and settings directory exist.
#
# Existing directories are left unchanged.
#
# Arguments:
#   None.
#
# Returns:
#   None.
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
