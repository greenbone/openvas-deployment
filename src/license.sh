# =============================================================================
# init_license_file()
# =============================================================================
# Installs the configured license file and extracts the OCI TLS client
# certificate and private key from the parsed license data.
#
# The function verifies that LICENSE_FILE exists, installs it into CERT_DIR_OCI
# as license.toml, and writes the certificate and key stored in license_data to
# client.crt and client.key.
#
# The resulting certificate and key paths are assigned through name references
# to the provided OCI client certificate and key variables.
#
# Arguments:
#   $1
#     Name of the associative array containing the parsed license data.
#     Defaults to LICENSE_DATA.
#
#   $2
#     Name of the variable receiving the OCI TLS client certificate path.
#     Defaults to OCI_TLS_CLIENT_CERT.
#
#   $3
#     Name of the variable receiving the OCI TLS client private key path.
#     Defaults to OCI_TLS_CLIENT_KEY.
#
# Returns:
#   None.
#
# Exits:
#   1 if LICENSE_FILE is missing or does not reference an existing file.
init_license_file() {
    local -n license_data="${1:-LICENSE_DATA}"
    local -n oci_tls_client_cert="${2:-OCI_TLS_CLIENT_CERT}"
    local -n oci_tls_client_key="${3:-OCI_TLS_CLIENT_KEY}"

    if ! [ -f "${LICENSE_FILE}" ]; then
        echo "Error: --license-file argument missing or file ${LICENSE_FILE} not found!"
        exit 1
    fi

    install -m 0600 "${LICENSE_FILE}" "${CERT_DIR_OCI}/license.toml"

    echo "${license_data[license.certificate.cert]}" > "${CERT_DIR_OCI}/client.crt"
    oci_tls_client_cert="${CERT_DIR_OCI}/client.crt"
    echo "${license_data[license.certificate.key]}" > "${CERT_DIR_OCI}/client.key"
    oci_tls_client_key="${CERT_DIR_OCI}/client.key"
}

# =============================================================================
# read_license_file()
# =============================================================================
# Parses a license file and stores its values in an associative array.
#
# The function reads the specified file line by line, ignores blank lines and
# comments, tracks TOML-style section headers, and stores parsed key/value pairs
# using "<section>.<key>" as the associative array key.
#
# Both single-line values and triple-quoted multiline values are supported.
# Surrounding single or double quotes are removed from single-line values.
#
# Arguments:
#   $1
#     License file path.
#     Defaults to LICENSE_FILE.
#
#   $2
#     Name of the associative array receiving the parsed license data.
#     Defaults to LICENSE_DATA.
#
# Returns:
#   None.
#
# Exits:
#   Returns 1 if a triple-quoted multiline value reaches end-of-file before its
#   closing delimiter is found.
read_license_file() {
    local file="${1:-$LICENSE_FILE}"
    local -n out="${2:-LICENSE_DATA}"
    local section key value line

    while IFS= read -r line; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue

        if [[ $line =~ ^\[([^]]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"

        elif [[ $line =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*\"\"\"(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            key="${key//[[:space:]]/}"
            value="${BASH_REMATCH[2]}"

            while [[ $value != *'"""' ]]; do
                IFS= read -r line || return 1
                value+="${value:+$'\n'}${line}"
            done

            value=${value%\"\"\"}
            out["${section}.${key}"]="${value}"

        elif [[ $line =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            key="${key//[[:space:]]/}"

            [[ $value == \'*\' || $value == \"*\" ]] &&
                value="${value:1:-1}"

            out["${section}.${key}"]="${value}"
        fi
    done < "$file"
}
