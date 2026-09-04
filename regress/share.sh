echo_task() {
    printf '\n\033[1;34m────────────────────────────────────────\033[0m\n'
    printf '\033[1;34m%s\033[0m\n' "$*"
    printf '\033[1;34m────────────────────────────────────────\033[0m\n\n'
}

echo_error() {
    printf '\033[1;31m%s\033[0m\n' "$*"
}

clean() {
    echo_task 'Test down volumes'
    openvas-deployment --down-volumes
}

list() {
    echo_task "Show docker container for $1"
    openvas-deployment --ps
    echo_task "Show docker logs for $1"
    openvas-deployment --logs >/dev/null 2>&1
    echo_task "List product folder for $1"
    tree product
}

update_ingress_certs() {
    echo_task 'Test update ingress certs'
    openvas-deployment --update-ingress-certs --update-ingress-cert-redeploy \
        --ingress-server-cert ./test_ingress_server.crt \
        --ingress-server-key ./test_ingress_server.key
}

gen_certs_ingress() {
    openssl genrsa -out "test_ingress_server.key" 2048
    openssl req -new -x509 -key "test_ingress_server.key" -out "test_ingress_server.crt" -days 365 \
       -addext "basicConstraints=CA:FALSE" -addext "extendedKeyUsage=serverAuth" -addext "keyUsage=digitalSignature,keyEncipherment" \
       -subj "/CN=openvas-enterprise-container"
}
