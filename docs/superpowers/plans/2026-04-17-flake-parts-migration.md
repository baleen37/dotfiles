# flake-parts Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate from plain flake to flake-parts, splitting flake.nix (~296 lines) into focused modules with perSystem auto-platform handling.

**Architecture:** Add flake-parts input, extract overlays to `lib/overlays.nix`, create 6 flake-modules, rewrite flake.nix outputs to use `mkFlake`. mksystem.nix signature unchanged. CI cache key improved.

**Tech Stack:** Nix flakes, flake-parts, nix-darwin, home-manager, Cachix, GitHub Actions

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `flake.nix` | Rewrite | nixConfig + inputs + mkFlake call only |
| `lib/overlays.nix` | Create | Overlay list (extracted from flake.nix let block) |
| `flake-modules/darwin.nix` | Create | `flake.darwinConfigurations` |
| `flake-modules/nixos.nix` | Create | `flake.nixosConfigurations` |
| `flake-modules/home.nix` | Create | `flake.homeConfigurations` |
| `flake-modules/checks.nix` | Create | `perSystem: checks` |
| `flake-modules/dev-shells.nix` | Create | `perSystem: devShells + formatter` |
| `flake-modules/packages.nix` | Create | `perSystem: packages` + `flake.e2e-tests` |
| `.github/actions/setup-nix/action.yml` | Modify | Remove week rotation, add arch to cache key |
| `.github/workflows/ci.yml` | Verify | No changes needed (env vars are independent) |
| `Makefile` | Minor | No structural changes needed (already uses UNAME) |

**Unchanged files:** `lib/mksystem.nix`, `lib/cache-config.nix`, `lib/user-info.nix`, `scripts/check-cache-sync.sh`, `machines/`, `users/`, `tests/`, `.pre-commit-config.yaml`

---

### Task 1: Add flake-parts input

**Files:**
- Modify: `flake.nix:22-47` (inputs section)

- [ ] **Step 1: Add flake-parts to inputs**

In `flake.nix`, add after the `nixpkgs` input (line 23):

```nix
    # flake-parts - modular flake structure
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Lock the new input**

Run: `nix flake lock --update-input flake-parts`
Expected: flake.lock updated, no errors

- [ ] **Step 3: Verify existing flake still evaluates**

Run: `nix flake check --no-build --impure 2>&1 | head -20`
Expected: No errors (flake-parts is an input but not yet used in outputs)

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat: add flake-parts input for upcoming migration"
```

---

### Task 2: Extract overlays to lib/overlays.nix

**Files:**
- Create: `lib/overlays.nix`
- Modify: `flake.nix:60-82` (move overlays out, import from new file)

- [ ] **Step 1: Create lib/overlays.nix**

```nix
# lib/overlays.nix
# Centralized overlay definitions
# Extracted from flake.nix for reuse across flake-modules
{ inputs }:

[
  (final: prev: {
    # unstable alias - nixpkgs already tracks nixpkgs-unstable
    unstable = prev;

    # Claude Code - latest from flake input
    claude-code = inputs.claude-code.packages.${prev.system}.default;

    # direnv - fix cgo build issue by removing linkmode=external
    direnv = prev.direnv.overrideAttrs (oldAttrs: {
      env = oldAttrs.env // { CGO_ENABLED = "1"; };
      preBuild = ''
        # Remove -linkmode=external from the build flags
        substituteInPlace GNUmakefile \
          --replace-fail "-ldflags '-linkmode=external" "-ldflags '"
      '';
    });
  })
]
```

- [ ] **Step 2: Update flake.nix to import overlays**

Replace the inline overlays definition (lines 62-80) with:

```nix
      overlays = import ./lib/overlays.nix { inherit inputs; };
```

Keep `mkSystem = import ./lib/mksystem.nix { inherit inputs self overlays; };` unchanged.

- [ ] **Step 3: Verify flake still evaluates**

Run: `nix flake check --no-build --impure 2>&1 | head -20`
Expected: No errors

- [ ] **Step 4: Verify a Darwin build evaluates**

Run: `nix eval '.#darwinConfigurations.macbook-pro.system' --impure 2>&1 | head -5`
Expected: No evaluation errors

- [ ] **Step 5: Commit**

```bash
git add lib/overlays.nix flake.nix
git commit -m "refactor: extract overlays to lib/overlays.nix"
```

---

### Task 3: Create all flake-modules (non-breaking)

These files are created but NOT imported yet. The existing flake.nix continues to work.

**Files:**
- Create: `flake-modules/darwin.nix`
- Create: `flake-modules/nixos.nix`
- Create: `flake-modules/home.nix`
- Create: `flake-modules/checks.nix`
- Create: `flake-modules/dev-shells.nix`
- Create: `flake-modules/packages.nix`

- [ ] **Step 1: Create flake-modules/darwin.nix**

```nix
{ inputs, self, ... }:

let
  overlays = import ../lib/overlays.nix { inherit inputs; };
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  # Dynamic user resolution: get from environment variable, fallback to "baleen"
  # Requires --impure flag for nix build/switch commands
  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" && envUser != "root" then envUser else "baleen";
in
{
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    baleen-macbook = mkSystem "baleen-macbook" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    kakaostyle-jito = mkSystem "kakaostyle-jito" {
      system = "aarch64-darwin";
      user = "jito.hello";
      darwin = true;
    };
  };
}
```

