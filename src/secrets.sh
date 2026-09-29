# =============================================================================
# init_secret()
# =============================================================================
# Initializes a secret file with a generated value if it does not already exist.
#
# If the specified secret file exists and is not empty, initialization is skipped
# and the existing secret value is preserved. Otherwise, the provided generator
# function is executed and its output is stored in the secret file.
#
# Arguments:
#   $1  Secret file name.
#   $2  Generator function used to create the secret value.
#   $3  Optional secrets directory. Defaults to SECRETS_DIR.
#
# Returns:
#   None. Exits with status 1 if secret generation fails or produces an empty file.
init_secret() {
        local file="${1}"
        local generator="${2}"
        local secrets_dir="${3:-$SECRETS_DIR}"

        if [ -s "${secrets_dir}/${file}" ]; then
            chmod 0600 "${secrets_dir}/${file}"
            echo "Info: Secret ${secrets_dir}/${file} exists, skip init!"
            return
        fi

        "${generator}" > "${secrets_dir}/${file}"
        chmod 0600 "${secrets_dir}/${file}"
        if [ ! -s "${secrets_dir}/${file}" ]; then
            echo "Error: Generated secret ${secrets_dir}/${file} is empty!"
            exit 1
        fi
}

# =============================================================================
# init_echo_secret()
# =============================================================================
# Initializes a secret file with a provided value.
#
# If the specified secret file exists and is not empty, initialization is skipped
# and the existing secret value is preserved unless force initialization is
# explicitly requested. When initialization proceeds, the provided password value
# is written to the secret file and the file permissions are restricted to the
# owner.
#
# Arguments:
#   $1  Secret file name.
#   $2  Password string to write to the secret file.
#   $3  Optional secrets directory. Defaults to SECRETS_DIR.
#   $4  Optional force flag. Set to "y" to overwrite an existing secret file.
#       Defaults to "n".
#
# Returns:
#   None. Skips initialization if the secret file already exists and force is
#   not enabled.
#
# Errors:
#   Exits with an error if the password input is empty.
init_echo_secret() {
        local file="${1}"
        local password="${2:?Error: input is empty}"
        local secrets_dir="${3:-$SECRETS_DIR}"
        local force="${4:-n}"

        if [ -s "${secrets_dir}/${file}" ] && [ "${force}" == 'n' ]; then
            chmod 0600 "${secrets_dir}/${file}"
            echo "Info: Secret ${secrets_dir}/${file} exists, skip init!"
            return
        fi

        printf '%s' "${password}" > "${secrets_dir}/${file}"
        chmod 0600 "${secrets_dir}/${file}"
}

# =============================================================================
# init_secrets()
# =============================================================================
# Initializes product-specific secrets for the selected OpenVAS product.
#
# The function dispatches secret initialization to the corresponding
# product-specific helper based on the provided product name.
#
# For enterprise-container, init_secrets_ec is called. For
# security-intelligence, init_secrets_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
init_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        init_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        init_secrets_osi
    fi
}

# =============================================================================
# load_secret()
# =============================================================================
# Loads a secret value from a file and exports it as an environment variable.
#
# If the specified secret file exists and is not empty, its content is assigned
# to the provided environment variable. Otherwise, an error is reported and the
# script exits.
#
# Arguments:
#   $1  Secret filename.
#   $2  Environment variable name to export.
#   $3  Optional secrets directory. Defaults to SECRETS_DIR.
#
# Returns:
#   None. Exports the loaded secret as an environment variable.
#
# Errors:
#   Exits with status 1 if the secret file does not exist or is empty.
load_secret() {
    local secret_file="$1"
    local env_var="$2"
    local secrets_dir="${3:-$SECRETS_DIR}"

    if [ -s "${secrets_dir}/${secret_file}" ]; then
        export "${env_var}=$(< "${secrets_dir}/${secret_file}")"
    else
        echo "Error: No secret found or is empty at ${secrets_dir}/${secret_file}! Please run --init!"
        exit 1
    fi
}

# =============================================================================
# load_secrets()
# =============================================================================
# Loads product-specific secrets for the selected OpenVAS product.
#
# The function dispatches secret loading to the corresponding product-specific
# helper based on the provided product name.
#
# For enterprise-container, load_secrets_ec is called. For
# security-intelligence, load_secrets_osi is called.
#
# Arguments:
#   $1
#     Product name.
#     Defaults to PRODUCT.
#
# Returns:
#   None.
load_secrets() {
    local product="${1:-$PRODUCT}"

    if [ "${product}" == 'enterprise-container' ]; then
        load_secrets_ec
    elif [ "${product}" == 'security-intelligence' ]; then
        load_secrets_osi
    fi
}
