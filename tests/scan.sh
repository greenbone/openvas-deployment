# =============================================================================
#  OpenVAS Deployment Script Tests
# =============================================================================
#  Test the scan deployment mode of the enterprise-container stack.
# =============================================================================

set -euo pipefail

echo_task() {
    printf '\n\033[1;34m────────────────────────────────────────\033[0m\n'
    printf '\033[1;34m%s\033[0m\n' "$*"
    printf '\033[1;34m────────────────────────────────────────\033[0m\n\n'
}

echo_error() {
    printf '\033[1;31m%s\033[0m\n' "$*"
}

check_req() {
    if ! [ -f 'gsf.key' ]; then
        echo_error "No gsf.key found"
        exit 1
    elif ! [ -f 'oci-client.cert' ]; then
        echo_error "No oci-client.cert found"
        exit 1
    elif ! [ -f 'oci-client.key' ]; then
        echo_error "No oci-client.key found"
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
}

gvmd_add_openvasd_host_to_etc_hosts() {
    local domain="${1:?Missing domain argument}"
    local ip="${2:?Missing IP argument}"

    docker exec -u 0 enterprise-container-scan-gvmd-1 sh -c "chmod 0666 /etc/hosts && echo \"$ip $domain\" >> /etc/hosts"
    #sudo chmod 0666 /etc/hosts
    #echo "$ip $domain" >> /etc/hosts
}

run() {
    echo_task 'Test Init'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key --oci-client-cert oci-client.cert --oci-client-key oci-client.key
    echo_task 'Test Update'
    openvas-deployment --update
    echo_task 'Test Run'
    openvas-deployment --run
}

run_openvasd_cert_tar() {
    echo_task 'Test Openvasd cert tar gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor1.test.test
    echo_task 'Test Openvasd cert tar'
    openvas-deployment --create-openvasd-cert-tar --cn-openvasd sensor1.test.test
    if ! [ -f 'sensor1-test-test.tar' ]; then
        echo_error 'Openvasd cert tar gen failed!'
        exit 1
    fi
    mkdir sensor1_test_test
    pushd sensor1_test_test > /dev/null || exit
        echo_task 'Test openvasd cert tar extract'
        tar xvf ../sensor1-test-test.tar
        echo_task 'Test Openvasd cert tar init'
        openvas-deployment --init --init-docker-oci --deployment-mode openvasd \
            --cn-openvasd sensor1.test.test \
            --oci-client-cert ../oci-client.cert \
            --oci-client-key ../oci-client.key \
            --feed-key ../gsf.key \
            --openvasd-server-cert server.crt \
            --openvasd-server-key server.key \
            --openvasd-client-ca ca.crt
        echo_task 'Test Openvasd Cert update'
        openvas-deployment --update
        echo_task 'Test Openvasd Cert run'
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.128/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:3::/64'
        openvas-deployment --run --openvasd-port '1337'
        if ! ss -ltn | grep -q ':1337 '; then
            echo_error 'Openvasd sensor setup port test failed!'
            exit 1
        fi
    popd > /dev/null
    echo_task 'Test add openvasd to gvmd'
    gvmd_add_openvasd_host_to_etc_hosts 'sensor1.test.test' '100.104.0.128'
    pushd sensor1_test_test > /dev/null || exit
        clean
        list
    popd > /dev/null
    rm -rf sensor1_test_test
    rm -f sensor1_test_test.tar
}

run_openvasd_tar() {
    echo_task 'Test Openvasd Gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor2.test.test
    echo_task 'Test Openvasd Tar'
    openvas-deployment --create-openvasd-tar --cn-openvasd sensor2.test.test
    ls
    if ! [ -f 'sensor2-test-test.tar.gz' ]; then
        echo_error 'Openvasd tar gen failed!'
        exit 1
    fi
    mkdir sensor2_test_test
    pushd sensor2_test_test > /dev/null || exit
        echo_task 'Test Openvasd extract'
        tar xzvf ../sensor2-test-test.tar.gz
        echo_task 'Test Openvasd run'
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.192/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:4::/64'
        openvas-deployment --run --openvasd-port '2337'
        if ! ss -ltn | grep -q ':2337 '; then
            echo_error 'Openvasd sensor setup port test failed!'
            exit 1
        fi

    popd > /dev/null
    echo_task 'Test add openvasd to gvmd'
    gvmd_add_openvasd_host_to_etc_hosts 'sensor2.test.test' '100.104.0.192'
    pushd sensor2_test_test > /dev/null || exit
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
