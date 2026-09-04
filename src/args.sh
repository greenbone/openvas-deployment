# =============================================================================
# parse_args()
# =============================================================================
# Parses the command-line arguments and initializes the corresponding global
# variables that control the script's behavior.
#
# If no arguments are provided, or if --help is specified, the help message is
# displayed via show_help().
#
# Globals modified:
#   MODE
#   DEPLOYMENT_MODE
#   OPENVASD_CLIENT_CA
#   OPENVASD_SERVER_CERT
#   OPENVASD_SERVER_KEY
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
#   SERVICE_NAME
#   DEV_STAGE_URL_PREFIX
#   SKIP_INIT_IF_EXIST
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
            --product)
                PRODUCT="$2"
                shift 2
                ;;
            --domain-name)
                DOMAIN_NAME="$2"
                shift 2
                ;;
            --init-openvasd-tar)
                MODE='init-openvasd-tar'
                shift 1
                ;;
            --metafeed-cert)
                METAFEED_CERT="$2"
                shift 2
                ;;
            --metafeed-key)
                METAFEED_KEY="$2"
                shift 2
                ;;
            --deployment-mode)
                DEPLOYMENT_MODE="$2"
                shift 2
                ;;
            --openvasd-client-ca)
                OPENVASD_CLIENT_CA="$2"
                shift 2
                ;;
            --openvasd-server-cert)
                OPENVASD_SERVER_CERT="$2"
                shift 2
                ;;
            --openvasd-server-key)
                OPENVASD_SERVER_KEY="$2"
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
            --feed-sync-force-no-log)
                FEED_SYNC_FORCE_NO_LOG='y'
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
            --create-openvasd-cert-tar)
                MODE='create-openvasd-cert-tar'
                shift 1
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
            --dev)
                DEV_STAGE_URL_PREFIX='-dev/dev'
                shift 1
                ;;
            --integration)
                DEV_STAGE_URL_PREFIX='-dev/integration'
                shift 1
                ;;
            --testing)
                DEV_STAGE_URL_PREFIX='-dev/testing'
                shift 1
                ;;
            --staging)
                DEV_STAGE_URL_PREFIX='-dev/staging'
                shift 1
                ;;
            --skip-init-if-exist)
                SKIP_INIT_IF_EXIST='y'
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
# run()
# =============================================================================
# The run function orchestrates the execution of the script.
run() {
    check_requirements

    update_globals

    if [ "${MODE}" == 'init' ]; then
        init
    fi
    if [ "${MODE}" == 'init-openvasd-tar' ]; then
        init_openvasd_tar
    fi
    if [ "${MODE}" == 'create-openvasd-tar' ]; then
        create_openvasd_tar
    fi
    if [ "${MODE}" == 'create-openvasd-cert-tar' ]; then
        create_openvasd_cert_tar
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
        change_admin_password_scan
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

update_globals() {
    if ! [ "${PRODUCT}" ]; then
        if [ -f "${WORKING_DIR}/PRODUCT" ]; then
            export PRODUCT="$(< "${WORKING_DIR}/PRODUCT")"
        else
            echo "Error: No product found at ${WORKING_DIR}/PRODUCT! Please run --init with --product and one of ${PRODUCT_OPTIONS[*]} !"
            exit 1
        fi
    fi
    PRODUCT_URL="packages.greenbone.net/openvas-${PRODUCT}${DEV_STAGE_URL_PREFIX}/${PRODUCT}"
    CERT_DIR_PRODUCT="${CERT_DIR}/${PRODUCT}"
    ARTIFACT_DIR="${WORKING_DIR}/${ARTIFACT_DIR_NAME}/${PRODUCT}"
    IMAGE_DIR="${WORKING_DIR}/${IMAGE_DIR_NAME}/${PRODUCT}"
    SECRETS_DIR="${WORKING_DIR}/${SECRETS_DIR_NAME}/${PRODUCT}"
    SETTINGS_DIR="${WORKING_DIR}/${SETTINGS_DIR_NAME}/${PRODUCT}"
}
