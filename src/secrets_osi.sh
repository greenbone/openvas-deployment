# init_secrets_osi()
# =============================================================================
# Initializes the secrets required by the security-intelligence product.
#
# The function creates credentials and encryption values for Keycloak,
# OpenSearch, the notification service, asset management, vulnerability
# intelligence, and the management console.
#
# Password-style secrets are generated with gen_password, hexadecimal
# encryption material with gen_hex, and Fernet-style values with gen_fernet.
# Each value is written to its dedicated file in SECRETS_DIR only if the file
# does not already exist. Existing secret files are preserved to avoid
# overwriting previously initialized credentials.
#
# Arguments:
#   None.
#
# Returns:
#   None.
init_secrets_osi() {
    echo "Info: Init secrets OSI"

    # Keycloak
    init_secret "KEYCLAOK_ADMIN_PASSWORD" gen_password
    init_secret "KEYCLOAK_DB_PASSWORD" gen_password
    init_secret "KEYCLOAK_OPENSEARCH_CLIENT_SECRET" gen_password
    init_secret "KEYCLOAK_WST_CLIENT_PASSWORD" gen_password
    init_secret "KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD" gen_password
    init_secret "KEYCLOAK_NOTIFICATION_USER_PASSWORD" gen_password
    init_secret "KEYCLOAK_REPORT_USER_PASSWORD" gen_password

    # OpenSearch
    init_secret "OPENSEARCH_ADMIN_PASSWORD" gen_password

    # Notification Service
    init_secret "NOTIFICATION_SERVICE_DB_PASSWORD" gen_password

    # REPORT
    init_secret "ASSET_MANAGEMENT_DB_PASSWORD" gen_password
    init_secret "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD" gen_password
    init_secret "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT" gen_password

    # VIEW
    init_secret "VULNERABILITY_INTELLIGENCE_DB_PASSWORD" gen_password
    init_secret "VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY" gen_hex

    # CONTROL
    init_secret "MANAGEMENT_CONSOLE_DB_PASSWORD" gen_password
    init_secret "MANAGEMENT_CONSOLE_ENCRYPTION_KEY" gen_fernet
    init_secret "MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT" gen_fernet
    init_secret "MANAGEMENT_CONSOLE_SECRET_KEY" gen_fernet
    init_secret "MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY" gen_fernet
}

# =============================================================================
# load_secrets_osi()
# =============================================================================
# Loads the secrets required by the security-intelligence product.
#
# The function reads the initialized secret files from SECRETS_DIR and exports
# their contents for use by Keycloak, OpenSearch, the notification service,
# asset management, vulnerability intelligence, and the management console.
#
# Arguments:
#   $1
#     Secrets directory.
#     Defaults to SECRETS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if any required OSI secret file is missing from SECRETS_DIR.
load_secrets_osi() {
    local secrets_dir="${1:-$SECRETS_DIR}"

    echo 'Info: Load secrets OSI'

    # Keycloak
    load_secret "KEYCLAOK_ADMIN_PASSWORD" "KEYCLAOK_ADMIN_PASSWORD" "${secrets_dir}"
    load_secret "KEYCLOAK_DB_PASSWORD" "KEYCLOAK_DB_PASSWORD" "${secrets_dir}"
    load_secret "KEYCLOAK_OPENSEARCH_CLIENT_SECRET" "KEYCLOAK_OPENSEARCH_CLIENT_SECRET" "${secrets_dir}"
    load_secret "KEYCLOAK_WST_CLIENT_PASSWORD" "KEYCLOAK_WST_CLIENT_PASSWORD" "${secrets_dir}"
    load_secret "KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD" "KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD" "${secrets_dir}"
    load_secret "KEYCLOAK_NOTIFICATION_USER_PASSWORD" "KEYCLOAK_NOTIFICATION_USER_PASSWORD" "${secrets_dir}"
    load_secret "KEYCLOAK_REPORT_USER_PASSWORD" "KEYCLOAK_REPORT_USER_PASSWORD" "${secrets_dir}"

    # OpenSearch
    load_secret "OPENSEARCH_ADMIN_PASSWORD" "OPENSEARCH_ADMIN_PASSWORD" "${secrets_dir}"

    # Notification Service
    load_secret "NOTIFICATION_SERVICE_DB_PASSWORD" "NOTIFICATION_SERVICE_DB_PASSWORD" "${secrets_dir}"

    # Asset Management / Report
    load_secret "ASSET_MANAGEMENT_DB_PASSWORD" "ASSET_MANAGEMENT_DB_PASSWORD" "${secrets_dir}"
    load_secret "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD" "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD" "${secrets_dir}"
    load_secret "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT" "ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT" "${secrets_dir}"

    # Vulnerability Intelligence / View
    load_secret "VULNERABILITY_INTELLIGENCE_DB_PASSWORD" "VULNERABILITY_INTELLIGENCE_DB_PASSWORD" "${secrets_dir}"
    load_secret "VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY" "VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY" "${secrets_dir}"

    # Management Console / Control
    load_secret "MANAGEMENT_CONSOLE_DB_PASSWORD" "MANAGEMENT_CONSOLE_DB_PASSWORD" "${secrets_dir}"
    load_secret "MANAGEMENT_CONSOLE_ENCRYPTION_KEY" "MANAGEMENT_CONSOLE_ENCRYPTION_KEY" "${secrets_dir}"
    load_secret "MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT" "MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT" "${secrets_dir}"
    load_secret "MANAGEMENT_CONSOLE_SECRET_KEY" "MANAGEMENT_CONSOLE_SECRET_KEY" "${secrets_dir}"
    load_secret "MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY" "MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY" "${secrets_dir}"
}
