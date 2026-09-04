init_secrets_osi() {
    echo "Info: Init OSI secrets."

    # Keycloak
    gen_password > "${SECRETS_DIR}/KEYCLAOK_ADMIN_PASSWORD"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_DB_PASSWORD"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_OPENSEARCH_CLIENT_SECRET"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_WST_CLIENT_PASSWORD"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_NOTIFICATION_USER_PASSWORD"
    gen_password > "${SECRETS_DIR}/KEYCLOAK_REPORT_USER_PASSWORD"

    # OpenSearch
    gen_password > "${SECRETS_DIR}/OPENSEARCH_ADMIN_PASSWORD"

    # Notification Service
    gen_password > "${SECRETS_DIR}/NOTIFICATION_SERVICE_DB_PASSWORD"

    # REPORT
    gen_password > "${SECRETS_DIR}/ASSET_MANAGEMENT_DB_PASSWORD"
    gen_password > "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD"
    gen_password > "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT"

    # VIEW
    gen_password > "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_DB_PASSWORD"
    gen_hex > "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY"

    # CONTROL
    gen_password > "${SECRETS_DIR}/MANAGEMENT_CONSOLE_DB_PASSWORD"
    gen_fernet > "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY"
    gen_fernet > "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT"
    gen_fernet > "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SECRET_KEY"
    gen_fernet > "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY"
}

load_secrets_osi() {
    echo 'Info: Load secrets OSI'

    # Keycloak
    if [ -f "${SECRETS_DIR}/KEYCLAOK_ADMIN_PASSWORD" ]; then
        export KEYCLAOK_ADMIN_PASSWORD="$(< "${SECRETS_DIR}/KEYCLAOK_ADMIN_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLAOK_ADMIN_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_DB_PASSWORD" ]; then
        export KEYCLOAK_DB_PASSWORD="$(< "${SECRETS_DIR}/KEYCLOAK_DB_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_DB_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_OPENSEARCH_CLIENT_SECRET" ]; then
        export KEYCLOAK_OPENSEARCH_CLIENT_SECRET="$(< "${SECRETS_DIR}/KEYCLOAK_OPENSEARCH_CLIENT_SECRET")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_OPENSEARCH_CLIENT_SECRET! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_WST_CLIENT_PASSWORD" ]; then
        export KEYCLOAK_WST_CLIENT_PASSWORD="$(< "${SECRETS_DIR}/KEYCLOAK_WST_CLIENT_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_WST_CLIENT_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD" ]; then
        export KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD="$(< "${SECRETS_DIR}/KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_MC_BACKEND_CLIENT_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_NOTIFICATION_USER_PASSWORD" ]; then
        export KEYCLOAK_NOTIFICATION_USER_PASSWORD="$(< "${SECRETS_DIR}/KEYCLOAK_NOTIFICATION_USER_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_NOTIFICATION_USER_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/KEYCLOAK_REPORT_USER_PASSWORD" ]; then
        export KEYCLOAK_REPORT_USER_PASSWORD="$(< "${SECRETS_DIR}/KEYCLOAK_REPORT_USER_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/KEYCLOAK_REPORT_USER_PASSWORD! Please run --init!"
        exit 1
    fi

    # OpenSearch
    if [ -f "${SECRETS_DIR}/OPENSEARCH_ADMIN_PASSWORD" ]; then
        export OPENSEARCH_ADMIN_PASSWORD="$(< "${SECRETS_DIR}/OPENSEARCH_ADMIN_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/OPENSEARCH_ADMIN_PASSWORD! Please run --init!"
        exit 1
    fi

    # Notification Service
    if [ -f "${SECRETS_DIR}/NOTIFICATION_SERVICE_DB_PASSWORD" ]; then
        export NOTIFICATION_SERVICE_DB_PASSWORD="$(< "${SECRETS_DIR}/NOTIFICATION_SERVICE_DB_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/NOTIFICATION_SERVICE_DB_PASSWORD! Please run --init!"
        exit 1
    fi

    # REPORT
    if [ -f "${SECRETS_DIR}/ASSET_MANAGEMENT_DB_PASSWORD" ]; then
        export ASSET_MANAGEMENT_DB_PASSWORD="$(< "${SECRETS_DIR}/ASSET_MANAGEMENT_DB_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/ASSET_MANAGEMENT_DB_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD" ]; then
        export ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD="$(< "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT" ]; then
        export ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT="$(< "${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/ASSET_MANAGEMENT_TASK_REPORT_CRYPTO_V1_SALT! Please run --init!"
        exit 1
    fi

    # VIEW
    if [ -f "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_DB_PASSWORD" ]; then
        export VULNERABILITY_INTELLIGENCE_DB_PASSWORD="$(< "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_DB_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_DB_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY" ]; then
        export VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY="$(< "${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/VULNERABILITY_INTELLIGENCE_ENCRYPTION_KEY! Please run --init!"
        exit 1
    fi

    # CONTROL
    if [ -f "${SECRETS_DIR}/MANAGEMENT_CONSOLE_DB_PASSWORD" ]; then
        export MANAGEMENT_CONSOLE_DB_PASSWORD="$(< "${SECRETS_DIR}/MANAGEMENT_CONSOLE_DB_PASSWORD")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/MANAGEMENT_CONSOLE_DB_PASSWORD! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY" ]; then
        export MANAGEMENT_CONSOLE_ENCRYPTION_KEY="$(< "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT" ]; then
        export MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT="$(< "${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/MANAGEMENT_CONSOLE_ENCRYPTION_KEY_REPORT_PUSH_KC_CLIENT! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SECRET_KEY" ]; then
        export MANAGEMENT_CONSOLE_SECRET_KEY="$(< "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SECRET_KEY")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/MANAGEMENT_CONSOLE_SECRET_KEY! Please run --init!"
        exit 1
    fi
    if [ -f "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY" ]; then
        export MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY="$(< "${SECRETS_DIR}/MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY")"
    else
        echo "Error: No secret file found at ${SECRETS_DIR}/MANAGEMENT_CONSOLE_SUPPORT_PACKAGE_DOWNLOAD_URL_KEY! Please run --init!"
        exit 1
    fi
}
