# TDD Workflow Examples

> **Examples demonstrating Test-Driven Development workflow for dotfiles**

## Red-Green-Refactor Cycle Example

### Phase 1: Red - Write Failing Test

First, create a test that validates the desired functionality:

```nix
# tests/unit/config-loader-unit.nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "config-loader-test"
{
  buildInputs = with pkgs; [ bash yq ];
} ''
  echo "🧪 Config Loader Unit Test - Red Phase"
  echo "====================================="

  # Test source
  source ${src}/scripts/utils/config-loader.sh

  # Test 1: Configuration loading
  echo "📋 Test 1: Load All Configs"
  if load_all_configs; then
    echo "✅ Config loading function exists"
  else
    echo "❌ Config loading failed - function not implemented"
    exit 1
  fi

  # Test 2: Get config function
  echo "📋 Test 2: Get Config Function"
  timeout=$(get_config "build" "timeout" "3600")
  if [[ -n "$timeout" ]]; then
    echo "✅ Get config function works"
  else
    echo "❌ Get config function not implemented"
    exit 1
  fi

  # Test 3: Unified config interface
  echo "📋 Test 3: Unified Config Interface"
  value=$(get_unified_config "test_key" "default_value")
  if [[ "$value" == "default_value" ]]; then
    echo "✅ Unified config returns fallback correctly"
  else
    echo "❌ Unified config interface not working"
    exit 1
  fi

  touch $out
''
```

**Run the test (should fail):**

```bash
nix build .#checks.aarch64-darwin.config_loader_unit
# Expected: Build fails - functions not implemented yet
```

### Phase 2: Green - Minimal Implementation

Create the minimal implementation to pass the test:

```bash
# scripts/utils/config-loader.sh
#!/bin/bash

# Minimal implementation to pass tests

load_all_configs() {
    # Basic function that just returns success
    return 0
}

get_config() {
    local config_type="$1"
    local key="$2"
    local default="$3"

    # Return default value for now
    echo "$default"
}

get_unified_config() {
    local key="$1"
    local default="$2"

    # Return default value for now
    echo "$default"
}
```

**Run the test (should pass):**

```bash
nix build .#checks.aarch64-darwin.config_loader_unit
# Expected: Build succeeds - minimal implementation works
```

### Phase 3: Refactor - Improve Implementation

Now improve the code quality while keeping tests green:

```bash
# scripts/utils/config-loader.sh
#!/bin/bash

# Configuration cache tracking
CONFIG_CACHE_LOADED="${CONFIG_CACHE_LOADED:-false}"

# Configuration loading with caching
load_all_configs() {
    if [[ "$CONFIG_CACHE_LOADED" == "true" ]]; then
        return 0
    fi

    local dotfiles_root
    dotfiles_root=$(get_dotfiles_root)

    # Load configuration files
    for config_file in "$dotfiles_root/config"/*.yaml; do
        if [[ -f "$config_file" && -r "$config_file" ]]; then
            echo "Loading config: $(basename "$config_file")" >&2
        fi
    done

    CONFIG_CACHE_LOADED=true
    return 0
}

get_config() {
    local config_type="$1"
    local key="$2"
    local default="$3"

    # Intelligent config resolution
    local dotfiles_root
    dotfiles_root=$(get_dotfiles_root)
    local config_file="$dotfiles_root/config/${config_type}.yaml"

    if [[ -f "$config_file" ]] && command -v yq >/dev/null 2>&1; then
        local value
        value=$(yq eval ".${config_type}.${key}" "$config_file" 2>/dev/null)
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    echo "$default"
}

get_unified_config() {
    local key="$1"
    local default="$2"

    # Search across config types with priority
    local config_types=("build" "platform" "path")

    for config_type in "${config_types[@]}"; do
        local value
        value=$(get_config "$config_type" "$key" "")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    done

    echo "$default"
}

get_dotfiles_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/flake.nix" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    echo "$PWD"
}
```

**Verify tests still pass:**

```bash
nix build .#checks.aarch64-darwin.config_loader_unit
# Expected: Build succeeds - refactored implementation still works
```

## Integration Test Example

After unit tests pass, create integration tests:

```nix
# tests/integration/config-system-integration.nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "config-system-integration"
{
  buildInputs = with pkgs; [ bash yq ];
} ''
  echo "🧪 Config System Integration Test"
  echo "==============================="

  # Setup test environment
  export HOME=/tmp/test-home
  mkdir -p $HOME

  # Create test config files
  mkdir -p ${src}/config
  cat > ${src}/config/build-settings.yaml << 'EOF'
build:
  timeout: 7200
  parallel_jobs: 8
EOF

  cat > ${src}/config/paths.yaml << 'EOF'
ssh_directories:
  darwin: "/Users/\${USER}/.ssh"
  linux: "/home/\${USER}/.ssh"
EOF

  # Test integration
  source ${src}/scripts/utils/config-loader.sh

  # Test full workflow
  echo "📋 Integration Test 1: Full Config Loading"
  if load_all_configs; then
    echo "✅ Configuration system loads successfully"
  else
    echo "❌ Configuration system failed to load"
    exit 1
  fi

  # Test cross-config access
  echo "📋 Integration Test 2: Cross-Config Access"
  timeout=$(get_config "build" "timeout" "3600")
  ssh_dir=$(get_config "path" "ssh_dir_darwin" "/default/ssh")

  if [[ "$timeout" == "7200" ]] && [[ "$ssh_dir" == "/Users/\${USER}/.ssh" ]]; then
    echo "✅ Cross-config access working"
  else
    echo "❌ Cross-config access failed"
    echo "  Expected timeout: 7200, got: $timeout"
    echo "  Expected ssh_dir: /Users/\${USER}/.ssh, got: $ssh_dir"
    exit 1
  fi

  echo "🎉 Integration tests passed!"
  touch $out
''
```

