#!/usr/bin/env bash

# T029: Test fixtures library
# Provides test data setup and teardown functionality

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.bash"

# Fixture management
declare -A FIXTURES=()
declare -a FIXTURE_CLEANUP_QUEUE=()

# Fixture registry
fixture_register() {
    local name="$1"
    local setup_function="$2"
    local teardown_function="${3:-}"

    FIXTURES["${name}:setup"]="$setup_function"
    FIXTURES["${name}:teardown"]="$teardown_function"

    log_debug "Fixture registered: $name"
}

fixture_setup() {
    local name="$1"
    local setup_function="${FIXTURES["${name}:setup"]:-}"

    if [[ -z "$setup_function" ]]; then
        log_error "Fixture not found: $name"
        return 1
    fi

    log_debug "Setting up fixture: $name"

    if "$setup_function"; then
        FIXTURE_CLEANUP_QUEUE+=("$name")
        log_debug "Fixture setup completed: $name"
        return 0
    else
        log_error "Fixture setup failed: $name"
        return 1
    fi
}

fixture_teardown() {
    local name="$1"
    local teardown_function="${FIXTURES["${name}:teardown"]:-}"

    if [[ -n "$teardown_function" ]]; then
        log_debug "Tearing down fixture: $name"
        if "$teardown_function"; then
            log_debug "Fixture teardown completed: $name"
        else
            log_error "Fixture teardown failed: $name"
        fi
    fi
}

