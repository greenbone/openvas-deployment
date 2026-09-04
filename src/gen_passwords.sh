# =============================================================================
# gen_fernet()
# =============================================================================
# Generates a random Base64-encoded value for use as a Fernet key or secret.
#
# The function uses OpenSSL to generate 32 bytes of cryptographically secure
# random data and writes the Base64-encoded result to standard output.
#
# Arguments:
#   None.
#
# Returns:
#   Writes the generated Base64-encoded random value to standard output.
gen_fernet() {
    openssl rand -base64 32
}

# =============================================================================
# gen_hex()
# =============================================================================
# Generates a random hexadecimal value.
#
# The function uses OpenSSL to generate 64 bytes of cryptographically secure
# random data and writes the hexadecimal representation to standard output.
#
# Arguments:
#   None.
#
# Returns:
#   Writes the generated hexadecimal random value to standard output.
gen_hex() {
    openssl rand -hex 64
}

# =============================================================================
# gen_password()
# =============================================================================
# Generates a random alphanumeric password.
#
# The function generates 48 bytes of cryptographically secure random data,
# encodes it as Base64, removes all non-alphanumeric characters, and returns
# the first 32 remaining characters.
#
# Arguments:
#   None.
#
# Returns:
#   Writes a 32-character alphanumeric password to standard output.
gen_password() {
    openssl rand -base64 48 \
        | tr -dc 'A-Za-z0-9' \
        | head -c 32
}