- [ ] **Step 2: Create flake-modules/nixos.nix**

```nix
{ inputs, self, ... }:

let
  overlays = import ../lib/overlays.nix { inherit inputs; };
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" && envUser != "root" then envUser else "baleen";
in
{
  flake.nixosConfigurations = {
    vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      user = user;
    };

    vm-x86_64-utm = mkSystem "vm-x86_64-utm" {
      system = "x86_64-linux";
      user = user;
    };
  };
}
```

- [ ] **Step 3: Create flake-modules/home.nix**

```nix
{ inputs, self, ... }:

let
  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  overlays = import ../lib/overlays.nix { inherit inputs; };

  mkHomeConfig =
    userName:
    {
      system ? "aarch64-darwin",
      isDarwin ? true,
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs self isDarwin;
        currentSystemUser = userName;
      };
      modules = [
        ../users/shared/home-manager.nix
      ];
    };
in
{
  flake.homeConfigurations = {
    baleen = mkHomeConfig "baleen" { };
    "jito.hello" = mkHomeConfig "jito.hello" { };
    testuser = mkHomeConfig "testuser" { };
    "baleen-linux" = mkHomeConfig "baleen" {
      system = "x86_64-linux";
      isDarwin = false;
    };
  };
}
```

- [ ] **Step 4: Create flake-modules/checks.nix**

```nix
{ inputs, self, ... }:

{
  perSystem = { system, ... }: {
    checks = import ../tests { inherit system inputs self; };
  };
}
```

- [ ] **Step 5: Create flake-modules/dev-shells.nix**

```nix
{ ... }:

{
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-rfc-style;

    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Core Nix tooling
        nixfmt-rfc-style
        alejandra
        deadnix
        statix

        # Development utilities
        git
        jq
        yq

        # Testing tools
        bats

        # Optional: common utilities
        curl
        wget
      ];

      shellHook = ''
        echo "Dotfiles development environment loaded"
        echo "Available commands:"
        echo "  make format    - Format all files"
        echo "  make test      - Run tests"
        echo "  make build     - Build current platform"
        echo "  make switch    - Apply configuration changes"
      '';
    };
  };
}
```

- [ ] **Step 6: Create flake-modules/packages.nix**

```nix
{ inputs, self, ... }:

let
  nixpkgs = inputs.nixpkgs;
  nixos-generators = inputs.nixos-generators;
in
{
  perSystem = { system, pkgs, lib, ... }: {
    packages = lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      test-vm = nixos-generators.nixosGenerate {
        inherit system;
        format = "vm-nogui";
        modules = [
          ../machines/nixos/vm-aarch64-utm.nix
          {
            virtualisation.memorySize = 2048;
            virtualisation.cores = 2;
            virtualisation.diskSize = 10240;

            virtualisation.forwardPorts = [
              {
                from = "host";
                host.port = 2222;
                guest.port = 22;
              }
            ];

            services.openssh.enable = true;
            services.openssh.settings.PasswordAuthentication = true;
            virtualisation.docker.enable = true;
            networking.firewall.enable = false;

            users.users.testuser = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "docker"
              ];
              initialPassword = "test";
            };
            security.sudo.wheelNeedsPassword = false;
          }
        ];
      };
    };
  };

  # E2E tests (only for Linux platforms where VMs can run)
  flake.e2e-tests =
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in
    import ../tests/e2e {
      inherit
        pkgs
        lib
        system
        self
        inputs
        ;
    };
}
```

- [ ] **Step 7: Verify no syntax errors in any module**

Run each file through `nix-instantiate --parse`:

```bash
for f in flake-modules/*.nix; do
  echo "Parsing $f..."
  nix-instantiate --parse "$f" > /dev/null && echo "  OK" || echo "  FAIL"
done
```

Expected: All files parse successfully

- [ ] **Step 8: Commit**

```bash
git add flake-modules/
git commit -m "feat: create flake-modules for flake-parts migration (not yet wired)"
```

---

### Task 4: Rewrite flake.nix to use mkFlake

This is the big switch. The entire outputs section changes.

**Files:**
- Modify: `flake.nix` (complete outputs rewrite)

- [ ] **Step 1: Backup current flake.nix**

```bash
cp flake.nix flake.nix.bak
```

- [ ] **Step 2: Rewrite flake.nix**

Replace the entire file with:

```nix
{
  description = "baleen's dotfiles - Nix-based development environment";

  nixConfig = {
    # Flake evaluation caches - performance-first order
    # NOTE: These values are also defined in lib/cache-config.nix for system configuration.
    # flake.nix nixConfig cannot import files (must be a top-level attribute set),
    # so these are maintained separately. Keep in sync with lib/cache-config.nix.
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    accept-flake-config = true;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake-parts - modular flake structure
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Claude Code - latest stable
    claude-code.url = "github:sadjow/claude-code-nix/main";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./flake-modules/darwin.nix
        ./flake-modules/nixos.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
      ];
    };
}
```

