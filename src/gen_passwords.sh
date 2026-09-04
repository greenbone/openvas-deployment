gen_fernet() {
    openssl rand -base64 32
}

gen_hex() {
    openssl rand -hex 64
}

gen_password() {
    openssl rand -base64 48 \
        | tr -dc 'A-Za-z0-9' \
        | head -c 32
}
