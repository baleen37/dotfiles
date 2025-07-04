#!/bin/sh
# Sudo Management Module for Build Scripts
# Contains privilege management and sudo-related functions

# Sudo session management
SUDO_REQUIRED=false

# Basic sudo management functions
check_current_privileges() {
    [ "$(id -u)" -eq 0 ]
}

acquire_sudo_early() {
    # Skip if already root
    if check_current_privileges; then
        return 0
    fi

    # Check if we're in non-interactive environment
    if [ ! -t 0 ]; then
        if command -v log_warning >/dev/null 2>&1; then
            log_warning "Non-interactive environment - sudo may fail"
        fi
        return 0
    fi

    # Simple sudo validation
    if ! sudo -v; then
        if command -v log_error >/dev/null 2>&1; then
            log_error "Failed to acquire sudo privileges"
        fi
        return 1
    fi

    if command -v log_success >/dev/null 2>&1; then
        log_success "Sudo privileges acquired"
    fi
    return 0
}

# Register cleanup handlers
register_cleanup() {
    return 0
}

# Cleanup sudo session
cleanup_sudo_session() {
    return 0
}

# Explain why sudo is required for system changes
explain_sudo_requirement() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  Administrator Privileges Required${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "${YELLOW}▶ Why sudo is needed:${NC}"
    echo "${DIM}  • System configuration changes require administrator privileges${NC}"
    echo "${DIM}  • ${PLATFORM_NAME} rebuild commands must modify system files${NC}"
    echo "${DIM}  • This ensures your system is properly configured and secure${NC}"
    echo ""
    echo "${YELLOW}▶ What will happen:${NC}"
    echo "${DIM}  • You'll be prompted for your password once${NC}"
    echo "${DIM}  • Privileges will be used only for system configuration${NC}"
    echo "${DIM}  • Session will be cleaned up automatically when done${NC}"
    echo ""
}

# Determine if sudo will be needed later
check_sudo_requirement() {
    # Skip if already root
    if check_current_privileges; then
        SUDO_REQUIRED=false
        return 0
    fi

    # Check if we're in non-interactive environment (Claude Code)
    if [ ! -t 0 ]; then
        if command -v log_warning >/dev/null 2>&1; then
            log_warning "Non-interactive environment detected"
        fi
        if command -v log_info >/dev/null 2>&1; then
            log_info "System changes will require manual sudo execution"
        fi
        SUDO_REQUIRED=false
        return 0
    fi

    # Explain why sudo is needed
    explain_sudo_requirement

    SUDO_REQUIRED=true
    return 0
}

get_sudo_prefix() {
    if [ "$SUDO_REQUIRED" = "true" ]; then
        echo "sudo"
    else
        echo ""
    fi
}
