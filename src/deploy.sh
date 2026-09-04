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
    load_settings
    get_latest_version

    echo "🚀 Starting OpenVAS ${PRODUCT} ..."
    echo "Info: Using version ${VERSION}."
    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        echo "Info: Using mode ${DEPLOYMENT_MODE}."
    fi

    load_secrets
    load_certs

    if [ "${PRODUCT}" == 'enterprise-container' ]; then
        load_feed_key
        if [ "${DEPLOYMENT_MODE}" == 'openvasd' ]; then
            if [ "${OPENVASD_LOAD_IMAGES_FROM_TAR}" == 'y' ]; then
                load_openvasd_images
            fi
        fi
    fi

    # Run deployment
    pushd "${ARTIFACT_DIR}/${VERSION}" > /dev/null || exit
        docker compose --env-file settings.env down --remove-orphans 2>/dev/null || true
        if docker compose --env-file settings.env up -d --wait --wait-timeout 7200 --quiet-pull --remove-orphans ; then
            echo "OpenVAS ${PRODUCT} deployment successful!"
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
