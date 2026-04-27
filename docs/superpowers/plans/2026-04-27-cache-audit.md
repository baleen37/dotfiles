# Cache Audit & Hit-rate Visibility — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Nix unit test that detects substituter / public-key drift across all four config locations, and add a CI Job Summary cache hit-rate report using standard Nix commands.

**Architecture:**
- (1) `tests/unit/cache-config-test.nix` — pure-eval unit test that reads `lib/cache-config.nix` and verifies all entries appear in `flake.nix`, `.github/workflows/ci.yml`, and `.github/actions/setup-nix/action.yml`, plus URL/key format checks.
- (2) `.github/workflows/ci.yml` — minor edit to existing "Upload to Cachix" step (add `--out-link result`) plus a new "Cache hit-rate report" step that runs `nix path-info -r` and `nix copy --dry-run` and writes a table to `$GITHUB_STEP_SUMMARY`.

The existing `scripts/check-cache-sync.sh` (pre-commit) only checks `flake.nix ↔ lib/cache-config.nix`. The new Nix test extends the same idea to `ci.yml` and `setup-nix/action.yml`, so the two layers are complementary, not duplicate.

**Tech Stack:** Nix (`builtins.readFile`, `lib.hasInfix`, `builtins.match`), GitHub Actions YAML, bash.

**Spec:** `docs/superpowers/specs/2026-04-27-cache-audit-design.md`

---

## File Structure

| Action | Path | Responsibility |
|---|---|---|
| Create | `tests/unit/cache-config-test.nix` | Drift detection across 4 config locations + URL/key format validation |
| Modify | `.github/workflows/ci.yml` | (a) Add `--out-link result` to the existing `nix build` in "Upload to Cachix"; (b) add new "Cache hit-rate report" step before that |

No other files change. No new scripts. No changes to `lib/cache-config.nix`.

---

## Task 1: Add cache-config consistency test

**Files:**
- Create: `tests/unit/cache-config-test.nix`

The test is auto-discovered by `tests/default.nix` (any `tests/unit/*-test.nix`), so no other file needs editing.

The test must:
1. Read `lib/cache-config.nix` (the single source of truth).
2. Read `flake.nix`, `.github/workflows/ci.yml`, `.github/actions/setup-nix/action.yml` as raw text.
3. Verify every substituter URL and every public key from `cache-config.nix` is a substring of all three files.
4. Verify every substituter URL starts with `https://`.
5. Verify every public key matches `<name>-<digit>+:<base64-43chars>=`.

- [ ] **Step 1: Write the test file**

Create `tests/unit/cache-config-test.nix`:

```nix
# Verifies cache-config.nix entries appear consistently in all four locations
# and that URLs/public-keys have valid format.
#
# This complements scripts/check-cache-sync.sh (which only covers
# flake.nix <-> lib/cache-config.nix) by also covering CI yaml.
{
  pkgs,
  lib,
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  cacheConfig = import ../../lib/cache-config.nix;

  flakeNix = builtins.readFile ../../flake.nix;
  ciYml = builtins.readFile ../../.github/workflows/ci.yml;
  setupNixYml = builtins.readFile ../../.github/actions/setup-nix/action.yml;

  containsAll = haystack: needles: lib.all (n: lib.hasInfix n haystack) needles;

  urlOk = url: lib.hasPrefix "https://" url;

  # Cachix public key format: <name>-<digit>+:<43 base64 chars>=
  # Examples:
  #   baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k=
  #   cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  keyOk =
    key: builtins.match "[a-zA-Z0-9._-]+-[0-9]+:[A-Za-z0-9+/]{43}=" key != null;

  subs = cacheConfig.substituters;
  keys = cacheConfig.trusted-public-keys;
in
{
  flakeNixHasAllSubstituters =
    helpers.assertTest "flake-nix-has-all-substituters" (containsAll flakeNix subs)
      "flake.nix nixConfig must contain every substituter from lib/cache-config.nix";

  flakeNixHasAllKeys =
    helpers.assertTest "flake-nix-has-all-keys" (containsAll flakeNix keys)
      "flake.nix nixConfig must contain every trusted-public-key from lib/cache-config.nix";

  ciYmlHasAllSubstituters =
    helpers.assertTest "ci-yml-has-all-substituters" (containsAll ciYml subs)
      ".github/workflows/ci.yml NIX_CONFIG must contain every substituter from lib/cache-config.nix";

  ciYmlHasAllKeys =
    helpers.assertTest "ci-yml-has-all-keys" (containsAll ciYml keys)
      ".github/workflows/ci.yml NIX_CONFIG must contain every trusted-public-key from lib/cache-config.nix";

  setupNixHasAllSubstituters =
    helpers.assertTest "setup-nix-has-all-substituters"
      (containsAll setupNixYml subs)
      ".github/actions/setup-nix/action.yml extra-conf must contain every substituter from lib/cache-config.nix";

  setupNixHasAllKeys =
    helpers.assertTest "setup-nix-has-all-keys" (containsAll setupNixYml keys)
      ".github/actions/setup-nix/action.yml extra-conf must contain every trusted-public-key from lib/cache-config.nix";

  allUrlsAreHttps =
    helpers.assertTest "substituter-urls-are-https" (lib.all urlOk subs)
      "every substituter URL must start with https://";

  allKeysHaveValidFormat =
    helpers.assertTest "public-keys-have-valid-format" (lib.all keyOk keys)
      "every trusted-public-key must match <name>-<digit>:<43-base64>=";
}
```

