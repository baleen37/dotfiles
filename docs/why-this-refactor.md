# Makefile Refactor Rationale

## Why mitchellh style?
- Simplicity over complexity
- One purpose per target
- Minimal variable definitions
- Hostname-based configuration

## What we're removing:
- Complex VM testing fallbacks (test-vm, test-vm-quick, test-vm-fallback → test-vm)
- Over-engineered platform detection
- Performance monitoring features
- Multiple test categories → single test target

## What we're keeping:
- Multi-platform support (Darwin + Linux)
- VM management
- All core functionality
- Testing (simplified)
