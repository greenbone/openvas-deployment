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
    elif ! [ -f 'oci-client.cert' ]; then
        echo "No oci-client.cert found"
        exit 1
    elif ! [ -f 'oci-client.key' ]; then
        echo "No oci-client.key found"
        exit 1
    fi
}

clean() {
    rm -rf product
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
}

run_openvasd_cert_tar() {
    echo 'Test Openvasd Cert Gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor.test.test
    echo 'Test Openvasd Cert Tar'
    openvas-deployment --create-openvasd-cert-tar --cn-openvasd sensor.test.test
    if ! [ -f 'sensor_test_test.tar' ]; then
        echo 'Openvasd cert tar gen failed!'
    fi
}

check_req
run
run_openvasd_cert_tar
clean
