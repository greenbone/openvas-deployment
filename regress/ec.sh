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
    elif ! [ -f 'oec-license.toml' ]; then
        echo_error "No oec-license.toml found"
        exit 1
    fi
}

gvmd_add_openvasd_host_to_etc_hosts() {
    local domain="${1:?Missing domain argument}"
    local ip="${2:?Missing IP argument}"

    docker exec -u 0 enterprise-container-scan-gvmd-1 sh -c "chmod 0666 /etc/hosts && echo \"$ip $domain\" >> /etc/hosts"
    if [ "${MHOSTS:-}" ]; then
        sudo chmod 0666 /etc/hosts
        echo "$ip $domain" >> /etc/hosts
    fi
}

init() {
    echo_task 'Test Init'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key \
        --oci-client-cert oci-client.cert --oci-client-key oci-client.key \
        --product enterprise-container --deployment-mode scan \
        --domain-name oec.test.test --domain-ip 127.0.0.1
    echo_task 'Test Update'
    openvas-deployment --update
}

init_version() {
    echo_task 'Test Init version 0.10.1'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key \
        --oci-client-cert oci-client.cert --oci-client-key oci-client.key \
        --product enterprise-container --deployment-mode scan \
        --domain-name oec.test.test --domain-ip 127.0.0.1
    echo_task 'Test Update version 0.10.1'
    openvas-deployment --update --version 0.10.1
}

init_license() {
    echo_task 'Test Init license file'
    openvas-deployment --init --init-docker-oci --feed-key gsf.key \
        --license-file oec-license.toml \
        --product enterprise-container --deployment-mode scan \
        --domain-name oec.test.test --domain-ip 127.0.0.1
    echo_task 'Test Update'
    openvas-deployment --update
}

run() {
    echo_task 'Test Run'
    openvas-deployment --run
}

run_version() {
    echo_task 'Test Run version 0.10.1'
    openvas-deployment --run --version 0.10.1
}

change_admin_pw() {
    echo_task 'Test change admin pasword'
    openvas-deployment --change-admin-password --admin-password 'admin'
}

change_gmp_sshd_enable() {
    echo_task 'Test change GMP SSHD enable'
    openvas-deployment --change-gmp-sshd-enable --gmp-sshd-enable true
}

change_openvas_gmp_sshd_listen_addr() {
    echo_task 'Test change OpenVAS GMP SSHD listen address'
    openvas-deployment --change-openvas-gmp-sshd-listen-addr --openvas-gmp-sshd-listen-addr 0.0.0.0
}

change_openvas_gmp_sshd_listen_addr_ipv6() {
    echo_task 'Test change OpenVAS GMP SSHD listen IPv6 address'
    openvas-deployment --change-openvas-gmp-sshd-listen-addr-ipv6 --openvas-gmp-sshd-listen-addr-ipv6 '::'
}

change_openvas_gmp_sshd_listen_port() {
    echo_task 'Test change OpenVAS GMP SSHD listen port'
    openvas-deployment --change-openvas-gmp-sshd-listen-port --openvas-gmp-sshd-listen-port 2222
}

change_logging_backend() {
    echo_task 'Test change logging backend'
    openvas-deployment --change-logging-backend --logging-backend json
}

change_logging_backend_json_file_max_size() {
    echo_task 'Test change logging backend JSON file max size'
    openvas-deployment --change-logging-backend-json-file-max-size --logging-backend-json-file-max-size 25m
}

change_logging_backend_json_file_max_file() {
    echo_task 'Test change logging backend JSON file max file'
    openvas-deployment --change-logging-backend-json-file-max-file --logging-backend-json-file-max-file 5
}

change_feed_sync_hour() {
    echo_task 'Test change feed sync hour'
    openvas-deployment --change-feed-sync-hour --feed-sync-hour 4 --feed-sync-force-no-log
}

change_force_feed_sync() {
    echo_task 'Test force feed sync'
    openvas-deployment --force-feed-sync --feed-sync-force-no-log
}

