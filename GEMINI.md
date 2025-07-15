# GEMINI.md (Project-Specific Context for dotfiles)

> **Last Updated:** 2025-07-15
> **Version:** 2.2
> **For:** Claude Code (`claude.ai/code`) working on Jito's `dotfiles` repository.

**This document provides project-specific rules and context that supplement the generic agent guidelines in `modules/shared/config/claude/CLAUDE.md`.**

## 1. Core Project Technologies

This project uses **Nix**, **nix-darwin**, and **Home Manager** to manage system configurations. You MUST be familiar with these technologies and their specific workflows.

- **Nix Flakes**: The project is managed as a Nix Flake. All dependencies and configurations are defined in `flake.nix`.
- **nix-darwin**: Used for managing macOS configurations. Changes are applied via `darwin-rebuild switch`.
- **Home Manager**: Used for managing user-level packages and dotfiles.

## 2. Critical Execution Constraints

**🚨 You are operating in a constrained environment with no direct `sudo` access.**

### `build-switch` Workflow

The primary command for applying changes is `nix run #build-switch`. This is a custom script that handles the complexity of `darwin-rebuild switch`.

- **Sudo Requirement**: `darwin-rebuild switch` requires `sudo`. The `build-switch` script is designed to handle this, but you cannot run it directly if it prompts for a password.
- **Your Role**: Your task is to **prepare** the configuration for the user (`Jito`) to apply. You do this by ensuring the Nix configuration is valid and free of errors.
- **NEVER attempt to run `darwin-rebuild switch` or `build-switch` directly.** Instead, your final output should be a confirmation that the configuration is ready, and you should instruct the user to run the command.

### Troubleshooting `build-switch` Failures

If a build fails, you MUST use a code-first analysis approach:

1.  **Check the Build Log**: `nix build .#darwinConfigurations.aarch64-darwin.system --show-trace`
2.  **Check the Flake**: `nix flake check --show-trace`
3.  **Validate Project Configs**: Run the local validation script: `./scripts/check-config`
4.  **Analyze Script Logic**: Read the contents of `scripts/build-switch-common.sh` to understand the build process.

Based on your analysis, identify the root cause and fix the underlying Nix configuration. **DO NOT** suggest workarounds.

## 3. Project-Specific Conventions

- **User**: The primary user and administrator of this system is **Jito**.
- **File Structure**: This repository has a specific modular structure. Before adding new files, analyze the existing layout in `modules/`, `lib/`, and `hosts/` to ensure your changes are consistent.
- **Configuration Files**: All core logic is written in `.nix` files. YAML files in `config/` are for data, not logic.
- **Testing**: This project has a suite of shell scripts for testing in the `tests/` directory. For example, `./scripts/test-build-switch-health` is used to diagnose issues with the build process.

## 4. Key File Cheatsheet

- **`flake.nix`**: The heart of the project. Defines all inputs, outputs, and dependencies.
- **`GEMINI.md` (this file)**: Your primary source for project-specific rules.
- **`modules/shared/config/claude/CLAUDE.md`**: The source for your generic operational guidelines.
- **`scripts/build-switch-common.sh`**: The core logic for applying system changes.
- **`scripts/check-config`**: A critical script for validating configuration before attempting a build.

## 5. Historical Context & Known Issues

- **Issue #367**: A past issue related to `build-switch` failures was resolved by improving the health-check scripts. Be aware of this history when troubleshooting.
- **macOS Privilege Limitations**: Certain macOS settings cannot be managed directly via `nix-darwin` and require `activationScripts`. See `lib/keyboard-input-settings.nix` for an example of using a Python script to modify `plist` files.

By adhering to these project-specific guidelines, you will be able to assist effectively without overstepping the boundaries of your execution environment.
