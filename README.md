```bash
./install.sh
```

## Nix Configuration

This repository uses Nix flakes to manage the development environment and user configurations.

### Structure

- `flake.nix`: Defines the inputs (nixpkgs, nix-darwin, home-manager) and outputs (darwinConfigurations, packages, homeConfigurations).
- `modules/darwin/configuration.nix`: Contains system-level configurations for macOS using nix-darwin.
- `modules/darwin/home.nix`: Defines user-specific configurations using home-manager. It uses a `commonUserConfig` function to share common settings between users.
- `libraries/home-manager`: Shared home-manager modules.
- `libraries/nixpkgs`: Shared nixpkgs configurations.

### Hosts

The configuration supports multiple hosts:

- **baleen**: An aarch64-darwin (Apple Silicon macOS) machine.
- **jito**: An aarch64-darwin (Apple Silicon macOS) machine.

### Usage

To apply the configuration for a specific host, use the following command:

```bash
nixos-rebuild switch --flake .#<hostname>
```

For example, to apply the configuration for the `baleen` host:

```bash
nixos-rebuild switch --flake .#baleen
```

For home-manager configurations on Linux systems:

```bash
home-manager switch --flake .#<username>@<hostname>
```
