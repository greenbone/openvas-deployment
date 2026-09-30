# =============================================================================
# init_settings_openvasd()
# =============================================================================
# Initializes the OpenVASD-specific settings for an enterprise-container
# deployment.
#
# The function validates that an OpenVASD common name (CN) is provided and
# stores it in the settings directory using init_setting().
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name is not provided.
init_settings_openvasd() {
    local cn_openvasd="${1:-$CN_OPENVASD}"
    local settings_dir="${2:-$SETTINGS_DIR}"

    if [ "${cn_openvasd}" ]; then
        init_setting "OPENVASD_CN" "${cn_openvasd}" "${settings_dir}"
    else
        echo "Error: --cn-openvasd argument missing!"
    exit 1
    fi
}

# =============================================================================
# load_settings_openvasd()
# =============================================================================
# Loads the OpenVASD-specific settings for an enterprise-container deployment.
#
# The function loads the persisted OpenVASD common name (CN) from the settings
# directory and exports it as CN_OPENVASD using the generic load_setting()
# helper.
#
# If OPENVASD_PORT is configured, the function exports the value as
# OPENVAS_SCANNER_HOST_LISTEN_PORT to configure the OpenVAS scanner listener
# port.
#
# Arguments:
#   $1
#     Settings directory.
#     Defaults to SETTINGS_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name settings file is missing or empty.
load_settings_openvasd() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    load_setting "OPENVASD_CN" "CN_OPENVASD" "${settings_dir}"

    if [ "${OPENVASD_PORT}" ]; then
        export OPENVAS_SCANNER_HOST_LISTEN_PORT="${OPENVASD_PORT}"
    fi
}