- [ ] **Step 2: Run the test to verify all assertions PASS**

Run:

```bash
export USER=$(whoami)
nix flake check --impure --no-build 2>&1 | grep -i cache-config
```

Then build the specific check to confirm it passes:

```bash
export USER=$(whoami)
SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')
nix build ".#checks.${SYSTEM}.unit-cache-config" --impure --print-build-logs
```

Expected: build succeeds, log shows `✅ <name>: PASS` for each of the 8 assertions. No FAIL lines.

If `unit-cache-config` is not the exact attr name produced by auto-discovery, list available checks first:

```bash
nix flake show --impure 2>&1 | grep -i cache-config
```

and use whatever name appears (it will be derived from the filename `cache-config-test.nix` per the discovery rule in `tests/default.nix`).

- [ ] **Step 3: Verify the test detects drift (negative test, manual)**

Temporarily modify `lib/cache-config.nix` to remove one substituter line (e.g. comment out `https://nix-community.cachix.org`).

Re-run the test:

```bash
export USER=$(whoami)
SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')
nix build ".#checks.${SYSTEM}.unit-cache-config" --impure --print-build-logs 2>&1 | tail -20
```

Expected: build FAILS. Output contains `❌ flake-nix-has-all-substituters: FAIL` AND `❌ ci-yml-has-all-substituters: FAIL` AND `❌ setup-nix-has-all-substituters: FAIL` (because all three files still have the URL but cache-config.nix no longer asserts it — wait, the direction is the opposite).

**Direction check:** the test iterates `subs = cacheConfig.substituters` and asserts each is in the file. If we *remove* a substituter from `cache-config.nix`, the test still passes (fewer needles). To trigger drift detection, we must instead *add* a substituter to `cache-config.nix` that is not in the other files.

Revised negative test: add a fake substituter to `lib/cache-config.nix`:

```nix
substituters = [
  "https://baleen-nix.cachix.org"
  "https://nix-community.cachix.org"
  "https://cache.nixos.org/"
  "https://drift-test.example.com"   # <-- ADD THIS LINE
];
```

Re-run the build. Expected:

```
❌ flake-nix-has-all-substituters: FAIL
❌ ci-yml-has-all-substituters: FAIL
❌ setup-nix-has-all-substituters: FAIL
❌ substituter-urls-are-https: PASS  (URL is https, so this still passes)
```

(The first three fail because the new URL is in `cache-config.nix` but not in the other files.)

Revert `lib/cache-config.nix`:

```bash
git checkout -- lib/cache-config.nix
```

Re-run the build to confirm it passes again:

```bash
nix build ".#checks.${SYSTEM}.unit-cache-config" --impure --print-build-logs
```

Expected: PASS for all 8 assertions.

- [ ] **Step 4: Verify URL format check (negative test, manual)**

Temporarily change one URL in `lib/cache-config.nix` from `https://` to `http://`:

```nix
"http://baleen-nix.cachix.org"
```

Run the build. Expected: `❌ substituter-urls-are-https: FAIL`. The other tests will also fail because the now-`http://` URL is not in the other files (which still have `https://`) — that is fine, expected.

Revert:

```bash
git checkout -- lib/cache-config.nix
```

- [ ] **Step 5: Verify key format check (negative test, manual)**

Temporarily remove the trailing `=` from one public key in `lib/cache-config.nix`:

