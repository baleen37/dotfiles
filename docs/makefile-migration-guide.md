# Makefile Migration Guide

## What changed
- `make test`: Now runs simple test (build + test), no complex sequential logic
- Removed: `test-vm`, `test-vm-quick`, `test-vm-fallback` → simplified test approach
- Removed: `build-switch` → use `make switch`
- Removed: `test-unit`, `test-integration`, `test-e2e` → all handled by `make test`
- Simplified: Platform detection (mitchellh ifeq pattern)
- Added: Environment variables `NIXPKGS_ALLOW_UNFREE=1` to all commands
- Preserved: All VM management targets

## New commands (mitchellh style)
- `make build`: Build configuration with environment variables
- `make switch`: Build + apply configuration with environment variables
- `make test`: Simple test (build + test), no complex sequences
- `make cache`: Build and push to cache with environment variables
- `make format`: Format all files
- `make check`: Run flake check

## CI Changes
- Simplified from multiple test steps to single `make test`
- Removed complex VM testing logic in CI
- Uses `make cache` for cachix upload

## VM commands unchanged
- `make vm/bootstrap0`
- `make vm/bootstrap`
- `make vm/copy`
- `make vm/switch`
