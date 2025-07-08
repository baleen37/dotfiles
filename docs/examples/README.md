# Examples Directory

> **Comprehensive collection of practical examples and templates for the dotfiles system**

This directory contains working examples, templates, and guides to help you understand and effectively use the Phase 4 dotfiles architecture.

## 📁 Directory Contents

### Configuration Examples

- **[config-usage.sh](./config-usage.sh)**: Complete configuration system usage examples
- **[yaml-config-templates.yaml](./yaml-config-templates.yaml)**: YAML configuration templates and patterns

### Development Guides

- **[tdd-workflow.md](./tdd-workflow.md)**: Test-Driven Development workflow examples

## 🚀 Quick Start Examples

### Basic Configuration Usage

```bash
# Load and use the configuration system
source scripts/utils/config-loader.sh
load_all_configs

# Get configuration values with fallbacks
timeout=$(get_unified_config "timeout" "3600")
cache_size=$(get_unified_config "max_size_gb" "5")
```

### Creating Custom Configuration

```yaml
# config/my-custom-settings.yaml
my_feature:
  enabled: true
  timeout: 60
  max_retries: 3
```

```bash
# scripts/my-feature.sh
source scripts/utils/config-loader.sh
load_all_configs

feature_enabled=$(get_config "my_feature" "enabled" "false")
if [[ "$feature_enabled" == "true" ]]; then
    echo "Feature is enabled"
fi
```

### TDD Development Example

```bash
# 1. Red Phase - Write failing test
# tests/unit/my-feature-unit.nix

# 2. Green Phase - Minimal implementation
# scripts/my-feature.sh

# 3. Refactor Phase - Improve code quality
# Optimize while keeping tests green
```

## 📚 Learning Path

### For New Users

1. **Start Here**: [config-usage.sh](./config-usage.sh)
   - Basic configuration loading
   - Environment variable overrides
   - Profile usage

2. **Configuration Templates**: [yaml-config-templates.yaml](./yaml-config-templates.yaml)
   - Pre-built configuration examples
   - Platform-specific settings
   - Performance optimization configs

3. **Development Workflow**: [tdd-workflow.md](./tdd-workflow.md)
   - Test-Driven Development approach
   - Red-Green-Refactor cycles
   - Best practices

### For Advanced Users

1. **Custom Configuration Systems**
   - Extend the configuration loader
   - Create custom config types
   - Implement advanced validation

2. **Performance Optimization**
   - Configuration caching strategies
   - Profile switching optimization
   - Build performance tuning

3. **Module Development**
   - Creating new modules
   - Cross-platform compatibility
   - Integration patterns

## 🔧 Running Examples

### Configuration Examples

```bash
# Make the script executable
chmod +x docs/examples/config-usage.sh

# Run configuration usage examples
./docs/examples/config-usage.sh
```

### Testing Examples

```bash
# Run TDD workflow examples
nix build .#checks.aarch64-darwin.test-all --show-trace
```

### Template Usage

```bash
# Copy and customize YAML templates
cp docs/examples/yaml-config-templates.yaml config/my-settings.yaml
vim config/my-settings.yaml  # Edit as needed
```

## 💡 Tips and Best Practices

### Configuration

- **Always use fallbacks**: `get_unified_config "key" "default_value"`
- **Leverage environment variables**: Export commonly used settings
- **Use profiles**: Switch between development/production configurations
- **Cache configuration**: Load once, use many times

### Development

- **Follow TDD**: Write tests before implementation
- **Use modular architecture**: Separate common, platform, and target-specific code
- **Document APIs**: Include examples in all API documentation
- **Test extensively**: Unit, integration, E2E, and performance tests

### Performance

- **Minimize config loading**: Use `is_config_loaded()` checks
- **Prefer unified interface**: `get_unified_config()` over multiple specific calls
- **Cache at component level**: Load configuration once per component
- **Profile for performance**: Include performance tests in TDD cycles

## 🔍 Example Patterns

### Error Handling Pattern

```bash
# Configuration with error handling
source scripts/utils/config-loader.sh
if ! load_all_configs; then
    echo "❌ Failed to load configuration"
    exit 1
fi

timeout=$(get_unified_config "timeout" "3600")
if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid timeout value: $timeout"
    exit 1
fi
```

### Cross-Platform Pattern

```bash
# Platform-aware configuration
source scripts/utils/config-loader.sh
load_all_configs

# Automatically chooses correct platform
ssh_dir=$(get_unified_config "ssh_dir_$(uname -s | tr '[:upper:]' '[:lower:]')" "$HOME/.ssh")
platform_cmd=$(get_unified_config "rebuild_command" "nix-rebuild")
```

### Performance Monitoring Pattern

```bash
# Performance measurement
start_time=$(date +%s%N)

# Your operation here
source scripts/utils/config-loader.sh
load_all_configs
result=$(get_unified_config "complex_setting" "default")

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

echo "Configuration loading took: ${duration}ms"
```

## 📖 Related Documentation

- **[Configuration Guide](../CONFIGURATION-GUIDE.md)**: Complete configuration system guide
- **[Development Guide](../DEVELOPMENT.md)**: TDD development methodology
- **[API Reference](../API_REFERENCE.md)**: Complete API documentation
- **[Migration Guide](../MIGRATION-GUIDE.md)**: Upgrading from previous versions
- **[Architecture](../ARCHITECTURE.md)**: System design and architecture

## 🤝 Contributing Examples

To contribute new examples:

1. **Create the example**: Follow existing patterns and naming conventions
2. **Add documentation**: Include clear explanations and use cases
3. **Test thoroughly**: Ensure examples work across platforms
4. **Update this README**: Add your example to the appropriate section

### Example Template

```bash
#!/bin/bash
# Example: [Brief description]
# Use case: [When to use this pattern]
# Requirements: [Dependencies or prerequisites]

echo "🔧 [Example Name]"
echo "================"

# Implementation with error handling
# Clear comments explaining each step
# Expected output documentation
```

This examples directory provides a comprehensive learning resource for the Phase 4 dotfiles architecture. Each example is designed to be practical, well-documented, and immediately useful.
