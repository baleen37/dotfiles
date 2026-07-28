# Herdr Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install Herdr through Home Manager, manage its minimal tmux-compatible configuration, and replace the older Homebrew binary on the current Mac.

**Architecture:** A focused Home Manager module owns both `pkgs.herdr` and `~/.config/herdr/config.toml`. An integration test evaluates the real module and runs Herdr's own config validator; the machine migration applies the Nix configuration before removing the Homebrew formula.

**Tech Stack:** Nix, Home Manager, nix-darwin, TOML, Herdr 0.7.5

## Global Constraints

- Use the pinned nixpkgs `pkgs.herdr`; do not add another flake input.
- Manage Herdr through `modules.programs.herdr.enable`.
- Set `Ctrl-a` as prefix, `prefix+d` as detach, and `prefix+|` / `prefix+minus` as pane splits.
- Keep all other Herdr defaults unchanged.
- Do not delete runtime state under `~/.config/herdr/`.
- Do not stop a running Herdr server because that would terminate pane processes.

---

### Task 1: Declarative Herdr module

**Files:**
- Create: `tests/integration/herdr-test.nix`
- Create: `users/shared/programs/herdr.nix`
- Modify: `users/shared/home-manager.nix`

**Interfaces:**
- Consumes: `pkgs.herdr`, Home Manager's `home.packages` and `xdg.configFile` options.
- Produces: `modules.programs.herdr.enable` and the managed `herdr/config.toml`.

- [ ] **Step 1: Write the failing integration test**

Create `tests/integration/herdr-test.nix`:

```nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/herdr.nix
      {
        modules.programs.herdr.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  config = homeConfig.config;
  herdrConfig = config.xdg.configFile."herdr/config.toml".text;
  herdrConfigFile = pkgs.writeText "herdr-config.toml" herdrConfig;
in
{
  herdr-package-installed = helpers.assertTest "herdr-package-installed" (
    builtins.elem pkgs.herdr config.home.packages
  ) "Herdr should be installed through Home Manager";

  herdr-config-contains-tmux-bindings = helpers.assertTest "herdr-config-contains-tmux-bindings" (
    lib.hasInfix ''prefix = "ctrl+a"'' herdrConfig
    && lib.hasInfix ''detach = "prefix+d"'' herdrConfig
    && lib.hasInfix ''split_vertical = "prefix+|"'' herdrConfig
    && lib.hasInfix ''split_horizontal = "prefix+minus"'' herdrConfig
  ) "Herdr should use the selected tmux-compatible bindings";

  herdr-config-valid = pkgs.runCommand "herdr-config-valid" { } ''
    export HOME="$TMPDIR"
    export HERDR_CONFIG_PATH=${herdrConfigFile}
    ${pkgs.herdr}/bin/herdr config check
    touch "$out"
  '';
}
```

- [ ] **Step 2: Run the new test and verify RED**

Run:

```bash
git add tests/integration/herdr-test.nix
nix build '.#checks.aarch64-darwin.integration-herdr' --impure --accept-flake-config --show-trace
```

Staging the new test makes it visible to flake source filtering. Expected:
FAIL because `users/shared/programs/herdr.nix` does not exist.

- [ ] **Step 3: Implement the minimal module**

Create `users/shared/programs/herdr.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.herdr;
in
{
  options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr terminal workspace manager";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/config.toml".text = ''
      onboarding = false

      [update]
      channel = "stable"
      version_check = false

      [keys]
      prefix = "ctrl+a"
      detach = "prefix+d"
      split_vertical = "prefix+|"
      split_horizontal = "prefix+minus"
    '';
  };
}
```

Modify `users/shared/home-manager.nix` by adding `./programs/herdr.nix` beside
`./programs/tmux.nix` and `herdr.enable = true;` beside `tmux.enable = true;`.

- [ ] **Step 4: Run focused verification and verify GREEN**

Run:

```bash
nix fmt
nix build '.#checks.aarch64-darwin.integration-herdr' --impure --accept-flake-config --show-trace
git diff --check
```

Expected: formatting completes, all three Herdr checks build, and the diff
check prints no errors.

- [ ] **Step 5: Commit the module**

```bash
git add tests/integration/herdr-test.nix users/shared/programs/herdr.nix users/shared/home-manager.nix
git commit -m "feat(herdr): add tmux-compatible home-manager setup"
```

### Task 2: Build, apply, and migrate the current machine

**Files:**
- Verify only: `flake.nix`, `flake.lock`
- Runtime target: `~/.config/herdr/config.toml`

**Interfaces:**
- Consumes: the Home Manager module from Task 1 and the `macbook-pro` nix-darwin configuration.
- Produces: a Nix-managed `herdr` command on the current Mac with no Homebrew shadow copy.

- [ ] **Step 1: Run repository-wide evaluation and the target build**

Run:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix flake check --no-build --impure --accept-flake-config --show-trace
NIXPKGS_ALLOW_UNFREE=1 nix build '.#darwinConfigurations.macbook-pro.system' --impure
```

Expected: both commands exit 0.

- [ ] **Step 2: Apply the nix-darwin configuration**

Run:

```bash
NIXPKGS_ALLOW_UNFREE=1 sudo -H /run/current-system/sw/bin/darwin-rebuild switch --flake '.#macbook-pro'
```

Expected: activation exits 0 and creates the Home Manager-managed Herdr config.

- [ ] **Step 3: Verify the Nix package before removing Homebrew**

Run:

```bash
test -x /etc/profiles/per-user/baleen/bin/herdr
/etc/profiles/per-user/baleen/bin/herdr --version
test -L "$HOME/.config/herdr/config.toml"
```

Expected: the executable exists, reports `herdr 0.7.5`, and the config is a
Home Manager symlink.

- [ ] **Step 4: Remove the inactive Homebrew formula**

First run:

```bash
/opt/homebrew/bin/herdr status --json
```

Continue only when `.server.running` is `false`. Then run:

```bash
brew uninstall herdr
```

Expected: Homebrew removes Herdr 0.7.4 without deleting
`~/.config/herdr/` runtime state. If the server is running, skip removal and
report the migration cleanup as blocked instead of stopping it.

- [ ] **Step 5: Run final runtime verification**

Run in a fresh login-shell environment:

```bash
zsh -lic 'command -v herdr && herdr --version && herdr config check'
brew list --versions herdr
```

Expected: `command -v` resolves to `/etc/profiles/per-user/baleen/bin/herdr`,
the version is `herdr 0.7.5`, config validation succeeds, and
`brew list --versions herdr` produces no package entry.
