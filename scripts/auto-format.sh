#!/usr/bin/env bash
# Auto-formatting script for dotfiles repository
# Automatically fixes formatting issues instead of just reporting them

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DRY_RUN=false
VERBOSE=false
QUIET=false
SPECIFIC_TOOLS=()

# Color output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# Logging functions
log_info() {
    [[ "$QUIET" != "true" ]] && echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    [[ "$QUIET" != "true" ]] && echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${CYAN}🔍 $*${NC}"
}

# Usage information
show_usage() {
    cat << EOF
Auto-formatting script for dotfiles repository

USAGE:
    $0 [OPTIONS] [TOOLS...]

OPTIONS:
    -h, --help       Show this help message
    -d, --dry-run    Show what would be formatted without making changes
    -v, --verbose    Enable verbose output
    -q, --quiet      Suppress non-error output
    --check          Check if files need formatting (exit 1 if changes needed)

TOOLS:
    If no tools are specified, all available tools will be used.
    Available tools:
        nix         - Format Nix files with nixpkgs-fmt
        shell       - Format shell scripts with shfmt
        yaml        - Format YAML files with prettier
        json        - Format JSON files with prettier/jq
        markdown    - Format Markdown files with markdownlint
        all         - Run all formatters (default)

EXAMPLES:
    $0                              # Format all files
    $0 --dry-run                    # Show what would be changed
    $0 nix shell                    # Format only Nix and shell files
    $0 --verbose yaml               # Format YAML files with verbose output
    $0 --check                      # Check if formatting is needed (CI mode)

EOF
}