- [ ] **Step 3: Verify flake evaluates**

Run: `nix flake check --no-build --impure 2>&1 | head -30`
Expected: No evaluation errors

- [ ] **Step 4: Verify darwinConfigurations output exists**

Run: `nix eval '.#darwinConfigurations' --impure --apply 'x: builtins.attrNames x' 2>&1`
Expected: `[ "baleen-macbook" "kakaostyle-jito" "macbook-pro" ]`

- [ ] **Step 5: Verify nixosConfigurations output exists**

Run: `nix eval '.#nixosConfigurations' --impure --apply 'x: builtins.attrNames x' 2>&1`
Expected: `[ "vm-aarch64-utm" "vm-x86_64-utm" ]`

- [ ] **Step 6: Verify homeConfigurations output exists**

Run: `nix eval '.#homeConfigurations' --impure --apply 'x: builtins.attrNames x' 2>&1`
Expected: `[ "baleen" "baleen-linux" "jito.hello" "testuser" ]`

- [ ] **Step 7: Verify checks output exists for current platform**

Run: `nix eval '.#checks.aarch64-darwin' --impure --apply 'x: builtins.attrNames x' 2>&1 | head -5`
Expected: List of check names including "smoke"

- [ ] **Step 8: Verify devShells output exists**

Run: `nix eval '.#devShells.aarch64-darwin' --impure --apply 'x: builtins.attrNames x' 2>&1`
Expected: `[ "default" ]`

- [ ] **Step 9: Verify formatter output exists**

Run: `nix eval '.#formatter.aarch64-darwin' --impure 2>&1 | head -3`
Expected: Path to nixfmt-rfc-style derivation

- [ ] **Step 10: Verify packages output for Linux**

Run: `nix eval '.#packages' --impure --apply 'x: builtins.attrNames x' 2>&1`
Expected: Should include linux systems

- [ ] **Step 11: Run full test suite**

Run: `make test`
Expected: Tests pass (validation mode on macOS)

- [ ] **Step 12: Run cache sync check**

Run: `scripts/check-cache-sync.sh`
Expected: "Cache config is in sync."

- [ ] **Step 13: Build Darwin configuration**

Run: `nix build '.#darwinConfigurations.macbook-pro.system' --impure --dry-run 2>&1 | tail -5`
Expected: No evaluation errors (dry-run shows what would be built)

- [ ] **Step 14: Remove backup and commit**

```bash
rm flake.nix.bak
git add flake.nix flake-modules/packages.nix
git commit -m "feat: migrate to flake-parts

Rewrite flake.nix outputs to use flake-parts mkFlake.
- flake.nix reduced from ~296 lines to ~70 lines
- 6 flake-modules split by responsibility
- perSystem replaces manual genAttrs for checks/devShells/formatter/packages
- darwinConfigurations/nixosConfigurations/homeConfigurations in flake section
- All existing outputs preserved with identical behavior"
```

---

### Task 5: CI cache key improvement

**Files:**
- Modify: `.github/actions/setup-nix/action.yml:36-82`

- [ ] **Step 1: Remove week-based rotation, add arch**

In `.github/actions/setup-nix/action.yml`, replace the week step and cache keys:

Remove the "Get week number" step (lines 36-39).

Update all cache key references from:
```yaml
key: nix-${{ runner.os }}-${{ hashFiles('**/flake.lock') }}-${{ steps.date.outputs.week }}-v3
restore-keys: |
  nix-${{ runner.os }}-
```

To:
```yaml
key: nix-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles('**/flake.lock') }}-v4
restore-keys: |
  nix-${{ runner.os }}-${{ runner.arch }}-
```

Apply this to both the "full mode" restore step (line 48), the "restore-only mode" step (line 60), and the "Save" step (line 82).

Also update the "Cache status check" step to remove the week reference.

- [ ] **Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/actions/setup-nix/action.yml'))"`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add .github/actions/setup-nix/action.yml
git commit -m "fix(ci): improve cache key with arch, remove week rotation

- Add runner.arch to cache key for ARM/x64 separation
- Remove week-based rotation (flake.lock hash handles invalidation)
- Bump cache key version to v4"
```

---

### Task 6: Final verification and cleanup

- [ ] **Step 1: Run full pre-commit suite**

Run: `pre-commit run --all-files`
Expected: All hooks pass

- [ ] **Step 2: Verify output parity**

Run a comprehensive check that all outputs from the old flake are present:

```bash
echo "=== Checking all flake outputs ==="
nix flake show --impure 2>&1 | head -40
```

Expected: Shows darwinConfigurations, nixosConfigurations, homeConfigurations, checks, devShells, formatter, packages, e2e-tests

- [ ] **Step 3: Count flake.nix lines**

Run: `wc -l flake.nix`
Expected: ~70 lines (down from ~296)

- [ ] **Step 4: Verify no leftover files**

Run: `ls flake.nix.bak 2>/dev/null && echo "CLEANUP NEEDED" || echo "Clean"`
Expected: "Clean"
