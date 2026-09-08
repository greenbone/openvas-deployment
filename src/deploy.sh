# =============================================================================
# deploy()
# =============================================================================
# Deploys the selected OpenVAS product using the latest downloaded artifacts.
#
# The function loads deployment settings, determines the latest available local
# product version, and loads the required secrets and certificate data.
#
# For enterprise-container deployments, it also loads the feed key and may
# import OpenVASD container images from a tar archive when running in openvasd
# mode with OPENVASD_LOAD_IMAGES_FROM_TAR enabled.
#
# The function then changes to the selected artifact directory, stops any
# existing compose stack, and starts the deployment with Docker Compose. It
# waits for the services to become ready and reports whether deployment
# completed successfully.
#
# Arguments:
#   None.
#
# Returns:
#   None.
#
# Exits:
#   1 if changing to the artifact directory fails.
#   1 if the Docker Compose deployment fails.
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
