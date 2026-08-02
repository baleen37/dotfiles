# Docker Program Module Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Home Manager `modules.programs.docker` module that pins the Docker context to OrbStack and enables Docker CLI zsh completion.

**Architecture:** A new `users/shared/programs/docker.nix` module following the existing `git.nix`/`ssh.nix` pattern (`options.modules.programs.<name>.enable` + `config = lib.mkIf cfg.enable`). Registered in `users/shared/home-manager.nix`. Unit test mirrors `tests/unit/ssh-program-test.nix`.

**Tech Stack:** Nix, Home Manager, zsh

---

### Task 1: Write the failing unit test

**Files:**

- Create: `tests/unit/docker-program-test.nix`

**Step 1: Write the failing test**

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

  hm = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/docker.nix
      {
        home = {
          username = "testuser";
          homeDirectory = "/home/testuser";
          stateVersion = "24.11";
        };
        modules.programs.docker.enable = true;
      }
    ];
  };

  zshInit = hm.config.programs.zsh.initContent;
  sessionVars = hm.config.home.sessionVariables;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "docker-program" [
    (helpers.assertTest "docker-program-no-deprecation-warnings" (
      hm.config.warnings == [ ]
    ) "Docker configuration should not use deprecated Home Manager options")

    (helpers.assertTest "docker-program-context-pinned" (
      sessionVars.DOCKER_CONTEXT == "orbstack"
    ) "DOCKER_CONTEXT should pin to orbstack so docker always targets OrbStack")

    (helpers.assertTest "docker-program-completion-enabled" (
      lib.hasInfix "docker completion zsh" zshInit
    ) "zsh init should source docker CLI completion")
  ];
}
```

**Step 2: Run test to verify it fails**

Run: `nix build '.#checks.aarch64-darwin.unit-docker-program' --impure`
Expected: FAIL — evaluation error "attribute 'docker' missing" in `modules.programs.docker.enable` and missing `docker.nix`.

**Step 3: Commit**

```bash
git add tests/unit/docker-program-test.nix
git commit -m "test: add docker program module tests"
```

---

### Task 2: Create the docker.nix module

**Files:**

- Create: `users/shared/programs/docker.nix`

**Step 1: Write the module**

```nix
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.docker;
in
{
  options.modules.programs.docker.enable = lib.mkEnableOption "Docker CLI context and completion";

  config = lib.mkIf cfg.enable {
    home.sessionVariables.DOCKER_CONTEXT = "orbstack";

    programs.zsh.initContent = lib.mkAfter ''
      # =============================================================================
      # Section: Docker CLI completion
      # =============================================================================
      if command -v docker >/dev/null 2>&1; then
        docker completion zsh 2>/dev/null | source /dev/stdin
      fi
    '';
  };
}
```

**Step 2: Commit**

```bash
git add users/shared/programs/docker.nix
git commit -m "feat: add docker program module"
```

---

### Task 3: Register module in home-manager.nix

**Files:**

- Modify: `users/shared/home-manager.nix`

**Step 1: Add import after `./programs/ssh.nix` (line 22)**

```nix
    ./programs/docker.nix
```

**Step 2: Add enable after `ssh.enable = true;` (line 56)**

```nix
    docker.enable = true;
```

**Step 3: Run test to verify all pass**

Run: `nix build '.#checks.aarch64-darwin.unit-docker-program' --impure`
Expected: PASS

**Step 4: Run full test-build**

Run: `export USER=$(whoami) && make test-build`
Expected: all assertions build

**Step 5: Format and commit**

Run: `make format`
Run: `git add users/shared/home-manager.nix`
Run: `git commit -m "feat(home-manager): enable docker program module"`

---

### Task 4: Verify and open PR

**Step 1: Final verification**

Run: `nix flake check --no-build --impure`
Expected: no evaluation errors

**Step 2: Push branch**

```bash
git push -u origin feat/docker
```

**Step 3: Open PR with auto-merge**

```bash
gh pr create --title "feat: docker program module" --body "Pins Docker context to OrbStack and enables Docker CLI completion. See docs/plans/2026-08-02-docker-program-design.md" --auto-merge
```

**Step 4: Verify merge**

Run: `gh pr status`
Expected: PR shows "auto-merge enabled"
