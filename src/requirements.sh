# =============================================================================
# check_requirements()
# =============================================================================
# Checks if the required tools (docker, oras, openssl, etc.) are installed and 
# if Docker and Docker Compose are running. If any are missing or not running, 
# the script exits with an error.
check_requirements() {
    echo "🚀 Checking system requirements..."
    
    for tool in docker oras openssl tar install grep sed sort tail ls curl cp less tar awk tr cat pwd base64 chmod; do
        if ! command -v $tool > /dev/null 2>&1; then
            cat <<EOF
Missing tool: $tool

These are just examples, they are subject to change at any time.

Fedora:
  sudo dnf install docker-cli docker-compose golang-oras openssl tar coreutils grep sed curl less gawk

Arch Linux:
  sudo pacman -S docker docker-compose openssl tar coreutils grep sed curl less gawk
  ORAS is available from the AUR, for example:
    yay -S oras

OpenBSD:
  doas pkg_add docker-cli docker-compose oras curl less
  Note: this installs the Docker CLI, not a native Docker daemon.
  Should work with:
    export DOCKER_HOST=ssh://user@remote-host
  to a Linux system running Docker.

SUSE/openSUSE:
  sudo zypper install docker docker-compose oras openssl tar coreutils grep sed curl less gawk

Debian:
  sudo apt-get update
  sudo apt-get install docker.io docker-compose oras openssl tar coreutils grep sed curl less gawk

Ubuntu:
  sudo apt-get update
  sudo apt-get install docker.io docker-compose-v2 oras openssl tar coreutils grep sed curl less gawk
  sudo snap install oras --classic
EOF
            exit 1
        fi
    done

    if ! docker compose version > /dev/null 2>&1; then
        echo "Docker Compose not available"
        exit 1
    fi
    
    if ! docker ps > /dev/null 2>&1; then
        echo "Docker not running"
        exit 1
    fi
}
