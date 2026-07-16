# Starship Username Prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Always show the dynamic username at the start of the Starship prompt and remove the Nix shell indicator.

**Architecture:** Keep the existing custom Starship format and use its built-in `username` module. Change only the focused Starship module and its unit test; preserve all other prompt modules and styles.

**Tech Stack:** Nix, Home Manager, Starship, repository Nix checks

## Global Constraints

- The username is always visible without a hostname.
- The prompt does not show the Nix shell indicator.
- The username remains dynamic across users and machines.
- Directory, Git, Python, command-duration, and character behavior stays unchanged.

---

### Task 1: Compact Username Prompt

**Files:**

- Modify: `tests/unit/starship-test.nix`
- Modify: `users/shared/programs/starship.nix`

**Interfaces:**

- Consumes: Home Manager `programs.starship.settings` and Starship's built-in `username` module.
- Produces: A custom format beginning with `$username`, no `$nix_shell`, and `username.show_always = true`.

- [x] **Step 1: Write the failing tests**

In `tests/unit/starship-test.nix`, require `$username`, stop requiring `$nix_shell`, and add direct assertions for the absent Nix module and username settings:

```nix
requiredModules = [
  "$username"
  "$directory"
  "$git_branch"
  "$git_status"
  "$python"
];

(helpers.assertTest "starship-format-excludes-nix-shell" (
  !(lib.hasInfix "$nix_shell" starshipConfig.programs.starship.settings.format)
) "Starship format should not include the nix_shell module")
(helpers.assertTest "starship-username-enabled" (
  starshipConfig.programs.starship.settings.username.disabled == false
) "Starship username module should be enabled")
(helpers.assertTest "starship-username-always-visible" (
  starshipConfig.programs.starship.settings.username.show_always == true
) "Starship username should always be visible")
(helpers.assertTest "starship-username-format" (
  starshipConfig.programs.starship.settings.username.format == "[$user]($style) "
) "Starship username should have a compact format")
```

Remove the old assertions that username is disabled and the Nix shell symbol is `nix`.

- [x] **Step 2: Run the focused test to verify RED**

Run:

```bash
nix build '.#checks.aarch64-darwin.unit-starship' --impure --accept-flake-config --print-build-logs
```

Expected: FAIL because `$username` is absent, `$nix_shell` remains present, and the username module is disabled.

- [x] **Step 3: Implement the minimal Starship settings**

In `users/shared/programs/starship.nix`, make the custom format begin with `$username`, remove `$nix_shell`, replace `username.disabled = true` with the compact always-visible username settings, and remove the unused `nix_shell` block:

```nix
format = lib.concatStrings [
  "$username"
  "$directory"
  "$git_branch"
  "$git_status"
  "$python"
  "$character"
];

username = {
  disabled = false;
  show_always = true;
  format = "[$user]($style) ";
};
```

- [x] **Step 4: Run the focused test to verify GREEN**

Run:

```bash
nix build '.#checks.aarch64-darwin.unit-starship' --impure --accept-flake-config --print-build-logs
```

Expected: PASS.

- [x] **Step 5: Verify formatting and inspect the final diff**

Run:

```bash
nix fmt -- --fail-on-change
git diff --check
git diff -- users/shared/programs/starship.nix tests/unit/starship-test.nix
```

Expected: formatter exits 0, `git diff --check` exits 0, and every code diff line maps to the requested prompt behavior.

- [x] **Step 6: Commit the implementation**

```bash
git add docs/superpowers/plans/2026-07-16-starship-username.md users/shared/programs/starship.nix tests/unit/starship-test.nix
git commit -m "feat(starship): show username in compact prompt"
```
