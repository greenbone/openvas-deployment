# =============================================================================
# init_settings_openvasd()
# =============================================================================
# Initializes the OpenVASD-specific settings for an enterprise-container
# deployment.
#
# The function validates that an OpenVASD common name (CN) is provided and
# stores it in the settings directory for later use.
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
        echo "${cn_openvasd}" > "${settings_dir}/OPENVASD_CN"
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
# The function reads the persisted OpenVASD common name (CN) from the settings
# directory and exports it as CN_OPENVASD for use by subsequent OpenVASD
# operations.
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
#   1 if the OpenVASD common name settings file is missing.
load_settings_openvasd() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    if [ -f "${settings_dir}/OPENVASD_CN" ]; then
        export CN_OPENVASD="$(< "${settings_dir}/OPENVASD_CN")"
    else
        echo "Error: No openvasd cn found at ${settings_dir}/OPENVASD_CN! Please run --init --deployment-mode openvasd!"
        exit 1
    fi
}
