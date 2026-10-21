# =============================================================================
#  OpenVAS Deployment Script Tests
# =============================================================================
#  Test the scan deployment mode of the enterprise-container stack.
# =============================================================================

set -euo pipefail

source regress/share.sh

check_req() {
    if ! [ -f 'oci-client.cert' ]; then
        echo_error "No oci-client.cert found"
        exit 1
    elif ! [ -f 'oci-client.key' ]; then
        echo_error "No oci-client.key found"
        exit 1
    elif ! [ -f 'osi-license.toml' ]; then
        echo_error "No osi-license.toml found"
        exit 1
    fi
}

change_bridge_vi_proxy() {
    echo_task 'Test change bridge backends'
    openvas-deployment --change-bridge-vi-proxy-subnet-ipv4 --bridge-vi-proxy-subnet-ipv4 '100.104.79.128/26'
    openvas-deployment --change-bridge-vi-proxy-subnet-ipv6 --bridge-vi-proxy-subnet-ipv6 'fd7a:9438:4e82:3::/64'
}

init() {
    echo_task 'Test Init'
    openvas-deployment --init --init-docker-oci \
        --oci-client-cert oci-client.cert \
        --oci-client-key oci-client.key \
        --product security-intelligence \
        --domain-name test.test.test
    echo_task 'Test Update'
    openvas-deployment --update
}

init_license() {
    echo_task 'Test Init license file'
    openvas-deployment --init --init-docker-oci \
        --license-file osi-license.toml \
        --product security-intelligence \
        --domain-name test.test.test
    echo_task 'Test Update'
    openvas-deployment --update
}

run() {
    echo_task 'Test Run'
    openvas-deployment --run
}

check_req
init
change_bridge_backends
change_bridge_ingress
change_bridge_vi_proxy
list_versions
list_local_versions
list 'security-intelligence'
clean 'security-intelligence'
init_license
certinfo 'product/certs/oci/client.key' 'product/certs/oci/client.crt'
run
gen_certs_ingress
update_ingress_certs
list 'security-intelligence'
clean 'security-intelligence'
