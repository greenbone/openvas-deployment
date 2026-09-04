# =============================================================================
# main()
# =============================================================================
# Entry point of the script.
#
# Parses the command-line arguments and then invokes the main execution
# routine based on the selected mode and configuration.
main() {
    parse_args "$@"
    run
}

# =============================================================================
# main
# =============================================================================
main "$@"