```nix
"baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k"
```

Run the build. Expected: `❌ public-keys-have-valid-format: FAIL`.

Revert:

```bash
git checkout -- lib/cache-config.nix
```

Re-run the build to confirm all 8 assertions pass.

- [ ] **Step 6: Run the full fast test suite once**

Run:

```bash
export USER=$(whoami)
make test
```

Expected: all tests pass (the new test is included via auto-discovery; on macOS `make test` runs validation mode plus unit/integration tests).

- [ ] **Step 7: Commit**

```bash
git add tests/unit/cache-config-test.nix
git commit -m "test(cache): add consistency test for substituter/key drift across 4 configs"
```

---

## Task 2: Add CI cache hit-rate report

**Files:**
- Modify: `.github/workflows/ci.yml` (existing "Upload to Cachix" step + add new step before it)

The current "Upload to Cachix" step uses `nix build ... --json` and pipes outputs to `cachix push`. It does not create a `./result` symlink. We need that symlink so the hit-rate step can read the closure with a stable path.

- [ ] **Step 1: Read the current "Upload to Cachix" step**

Open `.github/workflows/ci.yml`. Locate the step starting with `- name: Upload to Cachix`. Note its current shape:

```yaml
- name: Upload to Cachix
  if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
  env:
    USER: ${USER:-ci}
    CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}
  continue-on-error: true
  run: |
    export USER=${USER:-ci}
    echo "Uploading to Cachix (continue-on-error enabled)..."
    if [ "$RUNNER_OS" = "macOS" ]; then
      export NIXNAME=macbook-pro
      nix build '.#darwinConfigurations.macbook-pro.system' --json \
        | jq -r '.[].outputs | to_entries[].value' \
        | cachix push baleen-nix || echo "⚠️ Cache upload incomplete - continuing..."
    else
      if [ "${{ matrix.arch }}" = "x86_64" ]; then
        nix build '.#nixosConfigurations.vm-x86_64-utm.config.system.build.toplevel' --json \
          | jq -r '.[].outputs | to_entries[].value' \
          | cachix push baleen-nix || echo "Cache upload incomplete"
      else
        nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' --json \
          | jq -r '.[].outputs | to_entries[].value' \
          | cachix push baleen-nix || echo "Cache upload incomplete"
      fi
    fi
```

We need to:
1. Move the `nix build` invocations out of the conditional `if`/`else` so they always run (not just on main/tag) — this is required so PR builds also produce `./result` for the hit-rate report.
2. Use `--out-link result` instead of `--json | jq | cachix push` for the build, then push separately.
3. Wrap the `cachix push` portion in the existing `if` so it still only runs on main/tag.

There are two reasonable shapes. Pick **option B** below (simpler).

**Option A (rejected):** add a separate "Build closure" step that always runs, then keep "Upload to Cachix" as-is but reading from `./result`. Rejected because it duplicates the matrix-attr branching across two steps.

**Option B (chosen):** restructure the existing step into two phases — always-run build, conditional push. This keeps all matrix-attr branching in one place.

- [ ] **Step 2: Replace the "Upload to Cachix" step**

In `.github/workflows/ci.yml`, replace the entire existing "Upload to Cachix" step (the block from Step 1) with the following two steps. Order: "Build closure" first, then "Cache hit-rate report", then the renamed "Upload to Cachix":

```yaml
      - name: Build closure
        if: always()
        env:
          USER: ${USER:-ci}
        run: |
          export USER=${USER:-ci}
          if [ "$RUNNER_OS" = "macOS" ]; then
            export NIXNAME=macbook-pro
            ATTR='.#darwinConfigurations.macbook-pro.system'
          else
            if [ "${{ matrix.arch }}" = "x86_64" ]; then
              ATTR='.#nixosConfigurations.vm-x86_64-utm.config.system.build.toplevel'
            else
              ATTR='.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
            fi
          fi
          echo "Building $ATTR ..."
          nix build "$ATTR" --impure --out-link result --print-build-logs

      - name: Cache hit-rate report
        if: always()
        continue-on-error: true
        shell: bash
        run: |
          set -uo pipefail
          OUT=$(readlink -f result 2>/dev/null || echo "")
          if [ -z "$OUT" ]; then
            echo "::warning::./result not found — skipping cache hit-rate report"
            exit 0
          fi
          TOTAL=$(nix path-info -r "$OUT" | wc -l | tr -d ' ')
          MISS=$(nix copy --to https://baleen-nix.cachix.org --dry-run "$OUT" 2>&1 \
                 | grep -oE 'would copy [0-9]+' | grep -oE '[0-9]+' | head -1)
          MISS=${MISS:-0}
          HIT=$(( TOTAL - MISS ))
          {
            echo "### Cache hit-rate (${{ matrix.name }})"
            echo ""
            echo "- total closure paths: $TOTAL"
            echo "- hit:  $HIT"
            echo "- miss: $MISS"
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Upload to Cachix
        if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
        env:
          CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}
        continue-on-error: true
        run: |
          OUT=$(readlink -f result)
          echo "Pushing $OUT to Cachix ..."
          nix path-info -r "$OUT" \
            | cachix push baleen-nix || echo "⚠️ Cache upload incomplete - continuing..."
```

