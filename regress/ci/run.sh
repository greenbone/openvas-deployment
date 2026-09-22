#!/usr/bin/env bash
set -euo pipefail

source /etc/os-release
case "$ID" in
    fedora)
        dnf install -y --allowerasing \
            bash make ca-certificates curl tar gzip zstd less gawk tree \
            iproute coreutils findutils grep sed openssl sudo git
        ;;
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends \
            bash make ca-certificates curl tar gzip zstd less gawk tree \
            iproute2 coreutils findutils grep sed openssl sudo git
        ;;
    arch)
        pacman -Syu --noconfirm --needed \
            bash make ca-certificates curl tar gzip zstd less gawk tree \
            iproute2 coreutils findutils grep sed openssl sudo git
        ;;
    *)
        printf 'Unsupported CI distribution: %s\n' "$ID" >&2
        exit 1
        ;;
esac

export SSL_CERT_FILE=/host-ca-certificates.crt

case "$(uname -m)" in
    x86_64)
        arch=amd64
        docker_arch=x86_64
        docker_sum=ea90cfd12e1eeb12aa1c971741adb8bd4ed88e2a574eaac13f5029a1dbc6300d
        compose_sum=f9ebc6ebdb19d769b793c245a736caaeb198c62587f13b25c660c13b4987f959
        oras_sum=f27adb935022d94df8dc77719c322dda592c78a0d57a6f7dcdd8d900b248c454
        ;;
    aarch64)
        arch=arm64
        docker_arch=aarch64
        docker_sum=9e4f82996ab790724094475ebed33a736434bfe5d45231b676fef22ffb80044d
        compose_sum=aa611e811d0ea25897839c404bfb5bf93ce706dc51c500a4457890f5d0606a86
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
    printf '%s  %s\n' "$docker_sum" docker.tgz | sha256sum -c -
    tar -xzf docker.tgz docker/docker
    install -m 0755 docker/docker /usr/local/bin/docker

    # Compose
    compose_version=5.3.1
    compose_file="docker-compose-linux-${docker_arch}"
    compose_url="https://github.com/docker/compose/releases/download/v${compose_version}"
    curl -fsSL --retry 3 -o "$compose_file" "${compose_url}/${compose_file}"
    printf '%s  %s\n' "$compose_sum" "$compose_file" | sha256sum -c -
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
bash "regress/${1:-ec}.sh"
