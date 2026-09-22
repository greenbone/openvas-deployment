#!/usr/bin/env bash
set -euo pipefail

source /etc/os-release
case "$ID" in
    fedora)
        dnf install -y --allowerasing bash make ca-certificates curl tar gzip zstd less gawk tree \
            iproute coreutils findutils grep sed openssl sudo git make
        export SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
        export SSL_CERT_DIR=/etc/pki/ca-trust/extracted/pem
        ;;
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends bash make ca-certificates curl make \
            tar gzip zstd less gawk tree iproute2 coreutils findutils grep sed openssl sudo git
        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        export SSL_CERT_DIR=/etc/ssl/certs
        ;;
    arch)
        pacman -Syu --noconfirm --needed bash make ca-certificates curl tar gzip make \
            zstd less gawk tree iproute2 coreutils findutils grep sed openssl sudo git
        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        export SSL_CERT_DIR=/etc/ssl/certs
        ;;
    *)
        printf 'Unsupported CI distribution: %s\n' "$ID" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64)
        arch=amd64
        docker_arch=x86_64
        oras_sum=f27adb935022d94df8dc77719c322dda592c78a0d57a6f7dcdd8d900b248c454
        ;;
    aarch64)
        arch=arm64
        docker_arch=aarch64
        oras_sum=15702c6e3a4a56a8bd8ac5c17efdbcab56d9bada661ccbcf017f5b10c1d89399
        ;;
    *)
        printf 'Unsupported CI architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pushd "$tmp" > /dev/null
    # Docker cli
    docker_version=28.5.2
    curl -fsSL --retry 3 -o docker.tgz \
        "https://download.docker.com/linux/static/stable/${docker_arch}/docker-${docker_version}.tgz"
    tar -xzf docker.tgz docker/docker
    install -m 0755 docker/docker /usr/local/bin/docker

    # Compose
    compose_version=5.3.1
    compose_file="docker-compose-linux-${docker_arch}"
    compose_url="https://github.com/docker/compose/releases/download/v${compose_version}"
    curl -fsSL --retry 3 -o "$compose_file" "${compose_url}/${compose_file}"
    install -D -m 0755 "$compose_file" /usr/local/lib/docker/cli-plugins/docker-compose

    # Oras
    oras_file="oras_1.3.4_linux_${arch}.tar.gz"
    curl -fsSL --retry 3 -o "$oras_file" \
        "https://github.com/oras-project/oras/releases/download/v1.3.4/${oras_file}"
    printf '%s  %s\n' "$oras_sum" "$oras_file" | sha256sum -c -
    tar -xzf "$oras_file" oras
    install -m 0755 oras /usr/local/bin/oras
popd > /dev/null

# Build
make
install -m 0755 openvas-deployment /usr/bin/openvas-deployment

# Run CI
bash "regress/$1.sh"
