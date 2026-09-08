# =============================================================================
#  OpenVAS Deployment Script Tests
# =============================================================================
#  Test the scan deployment mode of the enterprise-container stack.
# =============================================================================

set -euo pipefail

source regress/share.sh

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

gvmd_add_openvasd_host_to_etc_hosts() {
    local domain="${1:?Missing domain argument}"
    local ip="${2:?Missing IP argument}"

    docker exec -u 0 enterprise-container-scan-gvmd-1 sh -c "chmod 0666 /etc/hosts && echo \"$ip $domain\" >> /etc/hosts"
    if [ "$MHOSTS" ]; then
        sudo chmod 0666 /etc/hosts
        echo "$ip $domain" >> /etc/hosts
    fi
}

run() {
    echo_task 'Test Init'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key \
        --oci-client-cert oci-client.cert --oci-client-key oci-client.key \
        --product enterprise-container --deployment-mode scan
    echo_task 'Test Update'
    openvas-deployment --update
    echo_task 'Test Run'
    openvas-deployment --run
}

change_admin_pw() {
    echo_task 'Test change admin pasword'
    openvas-deployment --change-admin-password --admin-password 'admin'
}

change_feed_sync_hour() {
    echo_task 'Test change feed sync hour'
    openvas-deployment --change-feed-sync-hour --feed-sync-hour 4 --feed-sync-force-no-log
}

change_force_feed_sync() {
    echo_task 'Test force feed sync'
    openvas-deployment --force-feed-sync --feed-sync-force-no-log
}

run_openvasd_cert_tar() {
    echo_task 'Test Openvasd cert tar gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor1.test.test
    echo_task 'Test Openvasd cert tar'
    openvas-deployment --create-openvasd-cert-tar --cn-openvasd sensor1.test.test
    if ! [ -f 'sensor1-test-test.tar' ]; then
        echo_error 'Error openvasd cert tar gen failed!'
        exit 1
    fi
    mkdir sensor1_test_test
    pushd sensor1_test_test > /dev/null || exit
        echo_task 'Test openvasd cert tar extract'
        tar xvf ../sensor1-test-test.tar
        echo_task 'Test Openvasd cert tar init'
        openvas-deployment --init --init-docker-oci \
            --product enterprise-container --deployment-mode openvasd \
            --cn-openvasd sensor1.test.test \
            --oci-client-cert ../oci-client.cert \
            --oci-client-key ../oci-client.key \
            --feed-key ../gsf.key \
            --openvasd-server-cert server.crt \
            --openvasd-server-key server.key \
            --openvasd-client-ca ca.crt
        echo_task 'Test openvasd cert tar update'
        openvas-deployment --update
        echo_task 'Test openvasd cert tar run'
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.128/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:3::/64'
        openvas-deployment --run --openvasd-port '1337'
        if ! ss -ltn | grep -q ':1337 '; then
            echo_error 'Error openvasd sensor setup port test failed!'
            exit 1
        fi
    popd > /dev/null
    echo_task 'Test add openvasd to gvmd'
    gvmd_add_openvasd_host_to_etc_hosts 'sensor1.test.test' '100.104.0.129'
    openvas-deployment --add-openvasd --cn-openvasd sensor1.test.test --openvasd-port 1337
    echo_task 'Cleanup Openvasd cert tar'
    pushd sensor1_test_test > /dev/null || exit
        list 'Openvasd cert tar'
        clean 'Openvasd cert tar'
    popd > /dev/null
}

run_openvasd_tar() {
    echo_task 'Test openvasd gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor2.test.test
    echo_task 'Test openvasd tar'
    openvas-deployment --create-openvasd-tar --cn-openvasd sensor2.test.test
    ls
    if ! [ -f 'sensor2-test-test.tar.gz' ]; then
        echo_error 'Error openvasd tar gen failed!'
        exit 1
    fi
    mkdir sensor2_test_test
    pushd sensor2_test_test > /dev/null || exit
        echo_task 'Test openvasd extract'
        tar xzvf ../sensor2-test-test.tar.gz
        echo_task 'Test openvasd run'
        export BRIDGE_BACKENDS_SUBNET_IPV4='100.104.0.192/26'
        export BRIDGE_BACKENDS_SUBNET_IPV6='fd7a:91c3:4e82:4::/64'
        openvas-deployment --run --openvasd-port '2337'
        if ! ss -ltn | grep -q ':2337 '; then
            echo_error 'Error openvasd sensor setup port test failed!'
            exit 1
        fi
    popd > /dev/null
    echo_task 'Test add openvasd to gvmd'
    gvmd_add_openvasd_host_to_etc_hosts 'sensor2.test.test' '100.104.0.193'
    openvas-deployment --add-openvasd --cn-openvasd sensor2.test.test --openvasd-port 2337
    echo_task 'Cleanup Openvasd tar'
    pushd sensor2_test_test > /dev/null || exit
        list 'Openvasd tar'
        clean 'Openvasd tar'
    popd > /dev/null
}

check_req
run
change_admin_pw
change_feed_sync_hour
change_force_feed_sync
gen_certs_ingress
update_ingress_certs
run_openvasd_cert_tar
run_openvasd_tar
list 'Openvasd scan'
clean 'Openvasd scan'