Notes on this rewrite:
- "Build closure" runs on every job (PR or main) so the hit-rate step always has data.
- "Cache hit-rate report" runs from the same `./result` symlink. Uses standard Nix commands only.
- "Upload to Cachix" now reuses `./result` instead of running `nix build` again — faster and consistent. Still gated on main/tag by `if:`.
- `cachix push baleen-nix` reads stdin paths; `nix path-info -r` outputs them one per line. This replaces the previous `jq` pipeline and removes the `jq` dependency from this step.

- [ ] **Step 3: Validate the YAML locally**

Run:

```bash
yq eval '.jobs.ci.steps[].name' .github/workflows/ci.yml 2>/dev/null || \
  python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); print('YAML OK')"
```

Expected: list of step names including `Build closure`, `Cache hit-rate report`, `Upload to Cachix` in that order, OR `YAML OK` printed.

If neither tool is available:

```bash
nix run nixpkgs#yq -- eval '.jobs.ci.steps[].name' .github/workflows/ci.yml
```

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci(cache): add hit-rate report and reuse build closure for upload"
```

- [ ] **Step 5: Push and verify on GitHub Actions**

```bash
git push -u origin feat/cache
```

Open the Actions run for the pushed commit. For each matrix job (Darwin, Linux x64, Linux ARM64):
1. Confirm the "Build closure" step succeeded.
2. Confirm the "Cache hit-rate report" step succeeded (or completed with continue-on-error).
3. Open the job's **Summary** tab. Verify the section `Cache hit-rate (<matrix name>)` appears with `total`, `hit`, `miss` lines.
4. Verify `total > 0` and `hit + miss == total`.

If the Summary section is missing for a matrix job:
- Check that `./result` was produced by Build closure (look in the step log for `result` link creation).
- If `nix copy --dry-run` output format changed in this Nix version, MISS will be 0 and the totals will look like a 100% hit. Note this in the PR description; do not fix unless it actually breaks.

If anything fails: investigate logs, fix, push again.

---

## Task 3: Final sanity pass before merge

- [ ] **Step 1: Confirm pre-commit still passes locally**

```bash
pre-commit run --all-files
```

Expected: all hooks pass, including the existing `check-cache-sync` and the new `Fast Tests` (which now include `cache-config-test`).

- [ ] **Step 2: Re-run full test suite**

```bash
export USER=$(whoami)
make test-all
```

Expected: full suite passes.

- [ ] **Step 3: Open the PR**

```bash
gh pr create --title "feat(cache): consistency test + CI hit-rate report" --body "$(cat <<'EOF'
## Summary
- Adds `tests/unit/cache-config-test.nix` to detect substituter/public-key drift across `flake.nix`, `lib/cache-config.nix`, `.github/workflows/ci.yml`, `.github/actions/setup-nix/action.yml`.
- Adds CI Job Summary cache hit-rate report (per-matrix) using `nix path-info -r` and `nix copy --dry-run`.
- Restructures "Upload to Cachix" to reuse a single `./result` build instead of building twice.

Spec: `docs/superpowers/specs/2026-04-27-cache-audit-design.md`

## Test plan
- [ ] `make test` passes locally (includes new test)
- [ ] `pre-commit run --all-files` passes
- [ ] CI green on Darwin / Linux x64 / Linux ARM64
- [ ] Each matrix job's Summary shows `Cache hit-rate (<name>)` with non-zero total
- [ ] Negative tests (manual, recorded in PR comment): drift in `lib/cache-config.nix` is caught by the new unit test
EOF
)"
```
