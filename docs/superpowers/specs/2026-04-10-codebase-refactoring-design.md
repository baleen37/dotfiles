# Codebase Refactoring: File Splitting & Deduplication

Date: 2026-04-10

## Goal

Reduce complexity, improve maintainability, and follow best practices by splitting large files and eliminating duplication. All changes must be backward-compatible — existing imports and test invocations continue to work without modification.

## Scope

1. `users/shared/darwin.nix` (338 lines)
2. `tests/lib/test-helpers.nix` (1,272 lines)
3. `users/shared/zsh/default.nix` (299 lines)
4. Cache config duplication (`flake.nix` vs `lib/cache-config.nix`)
5. E2E test boilerplate (`tests/e2e/`)

Out of scope: `p10k.zsh`, existing separated files (`darwin-test-helpers.nix`, `git-test-helpers.nix`, etc.).

## 1. darwin.nix Split

### Current State

`users/shared/darwin.nix` (338 lines) contains three distinct concerns:
- macOS system defaults (NSGlobalDomain, dock, finder, trackpad, spaces, loginwindow)
- Homebrew configuration (casks, brews, masApps, taps, onActivation)
- Activation scripts (keyboard input source, app cleanup)

### Target State

```
users/shared/
├── darwin.nix              # System defaults + system integration (~150 lines)
├── darwin-homebrew.nix     # Homebrew configuration (~50 lines)
├── darwin-scripts.nix      # Activation scripts (~100 lines)
```

### Design

**`darwin.nix`** retains:
- `imports = [ ./darwin-homebrew.nix ./darwin-scripts.nix ]`
- `system.defaults` (NSGlobalDomain, dock, finder, trackpad, spaces, CustomUserPreferences, loginwindow)
- System integration: `nixpkgs.config`, `nix.enable`, `programs.zsh.enable`, `system.keyboard`, `system.primaryUser`, `system.stateVersion`, `environment.systemPackages`, `documentation.enable`

**`darwin-homebrew.nix`** receives:
- `darwin-packages` list (dockutil)
- `homebrew-casks` list
- `homebrew` attrset (enable, casks, brews, onActivation, global, masApps, taps)

**`darwin-scripts.nix`** receives:
- `system.activationScripts.configureKeyboard`
- `system.activationScripts.cleanupMacOSApps`

### Backward Compatibility

External code imports only `darwin.nix`, which re-exports everything via `imports`. No changes needed outside this directory.

## 2. test-helpers.nix Split

### Current State

`tests/lib/test-helpers.nix` (1,272 lines) contains:
- Core assertions (~180 lines): assertTest, assertFileExists, assertHasAttr, assertContains, assertBuilds, testSuite, mkTest, assertTestWithDetails, assertTestWithDetailsVerbose, assertFileContent, getUserHomeDir, getTestUserHome, createTestUserConfig, runIfPlatform, runTestList
- macOS-specific assertions (~160 lines): assertNSGlobalDef(s), assertDockSetting(s), assertFinderSetting(s), assertTrackpadSetting(s), assertLoginWindowSetting, assertSettings, assertPatterns, assertAliases
- Property testing (~120 lines): propertyTest, multiParamPropertyTest, forAllCases
- Advanced assertions (~250 lines): assertPerformance, assertFileReadable, assertImportPresent, assertPluginSetup, bulk helpers

### Target State

```
tests/lib/
├── test-helpers.nix            # Core assertions + re-exports all (~180 lines + imports)
├── test-helpers-darwin.nix     # macOS assertion helpers (~160 lines)
├── test-helpers-property.nix   # Property testing helpers (~120 lines)
├── test-helpers-advanced.nix   # Advanced/bulk assertions (~250 lines)
```

### Design

**`test-helpers.nix`** retains core assertions (lines 46-178 approximately) and re-exports split files:

```nix
let
  darwinHelpers = import ./test-helpers-darwin.nix { inherit pkgs lib; assertTest = assertTest; testSuite = testSuite; };
  propertyHelpers = import ./test-helpers-property.nix { inherit pkgs lib; assertTest = assertTest; testSuite = testSuite; };
  advancedHelpers = import ./test-helpers-advanced.nix { inherit pkgs lib; assertTest = assertTest; testSuite = testSuite; };
in
rec {
  # ... core assertions ...
} // darwinHelpers // propertyHelpers // advancedHelpers
```

**`test-helpers-darwin.nix`** receives: assertNSGlobalDef, assertNSGlobalDefs, assertDockSetting, assertDockSettings, assertFinderSetting, assertFinderSettings, assertTrackpadSetting, assertTrackpadSettings, assertLoginWindowSetting, assertSettings, assertPatterns, assertAliases.

**`test-helpers-property.nix`** receives: propertyTest, multiParamPropertyTest, forAllCases.

**`test-helpers-advanced.nix`** receives: assertPerformance, assertFileReadable, assertImportPresent, assertPluginSetup, assertFileContent, assertTestWithDetailsVerbose, mkSimpleTest alias.

### Naming Convention

