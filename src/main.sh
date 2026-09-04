#!/usr/bin/env bash

# =============================================================================
#  OpenVAS Deployment Script
# =============================================================================
#  This script is for demo purposes until our deployment tool
#  supports this product!
# =============================================================================

set -euo pipefail

# Global Static
DOCKER_CERTS='/etc/docker/certs.d/packages.greenbone.net'
STORE_DIR_NAME='product'
CERT_DIR_NAME='certs'
CERT_DIR_OCI_NAME='oci'
ARTIFACT_DIR_NAME='artifacts'
IMAGE_DIR_NAME='images'
SECRETS_DIR_NAME='secrets'
SETTINGS_DIR_NAME='settings'
PRODUCT_OPTIONS=('enterprise-container' 'security-intelligence')
DEPLOYMENT_MODE_OPTIONS=('scan' 'openvasd')
FEED_MODE_OPTIONS=('volume' 'service' 'mount')
CCERT_MODE_OPTIONS=('ca' 'cert' 'mount')
GVMD_CONTAINER='enterprise-container-scan-gvmd-1'
GVMD_CONTAINER_UID='1001'

# Global
PRODUCT=''
DEV_STAGE_URL_PREFIX=''
PRODUCT_URL="packages.greenbone.net/openvas-${PRODUCT}${DEV_STAGE_URL_PREFIX}/${PRODUCT}"

# Working dir's
WORKING_DIR="$(pwd)/${STORE_DIR_NAME}"
CERT_DIR="${WORKING_DIR}/${CERT_DIR_NAME}"
CERT_DIR_OCI="${CERT_DIR}/${CERT_DIR_OCI_NAME}"
CERT_DIR_PRODUCT="${CERT_DIR}/${PRODUCT}"
ARTIFACT_DIR="${WORKING_DIR}/${ARTIFACT_DIR_NAME}/${PRODUCT}"
IMAGE_DIR="${WORKING_DIR}/${IMAGE_DIR_NAME}/${PRODUCT}"
SECRETS_DIR="${WORKING_DIR}/${SECRETS_DIR_NAME}/${PRODUCT}"
SETTINGS_DIR="${WORKING_DIR}/${SETTINGS_DIR_NAME}/${PRODUCT}"

# Runtime
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
SKIP_INIT_IF_EXIST=''
DEPLOYMENT_MODE='scan'
OPENVASD_TAR_WITH_IMAGES='n'
OPENVASD_LOAD_IMAGES_FROM_TAR='n'
OPENVASD_CLIENT_CA=''
OPENVASD_SERVER_CERT=''
OPENVASD_SERVER_KEY=''
GVMD_ADMIN_PASSWORD=''
GREENBONE_FEED_SYNC_JOB_HOUR='3'
declare -A LICENSE_DATA
LICENSE_FILE=''
SERVICE_NAME=''
FEED_SYNC_FORCE_NO_LOG='n'
METAFEED_CERT=''
METAFEED_KEY=''
DOMAIN_NAME=''

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