# Parse command line arguments
parse_args() {
    local check_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --check)
                check_mode=true
                DRY_RUN=true
                shift
                ;;
            nix|shell|yaml|json|markdown|all)
                SPECIFIC_TOOLS+=("$1")
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # If no tools specified, default to all
    if [[ ${#SPECIFIC_TOOLS[@]} -eq 0 ]]; then
        SPECIFIC_TOOLS=("all")
    fi
    
    # Set environment variable for check mode
    if [[ "$check_mode" == "true" ]]; then
        export AUTO_FORMAT_CHECK_MODE=true
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run command with dry-run support
run_formatter() {
    local tool="$1"
    local description="$2"
    shift 2
    local cmd=("$@")
    
    log_verbose "Running $tool: ${cmd[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run $description"
        return 0
    fi
    
    if "${cmd[@]}"; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Format Nix files
format_nix() {
    log_info "Formatting Nix files..."
    
    if ! command_exists nixpkgs-fmt; then
        log_warning "nixpkgs-fmt not found. Install with: nix shell nixpkgs#nixpkgs-fmt"
        return 1
    fi
    
    local nix_files
    mapfile -t nix_files < <(find "$PROJECT_ROOT" -name "*.nix" -not -path "*/\.*" | head -100)
    
    if [[ ${#nix_files[@]} -eq 0 ]]; then
        log_info "No Nix files found to format"
        return 0
    fi
    
    log_verbose "Found ${#nix_files[@]} Nix files"
    
    run_formatter "nixpkgs-fmt" "Nix formatting" nixpkgs-fmt "${nix_files[@]}"
}

# Format shell scripts
format_shell() {
    log_info "Formatting shell scripts..."
    
    if ! command_exists shfmt; then
        log_warning "shfmt not found. Install with: nix shell nixpkgs#shfmt"
        return 1
    fi
    
    local shell_files
    mapfile -t shell_files < <(find "$PROJECT_ROOT" -name "*.sh" -o -name "*.bash" | grep -v ".git" | head -100)
    
    if [[ ${#shell_files[@]} -eq 0 ]]; then
        log_info "No shell files found to format"
        return 0
    fi
    
    log_verbose "Found ${#shell_files[@]} shell files"
    
    local shfmt_args=(-w -s -i 2)
    if [[ "$DRY_RUN" == "true" ]]; then
        shfmt_args=(-d -s -i 2)  # Use diff mode for dry run
    fi
    
    run_formatter "shfmt" "Shell formatting" shfmt "${shfmt_args[@]}" "${shell_files[@]}"
}

# Format YAML files
format_yaml() {
    log_info "Formatting YAML files..."
    
    if ! command_exists prettier; then
        log_warning "prettier not found. Install with: nix shell nixpkgs#nodePackages.prettier"
        return 1
    fi
    
    local yaml_files
    mapfile -t yaml_files < <(find "$PROJECT_ROOT" -name "*.yaml" -o -name "*.yml" | grep -v ".git" | head -100)
    
    if [[ ${#yaml_files[@]} -eq 0 ]]; then
        log_info "No YAML files found to format"
        return 0
    fi
    
    log_verbose "Found ${#yaml_files[@]} YAML files"
    
    local prettier_args=(--tab-width=2 --print-width=120)
    if [[ "$DRY_RUN" != "true" ]]; then
        prettier_args+=(--write)
    else
        prettier_args+=(--check)
    fi
    
    run_formatter "prettier" "YAML formatting" prettier "${prettier_args[@]}" "${yaml_files[@]}"
}

# Format JSON files
format_json() {
    log_info "Formatting JSON files..."
    
    if ! command_exists jq; then
        log_warning "jq not found. Install with: nix shell nixpkgs#jq"
        return 1
    fi
    
    local json_files
    mapfile -t json_files < <(find "$PROJECT_ROOT" -name "*.json" | grep -v -E "(\\.git|node_modules|flake\\.lock)" | head -100)
    
    if [[ ${#json_files[@]} -eq 0 ]]; then
        log_info "No JSON files found to format"
        return 0
    fi
    
    log_verbose "Found ${#json_files[@]} JSON files"
    
    local formatted_count=0
    for file in "${json_files[@]}"; do
        log_verbose "Processing: $file"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            if ! jq empty "$file" >/dev/null 2>&1; then
                log_warning "Invalid JSON in $file"
            else
                log_info "[DRY RUN] Would format $file"
                ((formatted_count++))
            fi
        else
            if jq --indent 2 . "$file" > "${file}.tmp" 2>/dev/null; then
                mv "${file}.tmp" "$file"
                ((formatted_count++))
            else
                log_warning "Failed to format $file (invalid JSON?)"
                rm -f "${file}.tmp"
            fi
        fi
    done
    
    log_success "JSON formatting: $formatted_count files processed"
}

# Format Markdown files
format_markdown() {
    log_info "Formatting Markdown files..."
    
    if ! command_exists markdownlint; then
        log_warning "markdownlint not found. Install with: nix shell nixpkgs#nodePackages.markdownlint-cli"
        return 1
    fi
    
    local md_files
    mapfile -t md_files < <(find "$PROJECT_ROOT" -name "*.md" | grep -v ".git" | head -100)
    
    if [[ ${#md_files[@]} -eq 0 ]]; then
        log_info "No Markdown files found to format"
        return 0
    fi
    
    log_verbose "Found ${#md_files[@]} Markdown files"
    
    local markdownlint_args=(--config "$PROJECT_ROOT/.markdownlint.yaml")
    if [[ "$DRY_RUN" != "true" ]]; then
        markdownlint_args+=(--fix)
    fi
    
    # Exclude certain files as per original config
    local excluded_files=("CHANGELOG.md")
    local filtered_files=()
    for file in "${md_files[@]}"; do
        local basename_file
        basename_file=$(basename "$file")
        local exclude=false
        for excluded in "${excluded_files[@]}"; do
            if [[ "$basename_file" == "$excluded" ]]; then
                exclude=true
                break
            fi
        done
        if [[ "$exclude" == "false" ]]; then
            filtered_files+=("$file")
        fi
    done
    
    if [[ ${#filtered_files[@]} -eq 0 ]]; then
        log_info "No Markdown files to format (all excluded)"
        return 0
    fi
    
    run_formatter "markdownlint" "Markdown formatting" markdownlint "${markdownlint_args[@]}" "${filtered_files[@]}"
}

# Main formatting function
run_formatters() {
    local exit_code=0
    local tools_to_run=()
    
    # Determine which tools to run
    if [[ " ${SPECIFIC_TOOLS[*]} " =~ " all " ]]; then
        tools_to_run=("nix" "shell" "yaml" "json" "markdown")
    else
        tools_to_run=("${SPECIFIC_TOOLS[@]}")
    fi
    
    log_info "Running formatters: ${tools_to_run[*]}"
    [[ "$DRY_RUN" == "true" ]] && log_info "DRY RUN MODE - no files will be modified"
    
    # Run each formatter
    for tool in "${tools_to_run[@]}"; do
        case "$tool" in
            nix)
                format_nix || exit_code=1
                ;;
            shell)
                format_shell || exit_code=1
                ;;
            yaml)
                format_yaml || exit_code=1
                ;;
            json)
                format_json || exit_code=1
                ;;
            markdown)
                format_markdown || exit_code=1
                ;;
            *)
                log_error "Unknown tool: $tool"
                exit_code=1
                ;;
        esac
    done
    
    return $exit_code
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    
    parse_args "$@"
    
    if [[ "$DRY_RUN" == "true" && "${AUTO_FORMAT_CHECK_MODE:-}" == "true" ]]; then
        log_info "Running in check mode - will exit with non-zero if formatting is needed"
    fi
    
    log_info "Auto-formatting dotfiles repository"
    log_verbose "Project root: $PROJECT_ROOT"
    
    if run_formatters; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_success "All formatters completed (dry run)"
        else
            log_success "All files formatted successfully"
        fi
        exit 0
    else
        log_error "Some formatters failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"