`test-helpers-*.nix` prefix (not `*-test-helpers.nix`) to clearly indicate these are sub-modules of `test-helpers.nix`, distinct from existing standalone helpers like `darwin-test-helpers.nix` and `git-test-helpers.nix`.

### Backward Compatibility

`test-helpers.nix` re-exports all split functions via `//` merge. Any code doing `helpers = import ../lib/test-helpers.nix { ... }; helpers.assertDockSetting ...` continues to work unchanged.

## 3. zsh/default.nix Refactoring

### Current State

`users/shared/zsh/default.nix` (299 lines) has `initContent` with inline shell code organized in comment sections. `claude-wrappers.nix` and `gw.nix` are already extracted using `${import ./file.nix}` pattern.

### Target State

```
users/shared/zsh/
├── default.nix           # Shell config skeleton (~100 lines)
├── claude-wrappers.nix   # (existing, unchanged)
├── gw.nix                # (existing, unchanged)
├── env.nix               # Environment variables & PATH (~40 lines)
├── ssh-agent.nix         # 1Password SSH agent + ssh wrapper (~60 lines)
└── functions.nix         # Utility functions: shell(), idea(), setup_ssh_agent_for_gui() (~50 lines)
```

### Design

Extract three sections from `initContent` using the existing `${import ./file.nix}` pattern:

**`env.nix`** receives: PATH exports (pnpm, npm, local, cargo, go, gem, homebrew), HISTIGNORE, LANG, LC_ALL, EDITOR, VISUAL, NPM_CONFIG_PREFIX, GITHUB_TOKEN.

**`ssh-agent.nix`** receives: `_setup_1password_agent()` function, its invocation, ssh-add key registration, `ssh()` wrapper function.

**`functions.nix`** receives: `shell()`, `idea()`, `setup_ssh_agent_for_gui()` functions and their invocations.

**`default.nix`** retains: programs.fzf, programs.direnv, direnv.toml config, programs.zsh skeleton (enable, autocd, dotDir, completionInit, shellAliases), initContent with nix-daemon init, .zshrc.local sourcing, and `${import ./...}` calls.

### Backward Compatibility

Pure file extraction using existing pattern. No interface changes.

## 4. Cache Config Sync Verification

### Current State

`flake.nix` lines 9-18 and `lib/cache-config.nix` lines 11-14 contain identical substituters and trusted-public-keys. `nixConfig` cannot import files (Nix language constraint), so duplication is unavoidable at code level.

### Design

Add a pre-commit hook that extracts and compares the values:

**`scripts/check-cache-sync.sh`**: Parses both files for substituters and trusted-public-keys, compares them, exits non-zero on mismatch.

**`.pre-commit-config.yaml`** addition:
```yaml
- repo: local
  hooks:
    - id: check-cache-sync
      name: Check cache config sync
      entry: scripts/check-cache-sync.sh
      language: script
      files: '(flake\.nix|lib/cache-config\.nix)'
```

## 5. E2E Test Boilerplate Reduction

### Current State

Each E2E test file repeats:
- `nixosTest` initialization (3-5 lines)
- Base VM node configuration (networking, virtualisation, user setup, sudo — ~15-20 lines)

`tests/e2e/helpers.nix` exists with utility functions but no test infrastructure factories.

### Design

Add two factory functions to `tests/e2e/helpers.nix`:

**`mkNixosTest`**: Wraps `pkgs.testers.nixosTest` fallback logic.

```nix
mkNixosTest = { pkgs, nixpkgs, system }:
  pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
    inherit system pkgs;
  });
```

**`mkBaseNode`**: Returns a standard VM node config that can be extended.

```nix
mkBaseNode = { hostname, extraConfig ? {} }: { config, pkgs, ... }: lib.mkMerge [
  {
    networking.hostName = hostname;
    networking.useDHCP = false;
    networking.firewall.enable = false;
    virtualisation.cores = 2;
    virtualisation.memorySize = 2048;
    users.users.testuser = {
      isNormalUser = true;
      password = "test";
      extraGroups = [ "wheel" ];
      shell = pkgs.bash;
    };
    security.sudo.wheelNeedsPassword = false;
  }
  extraConfig
];
```

Existing tests are updated to use these factories where the boilerplate matches. Tests with custom VM configurations keep their inline setup.

### Backward Compatibility

Additive change to helpers.nix. Existing tests are migrated but behavior is identical.

## Verification Plan

Each section verified independently:

1. **darwin.nix split**: `nix build '.#darwinConfigurations.macbook-pro.system' --impure --dry-run`
2. **test-helpers.nix split**: `make test` (all existing tests must pass)
3. **zsh split**: `nix build '.#homeConfigurations."jito.hello".activationPackage' --impure --dry-run`
4. **cache sync**: `bash scripts/check-cache-sync.sh` returns 0
5. **E2E helpers**: `nix eval --impure --expr '(import ./tests/e2e/helpers.nix { pkgs = import <nixpkgs> {}; platformSystem = { isDarwin = false; isLinux = true; }; }).mkBaseNode'` succeeds
6. **Full suite**: `make test-all`
