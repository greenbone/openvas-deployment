# =============================================================================
# init_settings_openvasd()
# =============================================================================
# Initializes the OpenVASD environment configuration by storing the OpenVASD
# common name (CN) in the working directory.
#
# Arguments:
#   $1
#     OpenVASD common name (CN).
#     Defaults to CN_OPENVASD.
#
#   $2
#     Working directory where the OPENVASD_CN file is created.
#     Defaults to WORKING_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OpenVASD common name is missing.
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
# Loads the OpenVASD environment configuration from the OPENVASD_CN file in the
# working directory and exports the OpenVASD common name (CN) for use by
# subsequent deployment operations.
#
# Arguments:
#   $1
#     Working directory containing the OPENVASD_CN file.
#     Defaults to WORKING_DIR.
#
# Returns:
#   None.
#
# Exits:
#   1 if the OPENVASD_CN file is missing.
load_settings_openvasd() {
    local settings_dir="${1:-$SETTINGS_DIR}"

    if [ -f "${settings_dir}/OPENVASD_CN" ]; then
        export CN_OPENVASD="$(< "${settings_dir}/OPENVASD_CN")"
    else
        echo "Error: No openvasd cn found at ${settings_dir}/OPENVASD_CN! Please run --init --deployment-mode openvasd!"
        exit 1
    fi
}
