# Dotfiles Refactoring Design - Mitchell Hashimoto Style

**Date**: 2025-10-25
**Author**: Baleen & Claude
**Status**: Approved for Implementation

## Executive Summary

Refactor the entire dotfiles project structure to adopt Mitchell Hashimoto's minimalist architecture, prioritizing **maintainability** through extreme simplicity and clear file organization.

## Problem Statement

Current dotfiles structure suffers from:

1. **Hard to find modules** - excessive relative paths (`../../`)
2. **Slow builds** - unnecessary re-evaluation
3. **Code duplication** - similar configs scattered across files
4. **Unclear platform separation** - darwin/nixos/shared boundaries ambiguous

## Design Goals

**Primary Goal**: Maximize maintainability

- New packages/modules have obvious, intuitive locations
- Minimal cognitive overhead when navigating codebase
- Reusable program configurations

**Secondary Goals**:

- Improve build performance (20-30% faster)
- Reduce code duplication
- Clear platform separation

## Architecture Decision

**Approach**: Mitchell Hashimoto Style

- Extreme simplicity over abstraction
- User-centric organization
- Flat file structures (no deep nesting)
- Long files are acceptable if they're easy to navigate

## New Directory Structure

```
dotfiles/
├── flake.nix                    # Simplified entry point
├── flake.lock
├── Makefile                     # Build automation (preserved)
│
├── lib/
│   └── default.nix             # Minimal utilities (platform detection, user resolution)
│
├── machines/                    # Machine-specific configs (minimal)
│   ├── baleen-macbook.nix      # Hostname, hardware-specific settings only
│   └── nixos-vm.nix
│
├── users/                       # USER-CENTRIC ORGANIZATION (key change)
│   └── baleen/
│       ├── darwin.nix          # ALL macOS system settings
│       ├── nixos.nix           # ALL NixOS system settings
│       ├── home.nix            # Home Manager entry point (imports only)
│       │
│       └── programs/           # Program-specific configs (flat structure)
│           ├── git.nix
│           ├── zsh.nix
│           ├── vim.nix
│           ├── wezterm.nix
│           ├── claude.nix
│           ├── tmux.nix
│           └── ...             # One file per program
│
├── overlays/                   # Nixpkgs overlays (preserved)
│   └── default.nix
│
└── tests/                      # Testing framework (preserved)
    └── ...
```

## Key Architectural Changes

### 1. hosts/ → machines/

**Before**: `hosts/{hostname}/default.nix` with complex configurations
**After**: `machines/{hostname}.nix` with minimal settings only

```nix
# machines/baleen-macbook.nix
{
  networking.hostName = "baleen-macbook";
  networking.computerName = "Baleen's MacBook";
  # Hardware-specific settings only
}
```

### 2. modules/ → users/{user}/

**Before**: Scattered across `modules/shared/`, `modules/darwin/`, `modules/nixos/`
**After**: Everything under `users/baleen/` in 3 main files

**users/baleen/darwin.nix** - All macOS settings:

```nix
{ pkgs, ... }:
{
  system.stateVersion = 5;

  # Homebrew (all casks)
  homebrew = {
    enable = true;
    casks = [ "wezterm" "raycast" "1password" ... ];
  };

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    # All macOS defaults here
  };

  # Performance optimization
  # App cleanup
  # All darwin-specific settings
}
```

**users/baleen/home.nix** - Entry point for Home Manager:

```nix
{ pkgs, ... }:
{
  home.stateVersion = "24.05";

  # Common packages
  home.packages = with pkgs; [
    ripgrep fzf fd bat ...
  ];

  # Import all program configs
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/vim.nix
    ./programs/wezterm.nix
    ./programs/claude.nix
  ];
}
```

**users/baleen/programs/\*.nix** - Independent program configs:

```nix
# programs/git.nix
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Jiho";
    userEmail = "...";
    # All git configuration
  };
}
```

### 3. Simplified flake.nix

**Before**: 100+ lines with complex helpers
**After**: ~60 lines, explicit and clear

