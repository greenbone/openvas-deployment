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
    fi
}

run() {
    echo_task 'Test Init'
    openvas-deployment --init --oci-client-cert oci-client.cert \
        --oci-client-key oci-client.key \
        --product security-intelligence \
        --domain-name test.test.test
    echo_task 'Test Update'
    openvas-deployment --update
    echo_task 'Test Run'
    openvas-deployment --run
}

check_req
run
list 'security-intelligence'
clean 'security-intelligence'