update_ingress_certs_agent() {
    echo_task 'Test update ingress agent control certs'
    openvas-deployment --update-ingress-agent-control-certs --skip-update-ingress-cert-redeploy \
        --ingress-agent-control-cert ./test_ingress_server.crt \
        --ingress-agent-control-key ./test_ingress_server.key
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
        openvas-deployment --change-bridge-backends-subnet-ipv4 --bridge-backends-subnet-ipv4 '100.104.0.128/26'
        openvas-deployment --change-bridge-backends-subnet-ipv6 --bridge-backends-subnet-ipv6 'fd7a:91c3:4e82:3::/64'
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
        echo_task 'Test Openvasd tar init'
        openvas-deployment --init-openvasd-tar --init-docker-oci
        echo_task 'Test openvasd run'
        openvas-deployment --change-bridge-backends-subnet-ipv4 --bridge-backends-subnet-ipv4 '100.104.0.192/26'
        openvas-deployment --change-bridge-backends-subnet-ipv6 --bridge-backends-subnet-ipv6 'fd7a:91c3:4e82:4::/64'
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

run_openvasd_tar_with_images() {
    echo_task 'Test openvasd gen'
    openvas-deployment --create-openvasd-certs --cn-openvasd sensor3.test.test
    echo_task 'Test openvasd tar with images'
    openvas-deployment --create-openvasd-tar --openvasd-tar-with-images --cn-openvasd sensor3.test.test
    ls
    if ! [ -f 'sensor3-test-test.tar.gz' ]; then
        echo_error 'Error openvasd tar gen failed!'
        exit 1
    fi
    mkdir sensor3_test_test
    pushd sensor3_test_test > /dev/null || exit
        echo_task 'Test openvasd extract'
        tar xzvf ../sensor3-test-test.tar.gz
        echo_task 'Test Openvasd tar init'
        openvas-deployment --init-openvasd-tar --init-docker-oci
        echo_task 'Test openvasd run with load images from tar'
        openvas-deployment --change-bridge-backends-subnet-ipv4 --bridge-backends-subnet-ipv4 '100.104.1.192/26'
        openvas-deployment --change-bridge-backends-subnet-ipv6 --bridge-backends-subnet-ipv6 'fd7a:91c3:4e82:5::/64'
        openvas-deployment --run --openvasd-load-images-from-tar --openvasd-port '3337'
        if ! ss -ltn | grep -q ':3337 '; then
            echo_error 'Error openvasd sensor setup port test failed!'
            exit 1
        fi
    popd > /dev/null
    echo_task 'Test add openvasd to gvmd'
    gvmd_add_openvasd_host_to_etc_hosts 'sensor3.test.test' '100.104.1.193'
    openvas-deployment --add-openvasd --cn-openvasd sensor3.test.test --openvasd-port 3337
    echo_task 'Cleanup Openvasd tar'
    pushd sensor3_test_test > /dev/null || exit
        list 'Openvasd tar'
        clean 'Openvasd tar'
    popd > /dev/null
}

check_req
init_version
change_bridge_backends
change_bridge_ingress
change_ingress_listen_addr
change_ingress_listen_addr_ipv6
change_ingress_listen_port
if [ "${SKIP:-}" != 'run' ]; then
    run_version
fi
list_versions
list_local_versions
list 'Openvasd scan version 0.10.1'
clean 'Openvasd scan version 0.10.1'
init
list 'Openvasd scan'
clean 'Openvasd scan'
init_license
certinfo 'product/certs/oci/client.key' 'product/certs/oci/client.crt'
if [ "${SKIP:-}" != 'run' ]; then
    run
    change_admin_pw
    change_gmp_sshd_enable
    change_openvas_gmp_sshd_listen_addr
    change_openvas_gmp_sshd_listen_addr_ipv6
    change_openvas_gmp_sshd_listen_port
    change_logging_backend
    change_logging_backend_json_file_max_size
    change_logging_backend_json_file_max_file
    change_feed_sync_hour
    change_force_feed_sync
    gen_certs_ingress
    update_ingress_certs
    update_ingress_certs_agent
    change_domain_name
    change_domain_ip
    run_openvasd_cert_tar
    run_openvasd_tar
    run_openvasd_tar_with_images
fi
list 'Openvasd scan'
clean 'Openvasd scan'