## E2E Test Example

End-to-end test for complete user workflow:

```nix
# tests/e2e/config-workflow-e2e.nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "config-workflow-e2e"
{
  buildInputs = with pkgs; [ bash yq ];
} ''
  echo "🧪 Config Workflow E2E Test"
  echo "=========================="

  # Setup realistic test environment
  export HOME=/tmp/e2e-home
  export CONFIG_PROFILE="development"
  mkdir -p $HOME

  # Copy actual config structure
  cp -r ${src}/config /tmp/test-config

  # Test complete user workflow
  echo "📋 E2E Test 1: Complete Config Workflow"

  # Step 1: Load configuration system
  source ${src}/scripts/utils/config-loader.sh
  load_all_configs

  # Step 2: User gets build settings
  build_timeout=$(get_unified_config "timeout" "3600")
  parallel_jobs=$(get_unified_config "parallel_jobs" "4")

  # Step 3: User applies platform-specific settings
  ssh_dir=$(get_unified_config "ssh_dir_darwin" "/default")

  # Step 4: User checks loaded state
  if is_config_loaded; then
    echo "✅ Config state tracking works"
  else
    echo "❌ Config state tracking failed"
    exit 1
  fi

  # Verify realistic values
  if [[ "$build_timeout" =~ ^[0-9]+$ ]] && [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
    echo "✅ Config values are realistic"
  else
    echo "❌ Config values are not realistic"
    exit 1
  fi

  echo "🎉 E2E workflow test passed!"
  touch $out
''
```

## Performance Test Example

Test performance characteristics:

```nix
# tests/performance/config-performance.nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "config-performance"
{
  buildInputs = with pkgs; [ bash time yq ];
} ''
  echo "🧪 Config Performance Test"
  echo "========================"

  source ${src}/scripts/utils/config-loader.sh

  # Test 1: Cold load performance
  echo "📋 Performance Test 1: Cold Load"
  start_time=$(date +%s%N)
  load_all_configs
  end_time=$(date +%s%N)

  cold_load_time=$(( (end_time - start_time) / 1000000 ))
  echo "Cold load time: ${cold_load_time}ms"

  # Test 2: Cached load performance
  echo "📋 Performance Test 2: Cached Load"
  start_time=$(date +%s%N)
  load_all_configs
  end_time=$(date +%s%N)

  cached_load_time=$(( (end_time - start_time) / 1000000 ))
  echo "Cached load time: ${cached_load_time}ms"

  # Test 3: Config access performance
  echo "📋 Performance Test 3: Config Access"
  start_time=$(date +%s%N)
  for i in {1..100}; do
    get_unified_config "timeout" "3600" >/dev/null
  done
  end_time=$(date +%s%N)

  access_time=$(( (end_time - start_time) / 1000000 ))
  echo "100 config accesses: ${access_time}ms"

  # Performance validation
  if [[ $cold_load_time -lt 1000 ]] && [[ $cached_load_time -lt 100 ]] && [[ $access_time -lt 500 ]]; then
    echo "✅ Performance requirements met"
  else
    echo "❌ Performance requirements not met"
    echo "  Cold load should be < 1000ms, got: ${cold_load_time}ms"
    echo "  Cached load should be < 100ms, got: ${cached_load_time}ms"  
    echo "  100 accesses should be < 500ms, got: ${access_time}ms"
    exit 1
  fi

  touch $out
''
```

## TDD Best Practices

### 1. Test First, Always

- Write the test before any implementation
- Make sure the test fails initially
- Only write enough code to make the test pass

### 2. Incremental Development

```bash
# Small, focused commits for each TDD cycle
git commit -m "Red: Add failing test for config loader"
git commit -m "Green: Minimal implementation for config loader"
git commit -m "Refactor: Improve config loader with caching"
```

### 3. Test Categories

- **Unit**: Test individual functions
- **Integration**: Test module interactions  
- **E2E**: Test complete workflows
- **Performance**: Test speed and resource usage

### 4. Continuous Validation

```bash
# Run tests frequently during development
nix build .#checks.aarch64-darwin.test-all

# Run specific test categories
nix build .#checks.aarch64-darwin.unit-tests
nix build .#checks.aarch64-darwin.integration-tests
```

This TDD approach ensures robust, well-tested code that meets requirements and performs well.
