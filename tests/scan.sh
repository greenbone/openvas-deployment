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
    echo 'Show docker container'
    docker ps
    echo 'Test down volumes'
    openvas-deployment --down-volumes
}

list() {
    echo 'List product folder'
    tree product
    rm -rf product
}

run() {
    echo 'Test Init'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key --oci-client-cert oci-client.cert --oci-client-key oci-client.key
    echo 'Test Update'
    openvas-deployment --update
    echo 'Test Run'
    openvas-deployment --run
}

run_openvasd_cert_tar() {
    echo 'Test Openvasd Cert Gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor1.test.test
    echo 'Test Openvasd Cert Tar'
    openvas-deployment --create-openvasd-cert-tar --cn-openvasd sensor1.test.test
    if ! [ -f 'sensor1_test_test.tar' ]; then
        echo 'Openvasd cert tar gen failed!'
        exit 1
    fi
    mkdir sensor1_test_test
    pushd sensor1_test_test > /dev/null || exit
        echo 'Test Openvasd Cert extract'
        tar xvf ../sensor1_test_test.tar
        echo 'Test Openvasd Cert init'
        openvas-deployment --init --init-docker-oci --deployment-mode openvasd \
            --cn-openvasd sensor1.test.test \
            --oci-client-cert ../oci-client.cert \
            --oci-client-key ../oci-client.key \
            --feed-key ../gsf.key \
            --openvasd-server-cert server.crt \
            --openvasd-server-key server.key \
            --openvasd-client-ca ca.crt
        echo 'Test Openvasd Cert update'
        openvas-deployment --update
        echo 'Test Openvasd Cert run'
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.128/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:3::/64'
        openvas-deployment --run --openvasd-port '1337'
        if ! ss -ltn | grep -q ':1337 '; then
            echo 'Openvasd sensor setup port test failed!'
            exit 1
        fi
        clean
        list
    popd > /dev/null
    rm -rf sensor1_test_test
    rm -f sensor1_test_test.tar
}

run_openvasd_tar() {
    echo 'Test Openvasd Gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor2.test.test
    echo 'Test Openvasd Tar'
    openvas-deployment --create-openvasd-tar --cn-openvasd sensor2.test.test
    if ! [ -f 'sensor2_test_test.tar' ]; then
        echo 'Openvasd cert tar gen failed!'
        exit 1
    fi
    mkdir sensor2_test_test
    pushd sensor2_test_test > /dev/null || exit
        echo 'Test Openvasd Cert extract'
        tar xvf ../sensor2_test_test.tar
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.192/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:4::/64'
        openvas-deployment --run --openvasd-port '2337'
        if ! ss -ltn | grep -q ':2337 '; then
            echo 'Openvasd sensor setup port test failed!'
            exit 1
        fi
        clean
        list
    popd > /dev/null
    rm -rf sensor2_test_test
    rm -f sensor2_test_test.tar
}

check_req
run
run_openvasd_cert_tar
run_openvasd_tar
clean
list
