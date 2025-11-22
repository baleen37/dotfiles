# WSL Support Release

## New Features
- Native WSL2 support with Home Manager integration
- Automatic WSL environment detection in Makefile
- WSL-specific machine configuration optimized for Windows interop
- Comprehensive testing suite for WSL environments

## Usage
```bash
export USER=nixos
make switch
```

## Limitations
- WSL+NixOS uses standard `nixos-rebuild switch` (it's a real NixOS environment!)
- Some systemd services may be limited by WSL virtualization
- Windows-specific hardware features not available

## Documentation
See `docs/wsl-setup-guide.md` for detailed setup instructions.