#!/usr/bin/env bash
# BATS Contract Testing Helpers
# Provides utility functions for contract testing in BATS

# Load test framework utilities
load "helpers.sh" 2>/dev/null || true

# Contract Testing Functions

# Assert that a module exports required functions/attributes
assert_exports() {
    local module_path="$1"
    shift
    local required_exports=("$@")

    # Check if module file exists
    if [[ ! -f "$module_path" ]]; then
        echo "Module not found: $module_path" >&2
        return 1
    fi

    # Evaluate module and get exported attributes
    local exports
    exports=$(nix eval --json --file "$module_path" --arg lib 'import <nixpkgs/lib>' --arg pkgs 'import <nixpkgs> {}' 2>/dev/null | jq -r 'keys[]' 2>/dev/null) || {
        echo "Failed to evaluate module: $module_path" >&2
        return 1
    }

    # Check each required export
    for export in "${required_exports[@]}"; do
        if ! echo "$exports" | grep -q "^${export}$"; then
            echo "Module $module_path missing required export: $export" >&2
            echo "Available exports: $exports" >&2
            return 1
        fi
    done

    return 0
}

# Assert that a JSON object has required fields
assert_json_field() {
    local json="$1"
    local field="$2"
    local expected_type="$3"

    # Check if field exists
    if ! echo "$json" | jq -e "has(\"$field\")" >/dev/null 2>&1; then
        echo "JSON missing required field: $field" >&2
        return 1
    fi

    # Check field type if specified
    if [[ -n "$expected_type" ]]; then
        local actual_type
        actual_type=$(echo "$json" | jq -r ".$field | type")
        if [[ "$actual_type" != "$expected_type" ]]; then
            echo "Field $field has type $actual_type, expected $expected_type" >&2
            return 1
        fi
    fi

    return 0
}

# Assert that a flake output exists and has correct structure
assert_flake_output() {
    local output_path="$1"
    local expected_type="$2"

    # Evaluate flake output
    local result
    result=$(nix eval --json "$output_path" 2>/dev/null) || {
        echo "Failed to evaluate flake output: $output_path" >&2
        return 1
    }

    # Check type if specified
    if [[ -n "$expected_type" ]]; then
        local actual_type
        actual_type=$(echo "$result" | jq -r 'type')
        if [[ "$actual_type" != "$expected_type" ]]; then
            echo "Flake output $output_path has type $actual_type, expected $expected_type" >&2
            return 1
        fi
    fi

    return 0
}

# Assert that a command provides expected interface
assert_command_interface() {
    local command="$1"
    local expected_flags=("${@:2}")

    # Check if command exists
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Command not found: $command" >&2
        return 1
    fi

    # Get command help/usage
    local help_output
    help_output=$("$command" --help 2>&1) || help_output=$("$command" -h 2>&1) || {
        echo "Command $command does not provide help interface" >&2
        return 1
    }

    # Check for expected flags
    for flag in "${expected_flags[@]}"; do
        if ! echo "$help_output" | grep -q -- "$flag"; then
            echo "Command $command missing expected flag: $flag" >&2
            return 1
        fi
    done

    return 0
}

# Assert that a nix expression evaluates successfully
assert_nix_evaluates() {
    local expression="$1"
    local expected_value="$2"

    # Evaluate expression
    local result
    result=$(nix eval --impure --expr "$expression" 2>/dev/null) || {
        echo "Failed to evaluate Nix expression: $expression" >&2
        return 1
    }

    # Check expected value if provided
    if [[ -n "$expected_value" ]]; then
        # Remove quotes from nix eval output for comparison
        result=$(echo "$result" | sed 's/^"//;s/"$//')
        if [[ "$result" != "$expected_value" ]]; then
            echo "Expression '$expression' returned '$result', expected '$expected_value'" >&2
            return 1
        fi
    fi

    return 0
}

# Assert that a module configuration is valid
assert_module_config_valid() {
    local module_path="$1"
    local config_file="$2"

    # Build module with config
    local build_result
    build_result=$(nix build --impure --no-link --expr "
        let
          lib = import <nixpkgs/lib>;
          pkgs = import <nixpkgs> {};
          config = import $config_file;
          module = import $module_path;
        in
          lib.evalModules {
            modules = [ module config ];
          }
    " 2>&1) || {
        echo "Module $module_path failed validation with config $config_file" >&2
        echo "Error: $build_result" >&2
        return 1
    }

    return 0
}

# Assert platform compatibility
assert_platform_compatible() {
    local component="$1"
    local platforms=("${@:2}")

    local current_platform
    current_platform=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    for platform in "${platforms[@]}"; do
        if [[ "$current_platform" == "$platform" ]]; then
            return 0
        fi
    done

    skip "Component $component not compatible with platform $current_platform"
}

# Assert that a service contract is satisfied
assert_service_contract() {
    local service_name="$1"
    local expected_state="$2"
    local timeout="${3:-30}"

    local start_time
    start_time=$(date +%s)

    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ $elapsed -gt $timeout ]]; then
            echo "Service $service_name did not reach expected state $expected_state within ${timeout}s" >&2
            return 1
        fi

        # Check service state (this is a simplified check)
        if systemctl --user is-active "$service_name" >/dev/null 2>&1; then
            if [[ "$expected_state" == "active" ]]; then
                return 0
            fi
        elif [[ "$expected_state" == "inactive" ]]; then
            return 0
        fi

        sleep 1
    done
}

# Export functions for use in BATS tests
export -f assert_exports
export -f assert_json_field
export -f assert_flake_output
export -f assert_command_interface
export -f assert_nix_evaluates
export -f assert_module_config_valid
export -f assert_platform_compatible
export -f assert_service_contract
