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
list 'security-intelligence'
clean 'security-intelligence'
init_license
run
gen_certs_ingress
update_ingress_certs
list 'security-intelligence'
clean 'security-intelligence'