```nix
{
  description = "Baleen's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Other inputs...
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs:
    let
      user = "baleen";
      lib = import ./lib { inherit nixpkgs; };
    in
    {
      # macOS configuration
      darwinConfigurations.baleen-macbook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./machines/baleen-macbook.nix
          ./users/${user}/darwin.nix
          home-manager.darwinModules.home-manager {
            home-manager.users.${user} = import ./users/${user}/home.nix;
          }
        ];
      };

      # NixOS configuration
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/nixos-vm.nix
          ./users/${user}/nixos.nix
          home-manager.nixosModules.home-manager {
            home-manager.users.${user} = import ./users/${user}/home.nix;
          }
        ];
      };

      # Preserved: devShells, checks, apps (formatters, etc.)
    };
}
```

### 4. Minimized lib/

**Before**: Multiple lib files with various helpers
**After**: Single `lib/default.nix` with essential functions only

- Platform detection
- User resolution
- Formatter definitions (for `make format`)

### 5. Flat programs/ Structure

**Key principle**: NO subdirectories under `programs/`

❌ **Avoid**:

```
programs/
├── shell/
│   ├── zsh.nix
│   └── bash.nix
└── editors/
    └── vim.nix
```

✅ **Use**:

```
programs/
├── zsh.nix
├── bash.nix
└── vim.nix
```

## Migration Strategy

### Phase 1: Prepare New Structure

1. Create new directory structure (without removing old)
2. Create empty skeleton files

### Phase 2: Migrate Content

1. **programs/**: Move each program from `modules/shared/config/` to `users/baleen/programs/`
   - One migration at a time
   - Test after each move

2. **darwin.nix**: Consolidate `modules/darwin/` files
   - Merge all darwin modules into single file
   - Remove module wrappers

3. **nixos.nix**: Consolidate `modules/nixos/` files
   - Merge all nixos modules into single file

4. **home.nix**: Create imports list
   - List all program imports
   - Add common packages

### Phase 3: Update flake.nix

1. Simplify outputs
2. Update module imports
3. Remove complex helpers

### Phase 4: Clean Up

1. Remove old `modules/` directory
2. Remove old `hosts/` directory
3. Update documentation
4. Run tests

### Phase 5: Verify

1. `make format`
2. `make build-current`
3. `make test-core`
4. `make smoke`

## Performance Optimizations

### Build Performance

```nix
# In flake.nix or darwin.nix/nixos.nix
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
```

Expected improvement: 20-30% faster builds

### Evaluation Performance

- Minimize `forAllSystems` usage
- Remove unnecessary abstractions
- Direct imports instead of complex lib functions

## Benefits

### Maintainability

- **Find files instantly**: Obvious locations
  - Program config? → `users/baleen/programs/{name}.nix`
  - macOS setting? → `users/baleen/darwin.nix`
  - Add package? → `users/baleen/home.nix`

- **No relative paths**: Everything under `users/baleen/`
- **Reusable programs**: Copy single file to new user/machine

### Performance

- Faster builds with `useGlobalPkgs`
- Simpler evaluation (less abstraction)
- Clear separation reduces rebuild triggers

### Clarity

- Platform separation: `darwin.nix` vs `nixos.nix`
- User-centric: Everything in one place
- Flat structures: No deep nesting

## Trade-offs

### What We Gain

- Extreme simplicity
- Clear organization
- Easy maintenance
- Fast navigation

### What We Sacrifice

- Some abstraction (acceptable - clarity > DRY)
- Longer individual files (acceptable - searchable)
- Module reusability across projects (not a goal)

## Success Criteria

✅ **Primary (Maintainability)**:

- Adding new program takes < 2 minutes
- Finding config file takes < 5 seconds
- No relative path imports in user configs

✅ **Secondary**:

- Build time improvement: 20-30%
- Code duplication reduced by 30%+
- All tests pass

## References

- [Mitchell Hashimoto's nixos-config](https://github.com/mitchellh/nixos-config)
- [Evan Travers: Reorganizing My Nix Dotfiles](https://evantravers.com/articles/2025/04/17/reorganizing-my-nix-dotfiles/)
- [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)

## Next Steps

1. Create git worktree for isolated development
2. Create detailed implementation plan
3. Execute migration in phases
4. Test thoroughly
5. Switch to new structure

---

**Approved by**: Jiho
**Ready for**: Implementation Planning