fixture_cleanup_all() {
    log_debug "Cleaning up all fixtures"

    # Cleanup in reverse order
    for ((i=${#FIXTURE_CLEANUP_QUEUE[@]}-1; i>=0; i--)); do
        local fixture_name="${FIXTURE_CLEANUP_QUEUE[i]}"
        fixture_teardown "$fixture_name"
    done

    FIXTURE_CLEANUP_QUEUE=()
}

# Built-in fixtures

# Temporary directory fixture
fixture_temp_dir_setup() {
    local temp_dir
    temp_dir=$(mktemp -d)

    export FIXTURE_TEMP_DIR="$temp_dir"
    log_debug "Created temp directory: $temp_dir"

    return 0
}

fixture_temp_dir_teardown() {
    if [[ -n "${FIXTURE_TEMP_DIR:-}" && -d "$FIXTURE_TEMP_DIR" ]]; then
        rm -rf "$FIXTURE_TEMP_DIR"
        log_debug "Removed temp directory: $FIXTURE_TEMP_DIR"
        unset FIXTURE_TEMP_DIR
    fi
}

# Test files fixture
fixture_test_files_setup() {
    local base_dir="${FIXTURE_TEMP_DIR:-$(mktemp -d)}"

    export FIXTURE_TEST_FILES_DIR="$base_dir/test_files"
    mkdir -p "$FIXTURE_TEST_FILES_DIR"

    # Create various test files
    echo "Hello, World!" > "$FIXTURE_TEST_FILES_DIR/hello.txt"
    echo "#!/bin/bash\necho 'test script'" > "$FIXTURE_TEST_FILES_DIR/script.sh"
    chmod +x "$FIXTURE_TEST_FILES_DIR/script.sh"

    # Create a JSON file
    cat > "$FIXTURE_TEST_FILES_DIR/config.json" << 'EOF'
{
  "name": "test",
  "version": "1.0.0",
  "enabled": true
}
EOF

    # Create a YAML file
    cat > "$FIXTURE_TEST_FILES_DIR/config.yaml" << 'EOF'
name: test
version: 1.0.0
enabled: true
items:
  - item1
  - item2
EOF

    # Create subdirectories
    mkdir -p "$FIXTURE_TEST_FILES_DIR/subdir"
    echo "nested content" > "$FIXTURE_TEST_FILES_DIR/subdir/nested.txt"

    log_debug "Created test files in: $FIXTURE_TEST_FILES_DIR"
    return 0
}

fixture_test_files_teardown() {
    if [[ -n "${FIXTURE_TEST_FILES_DIR:-}" && -d "$FIXTURE_TEST_FILES_DIR" ]]; then
        rm -rf "$FIXTURE_TEST_FILES_DIR"
        log_debug "Removed test files directory: $FIXTURE_TEST_FILES_DIR"
        unset FIXTURE_TEST_FILES_DIR
    fi
}

# Git repository fixture
fixture_git_repo_setup() {
    local base_dir="${FIXTURE_TEMP_DIR:-$(mktemp -d)}"

    export FIXTURE_GIT_REPO_DIR="$base_dir/git_repo"
    mkdir -p "$FIXTURE_GIT_REPO_DIR"

    cd "$FIXTURE_GIT_REPO_DIR"

    # Initialize git repo
    git init >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1

    # Create initial commit
    echo "# Test Repository" > README.md
    git add README.md >/dev/null 2>&1
    git commit -m "Initial commit" >/dev/null 2>&1

    # Create some test content
    echo "console.log('Hello, World!');" > index.js
    echo "export default { test: true };" > config.js

    mkdir -p src
    echo "export function greet() { return 'Hello'; }" > src/utils.js

    git add . >/dev/null 2>&1
    git commit -m "Add test files" >/dev/null 2>&1

    log_debug "Created git repository: $FIXTURE_GIT_REPO_DIR"
    return 0
}

fixture_git_repo_teardown() {
    if [[ -n "${FIXTURE_GIT_REPO_DIR:-}" && -d "$FIXTURE_GIT_REPO_DIR" ]]; then
        rm -rf "$FIXTURE_GIT_REPO_DIR"
        log_debug "Removed git repository: $FIXTURE_GIT_REPO_DIR"
        unset FIXTURE_GIT_REPO_DIR
    fi
}

# Nix flake fixture
fixture_nix_flake_setup() {
    local base_dir="${FIXTURE_TEMP_DIR:-$(mktemp -d)}"

    export FIXTURE_NIX_FLAKE_DIR="$base_dir/nix_flake"
    mkdir -p "$FIXTURE_NIX_FLAKE_DIR"

    cd "$FIXTURE_NIX_FLAKE_DIR"

    # Create a minimal flake.nix
    cat > flake.nix << 'EOF'
{
  description = "Test flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
  };
}
EOF

    # Initialize git (required for flakes)
    git init >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git add flake.nix >/dev/null 2>&1
    git commit -m "Initial flake" >/dev/null 2>&1

    log_debug "Created Nix flake: $FIXTURE_NIX_FLAKE_DIR"
    return 0
}

fixture_nix_flake_teardown() {
    if [[ -n "${FIXTURE_NIX_FLAKE_DIR:-}" && -d "$FIXTURE_NIX_FLAKE_DIR" ]]; then
        rm -rf "$FIXTURE_NIX_FLAKE_DIR"
        log_debug "Removed Nix flake: $FIXTURE_NIX_FLAKE_DIR"
        unset FIXTURE_NIX_FLAKE_DIR
    fi
}

# Mock services fixture
fixture_mock_services_setup() {
    local base_dir="${FIXTURE_TEMP_DIR:-$(mktemp -d)}"

    export FIXTURE_MOCK_SERVICES_DIR="$base_dir/mock_services"
    mkdir -p "$FIXTURE_MOCK_SERVICES_DIR"

    # Create a simple HTTP server mock
    cat > "$FIXTURE_MOCK_SERVICES_DIR/http_server.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
from urllib.parse import urlparse, parse_qs

class MockHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress log messages

if __name__ == "__main__":
    PORT = 8888
    with socketserver.TCPServer(("", PORT), MockHandler) as httpd:
        httpd.serve_forever()
EOF

    chmod +x "$FIXTURE_MOCK_SERVICES_DIR/http_server.py"

    # Create a mock SSH server script
    cat > "$FIXTURE_MOCK_SERVICES_DIR/ssh_server.sh" << 'EOF'
#!/bin/bash
# Mock SSH server that just listens on a port
socat TCP-LISTEN:2222,reuseaddr,fork EXEC:'/bin/cat'
EOF

    chmod +x "$FIXTURE_MOCK_SERVICES_DIR/ssh_server.sh"

    log_debug "Created mock services: $FIXTURE_MOCK_SERVICES_DIR"
    return 0
}

fixture_mock_services_teardown() {
    # Kill any mock services that might be running
    pkill -f "http_server.py" 2>/dev/null || true
    pkill -f "ssh_server.sh" 2>/dev/null || true

    if [[ -n "${FIXTURE_MOCK_SERVICES_DIR:-}" && -d "$FIXTURE_MOCK_SERVICES_DIR" ]]; then
        rm -rf "$FIXTURE_MOCK_SERVICES_DIR"
        log_debug "Removed mock services: $FIXTURE_MOCK_SERVICES_DIR"
        unset FIXTURE_MOCK_SERVICES_DIR
    fi
}

# Configuration fixtures
fixture_test_config_setup() {
    local base_dir="${FIXTURE_TEMP_DIR:-$(mktemp -d)}"

    export FIXTURE_TEST_CONFIG_DIR="$base_dir/config"
    mkdir -p "$FIXTURE_TEST_CONFIG_DIR"

    # Create test configuration files
    cat > "$FIXTURE_TEST_CONFIG_DIR/app.conf" << 'EOF'
[app]
name = test_app
debug = true
port = 3000

[database]
host = localhost
port = 5432
name = test_db
EOF

    cat > "$FIXTURE_TEST_CONFIG_DIR/settings.json" << 'EOF'
{
  "app": {
    "name": "test_app",
    "version": "1.0.0",
    "features": {
      "auth": true,
      "logging": true
    }
  },
  "environment": "test"
}
EOF

    # Create environment file
    cat > "$FIXTURE_TEST_CONFIG_DIR/.env" << 'EOF'
NODE_ENV=test
DEBUG=true
DATABASE_URL=postgresql://localhost:5432/test_db
API_KEY=test_key_123
EOF

    log_debug "Created test config: $FIXTURE_TEST_CONFIG_DIR"
    return 0
}

fixture_test_config_teardown() {
    if [[ -n "${FIXTURE_TEST_CONFIG_DIR:-}" && -d "$FIXTURE_TEST_CONFIG_DIR" ]]; then
        rm -rf "$FIXTURE_TEST_CONFIG_DIR"
        log_debug "Removed test config: $FIXTURE_TEST_CONFIG_DIR"
        unset FIXTURE_TEST_CONFIG_DIR
    fi
}

# Register built-in fixtures
fixture_register "temp_dir" "fixture_temp_dir_setup" "fixture_temp_dir_teardown"
fixture_register "test_files" "fixture_test_files_setup" "fixture_test_files_teardown"
fixture_register "git_repo" "fixture_git_repo_setup" "fixture_git_repo_teardown"
fixture_register "nix_flake" "fixture_nix_flake_setup" "fixture_nix_flake_teardown"
fixture_register "mock_services" "fixture_mock_services_setup" "fixture_mock_services_teardown"
fixture_register "test_config" "fixture_test_config_setup" "fixture_test_config_teardown"

# Convenience functions for common fixture combinations
fixtures_setup_basic() {
    fixture_setup "temp_dir"
    fixture_setup "test_files"
}

fixtures_setup_development() {
    fixture_setup "temp_dir"
    fixture_setup "test_files"
    fixture_setup "git_repo"
    fixture_setup "test_config"
}

fixtures_setup_nix() {
    fixture_setup "temp_dir"
    fixture_setup "nix_flake"
}

fixtures_setup_integration() {
    fixture_setup "temp_dir"
    fixture_setup "test_files"
    fixture_setup "mock_services"
    fixture_setup "test_config"
}

# Cleanup handler
fixtures_cleanup_handler() {
    log_debug "Running fixture cleanup on exit"
    fixture_cleanup_all
}

# Register cleanup handler
trap fixtures_cleanup_handler EXIT

# Functions available when sourced
