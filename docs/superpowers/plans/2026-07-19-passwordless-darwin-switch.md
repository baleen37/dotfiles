# Passwordless nix-darwin Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `make switch` to run without a sudo password only for the `jito.hello` user on `kakaostyle-jito`, while unrelated sudo commands and other hosts still require authentication.

**Architecture:** Replace the Darwin Makefile recipe's passwordless-incompatible `/usr/bin/env` sudo target with the root-managed absolute `darwin-rebuild` path. Add a host-conditional nix-darwin sudoers rule whose regular expression matches the complete switch argument string, and guard both halves of the contract with focused Nix tests.

**Tech Stack:** GNU Make, Nix, nix-darwin, sudoers 1.9.13p2

## Global Constraints

- Apply the NOPASSWD rule only when `currentSystemName == "kakaostyle-jito"`.
- Permit only `/run/current-system/sw/bin/darwin-rebuild` with arguments exactly `switch --flake .#kakaostyle-jito`.
- Do not grant NOPASSWD to `/usr/bin/env`, `make`, arbitrary `darwin-rebuild` arguments, or all sudo commands.
- Preserve existing Linux and Home Manager switch recipes.
- Validate the generated rule with the installed `visudo` before activation.

---

### Task 1: Add and apply the constrained passwordless switch

**Files:**

- Create: `tests/unit/darwin-sudo-test.nix`
- Modify: `tests/unit/makefile-switch-commands-test.nix`
- Modify: `Makefile`
- Modify: `machines/darwin/common.nix`

**Interfaces:**

- Consumes: `currentSystemName` and `currentSystemUser` special arguments passed by `lib/mksystem.nix`.
- Produces: one sudoers rule for `jito.hello` on `kakaostyle-jito` and a Makefile command that exactly matches it.

- [ ] **Step 1: Write failing host-isolation tests**

Create `tests/unit/darwin-sudo-test.nix`:

```nix
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  expectedRule =
    ''jito.hello ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$'';
  jitoSudo = self.darwinConfigurations.kakaostyle-jito.config.security.sudo.extraConfig;
  macbookSudo = self.darwinConfigurations.macbook-pro.config.security.sudo.extraConfig;
in
{
  platforms = [ "darwin" ];
  value = {
    kakaostyle-switch-is-passwordless =
      helpers.assertTest "kakaostyle switch is passwordless" (lib.hasInfix expectedRule jitoSudo)
        "kakaostyle-jito should allow only its exact darwin-rebuild switch command without a password";

    other-host-switch-needs-password =
      helpers.assertTest "other host switch needs password" (!lib.hasInfix "NOPASSWD" macbookSudo)
        "other Darwin hosts should not inherit the passwordless switch rule";

    no-unrestricted-passwordless-sudo =
      helpers.assertTest "no unrestricted passwordless sudo" (!lib.hasInfix "NOPASSWD: ALL" jitoSudo)
        "kakaostyle-jito should not allow unrestricted passwordless sudo";
  };
}
```

- [ ] **Step 2: Add failing Makefile contract assertions**

Append these checks before the final success message in `tests/unit/makefile-switch-commands-test.nix`:

```bash
    # Test 6: Darwin switch must invoke the root-managed binary directly.
    if grep -q '^DARWIN_REBUILD := /run/current/system/sw/bin/darwin-rebuild$' "$makefileSource" &&
       sed -n '/^switch:/,/^else/{p}' "$makefileSource" | grep -q 'sudo -H $(DARWIN_REBUILD) switch --flake ".#$(NIXNAME)"'; then
      echo "✅ Test 6 PASS: Darwin switch matches the sudoers allowlist"
    else
      echo "❌ Test 6 FAIL: Darwin switch must use the allowlisted absolute darwin-rebuild path"
      exit 1
    fi

    # Test 7: Darwin switch must not authorize sudo through env.
    if sed -n '/^switch:/,/^else/{p}' "$makefileSource" | grep -q 'sudo -H env'; then
      echo "❌ Test 7 FAIL: Darwin switch must not sudo /usr/bin/env"
      exit 1
    else
      echo "✅ Test 7 PASS: Darwin switch does not sudo /usr/bin/env"
    fi
```

- [ ] **Step 3: Run focused tests and verify RED**

Run:

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
  '.#checks.aarch64-darwin.unit-darwin-sudo-kakaostyle-switch-is-passwordless'
nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
  '.#checks.aarch64-darwin.unit-makefile-switch-commands'
```

Expected: the first build fails because the sudoers rule is absent; the second fails at Test 6 because `DARWIN_REBUILD` is absent.

- [ ] **Step 4: Implement the exact Makefile command**

Add near `NIX` in `Makefile`:

```make
DARWIN_REBUILD := /run/current-system/sw/bin/darwin-rebuild
```

Replace only the Darwin switch recipe with:

```make
	$(NIX_ENV) sudo -H $(DARWIN_REBUILD) switch --flake ".#$(NIXNAME)"
```

- [ ] **Step 5: Implement the host-conditional sudoers rule**

Accept `currentSystemName` and `currentSystemUser` in `machines/darwin/common.nix`, then add:

```nix
  security.sudo.extraConfig = lib.mkIf (currentSystemName == "kakaostyle-jito") ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$
  '';
```

- [ ] **Step 6: Run focused tests and syntax verification**

Run the two focused builds from Step 3. Then run:

```bash
/usr/sbin/visudo -cf <(nix --extra-experimental-features 'nix-command flakes' eval --raw \
  '.#darwinConfigurations.kakaostyle-jito.config.security.sudo.extraConfig')
nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
  '.#checks.aarch64-darwin.treefmt'
git diff --check
```

Expected: all commands exit 0 and `visudo` prints `parsed OK`.

- [ ] **Step 7: Commit the verified implementation**

```bash
git add Makefile machines/darwin/common.nix tests/unit/darwin-sudo-test.nix \
  tests/unit/makefile-switch-commands-test.nix \
  docs/superpowers/plans/2026-07-19-passwordless-darwin-switch.md
git commit -m "feat(darwin): allow passwordless system switch"
```

- [ ] **Step 8: Activate and verify the live sudo boundary**

Run `make switch` once with existing authentication to install the rule. Then invalidate any cached credential and verify:

```bash
sudo -k
make switch
sudo -n true
sudo -n /run/current-system/sw/bin/darwin-rebuild build --flake '.#kakaostyle-jito'
```

Expected: `make switch` succeeds without prompting; both negative `sudo -n` commands fail with `a password is required`.

- [ ] **Step 9: Publish and merge**

Run the repository create-PR workflow, enable squash auto-merge only after local and live verification pass, and wait for all CI checks plus the merge event.
