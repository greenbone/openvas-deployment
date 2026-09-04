# =============================================================================
# init_license_file()
# =============================================================================
# Installs the license file and extracts its embedded OCI client credentials.
#
# The first argument names the associative array containing the parsed license
# data and defaults to LICENSE_DATA. The second and third arguments name the
# variables that receive the generated OCI client certificate and key paths.
#
# The function verifies that LICENSE_FILE exists, installs it in the OCI
# certificate directory with owner-only permissions, writes the embedded
# certificate and private key to separate files, and updates the referenced
# path variables. It exits with a non-zero status when the license file is
# missing.
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
# Reads license data from a section-based configuration file.
#
# The first argument specifies the input file and defaults to LICENSE_FILE. The
# second argument names the output array and defaults to LICENSE. Parsed values
# are stored using "section.key" as the array key. The function supports
# comments, blank lines, quoted values, and triple-quoted multiline values.
#
# Returns a non-zero status if a multiline value reaches the end of the file
# before its closing triple quotes are found.
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
