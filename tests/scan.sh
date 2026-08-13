# =============================================================================
#  OpenVAS Deployment Script Tests
# =============================================================================
#  Test the scan deployment mode of the enterprise-container stack.
# =============================================================================

set -euo pipefail

check_req() {
    if ! [ -f 'gsf.key' ]; then
        echo "No gsf.key found"
        exit 1
    elif [ -f 'oci-client.cert' ]; then
        echo "No oci-client.cert found"
        exit 1
    elif [ -f 'oci-client.key' ]; then
        echo "No oci-client.key found"
        exit 1
    fi
}

run() {
    echo 'Test Init'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key --oci-client-cert oci-client.cert --oci-client-key oci-client.key
    echo 'Test Update'
    openvas-deployment --update
    echo 'Test Run'
    openvas-deployment --run
    echo 'Test down volumes'
    openvas-deployment --down-volumes
    echo 'List product folder'
    tree product
    rm -rf product
}

check_req
run
