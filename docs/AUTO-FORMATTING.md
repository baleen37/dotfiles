# Auto-Formatting System

Enterprise-grade auto-formatting system for the dotfiles repository that automatically fixes lint issues instead of just reporting them.

## Overview

The auto-formatting system provides comprehensive code formatting across multiple languages and file types:

- **Nix files**: `nixpkgs-fmt` for consistent Nix formatting
- **Shell scripts**: `shfmt` for shell script formatting with 2-space indentation
- **YAML files**: `prettier` for YAML formatting with 120-character width
- **JSON files**: `jq` for JSON formatting with 2-space indentation
- **Markdown files**: `markdownlint` with auto-fix capabilities

## Quick Start

### Auto-format all files
```bash
make format
```

### Check if formatting is needed (CI mode)
```bash
make format-check
```

### Preview changes without applying them
```bash
make format-dry-run
```

## Available Make Targets

### General Formatting
- `make format` - Auto-format all files
- `make format-check` - Check if files need formatting (exits 1 if changes needed)
- `make format-dry-run` - Show what would be formatted without making changes

### Language-Specific Formatting
- `make format-nix` - Format only Nix files
- `make format-shell` - Format only shell scripts
- `make format-yaml` - Format only YAML files
- `make format-json` - Format only JSON files
- `make format-markdown` - Format only Markdown files

### Enhanced Pre-commit Integration
- `make lint-autofix` - Run linting with auto-fix enabled
- `make lint-install-autofix` - Install pre-commit hooks with auto-fix configuration

## Direct Script Usage

The auto-formatting system is powered by `/scripts/auto-format.sh`:

```bash
# Format all files
./scripts/auto-format.sh

# Format specific file types
./scripts/auto-format.sh nix shell yaml

# Dry run mode
./scripts/auto-format.sh --dry-run

# Verbose output
./scripts/auto-format.sh --verbose

# Check mode (for CI)
./scripts/auto-format.sh --check
```

## Configuration Files

### Prettier Configuration (`.prettierrc.yaml`)
Configures formatting for YAML, JSON, and Markdown files:
- 2-space indentation
- 120-character line width
- Preserves Markdown prose wrapping
- File-specific overrides for different formats

### Enhanced Pre-commit (`.pre-commit-config-autofix.yaml`)
Pre-commit configuration with auto-fix capabilities:
- Includes `shfmt` for shell script formatting
- Uses `prettier` for YAML/JSON auto-formatting
- Maintains all existing validation checks
- Enables `--fix` flags where available

## Tool Installation

The formatting tools are automatically available in the Nix development shell:

```bash
nix develop
# or
nix shell
```

Manual installation for individual tools:
```bash
# Install all formatting tools
nix shell nixpkgs#nixpkgs-fmt nixpkgs#shfmt nixpkgs#nodePackages.prettier nixpkgs#jq nixpkgs#nodePackages.markdownlint-cli

# Install specific tools
nix shell nixpkgs#nixpkgs-fmt    # Nix formatting
nix shell nixpkgs#shfmt          # Shell formatting
nix shell nixpkgs#nodePackages.prettier  # YAML/JSON/Markdown
```

## Workflow Integration

### Pre-commit Integration
Install auto-fix pre-commit hooks:
```bash
make lint-install-autofix
```

This replaces the standard linting-only hooks with auto-fixing variants.

### CI/CD Integration
Use check mode in CI pipelines:
```bash
make format-check
```

This will exit with code 1 if any files need formatting, perfect for CI validation.

### Development Workflow
1. **Before committing**: `make format`
2. **During development**: `make format-dry-run` to preview changes
3. **Language-specific work**: Use `make format-nix`, `make format-shell`, etc.

## Architecture

### Design Principles
1. **Auto-fix first**: Automatically fix issues instead of just reporting them
2. **Comprehensive coverage**: Support all major file types in the repository
3. **Safe operation**: Dry-run mode and check mode for validation
4. **Modular design**: Individual formatters can be run independently
5. **CI-friendly**: Check mode for validation without modification

### Tool Selection
- **nixpkgs-fmt**: Official Nix formatter, already in use
- **shfmt**: Industry-standard shell script formatter
- **prettier**: Widely-adopted formatter for YAML, JSON, and Markdown
- **jq**: Reliable JSON processor and formatter
- **markdownlint**: Comprehensive Markdown linting with auto-fix

### File Discovery
The system automatically discovers files to format:
- Uses `find` with appropriate patterns
- Excludes `.git` directories and other common ignore patterns
- Limits file discovery to prevent excessive processing
- Respects existing exclusion patterns from original configs

## Error Handling

### Missing Tools
If formatting tools are not available, the system:
- Warns about missing tools with installation instructions
- Continues processing other available formatters
- Returns appropriate exit codes for CI integration

### File Processing Errors
- Individual file failures don't stop the entire process
- Detailed error reporting with file-specific messages
- Graceful handling of invalid files (e.g., malformed JSON)

### Safe Operation
- Dry-run mode never modifies files
- Check mode validates without changes
- Verbose mode provides detailed operation logging

## Troubleshooting

### Common Issues

**Tool not found errors:**
```bash
# Enter development shell with all tools
nix develop

# Or install specific tools
nix shell nixpkgs#nixpkgs-fmt nixpkgs#shfmt
```

**Permission errors:**
```bash
# Ensure script is executable
chmod +x scripts/auto-format.sh
```

**Pre-commit hook conflicts:**
```bash
# Reinstall with auto-fix configuration
make lint-install-autofix
```

### Debug Mode
Use verbose flag for detailed operation logging:
```bash
make format ARGS="--verbose"
# or
./scripts/auto-format.sh --verbose
```

## Integration with Existing Tools

### Pre-commit Compatibility
The auto-formatting system maintains compatibility with existing pre-commit hooks:
- Original validation-only config: `.pre-commit-config.yaml`
- Enhanced auto-fix config: `.pre-commit-config-autofix.yaml`
- Easy switching between modes

### Editor Integration
Configure your editor to use the same formatting tools:
- **VSCode**: Install extensions for nixpkgs-fmt, shfmt, prettier
- **Vim**: Use appropriate plugins with the same tool configurations
- **Emacs**: Configure formatting modes to match the system

### Git Hooks
The system integrates with git workflows:
- Pre-commit hooks can auto-format before commits
- Pre-push hooks can validate formatting in CI mode
- Consistent formatting across all contributors

## Performance Considerations

### File Limits
- File discovery is limited to prevent excessive processing
- Large repositories benefit from language-specific formatting
- Parallel processing where supported by tools

### Optimization Tips
1. Use language-specific targets for focused work
2. Use dry-run mode for quick validation
3. Run formatting before committing to minimize CI overhead
4. Consider formatting only changed files in large repositories

## Future Enhancements

Planned improvements:
- **Parallel processing**: Format different file types concurrently
- **Git integration**: Format only changed files
- **Configuration files**: Support for tool-specific config files
- **Language detection**: Automatic file type detection
- **Performance monitoring**: Track formatting times and file counts