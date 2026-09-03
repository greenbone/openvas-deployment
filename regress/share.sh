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
