---
description: Universal quality validation ensuring consistency between pre-commit, lint, tests, and CI pipelines across any project type
---

User input:

$ARGUMENTS

Goal: 모든 품질 검사 (pre-commit, lint, test, CI)가 일관성 있게 동작하도록 검증하고, CI에서 발견되는 문제를 로컬에서 미리 발견합니다.

**Universal Design**: Works with any project type (Nix, Python, JavaScript, Go, Rust, etc.) by auto-detecting project structure and tools.

## How It Works

Simply run:
```bash
/validate-quality
```

The command will:
1. **Auto-detect** your project type and tools
2. **Analyze** all quality gates (pre-commit, lint, test, CI)
3. **Find gaps** where CI checks something but pre-commit doesn't
4. **Suggest fixes** with specific commands to align everything

No flags needed - it intelligently adapts to your project.

## Execution Strategy

### Layer 0: Project Detection (5s)

**Purpose**: Auto-detect project type and available tools

**Detection Steps**:
1. Identify project type by checking for marker files:
   - **Nix**: `flake.nix` or `default.nix`
   - **Python**: `pyproject.toml`, `setup.py`, `requirements.txt`
   - **JavaScript/TypeScript**: `package.json`
   - **Go**: `go.mod`
   - **Rust**: `Cargo.toml`
   - **Ruby**: `Gemfile`
   - **Java/Kotlin**: `pom.xml`, `build.gradle`

2. Detect build/task runners:
   - **Makefile**: `Makefile`
   - **npm/yarn/pnpm**: `package.json` scripts
   - **poetry**: `pyproject.toml` with `[tool.poetry]`
   - **cargo**: `Cargo.toml`
   - **gradle/maven**: `build.gradle`, `pom.xml`

3. Detect CI providers:
   - **GitHub Actions**: `.github/workflows/*.yml`
   - **GitLab CI**: `.gitlab-ci.yml`
   - **CircleCI**: `.circleci/config.yml`
   - **Travis CI**: `.travis.yml`
   - **Jenkins**: `Jenkinsfile`

4. Detect quality tools:
   - **pre-commit**: `.pre-commit-config.yaml`
   - **act**: `which act` (for local CI testing)
   - **lint config**: `.eslintrc`, `pyproject.toml`, `.rubocop.yml`, etc.

**Output**:
```text
📊 Project Detection Results:
  Type: Nix + Go
  Build Tools: make, nix
  CI: GitHub Actions
  Quality Tools: pre-commit, act
  Detected Commands:
    - Format: make format
    - Lint: make lint
    - Test: make test-core
```

---

### Layer 1: Pre-commit Validation (30s)

**Purpose**: Ensure pre-commit hooks match CI expectations

**Steps**:
1. Check if `.pre-commit-config.yaml` exists
2. If yes: Extract all hook IDs and versions
3. If no: Note this as potential gap (suggest adding pre-commit)
4. Parse hook configurations to understand what checks are performed

**Analysis** (no execution):
- List all configured hooks
- Note any hooks that might be outdated
- Compare with CI checks (analyzed in Layer 5)

---

### Layer 2: Format & Lint Detection

**Purpose**: Detect available formatting and linting tools

**Steps** (based on detected project type):

1. **Detect build tool commands**:
   - Makefile: Check for `format`, `lint`, `fmt` targets
   - package.json: Check `scripts` section for format/lint entries
   - pyproject.toml: Check for `[tool.black]`, `[tool.ruff]`, etc.
   - Other: Look for standard tool configs

2. **Detect direct tool configs**:
   - Formatting: `.prettierrc`, `.editorconfig`, `rustfmt.toml`, etc.
   - Linting: `.eslintrc`, `pylintrc`, `.golangci.yml`, etc.

**Analysis** (no execution):
- List detected format/lint commands
- Note which tools are configured
- Compare with pre-commit hooks (if any)

---

### Layer 3: Test Configuration Detection

**Purpose**: Detect what tests are configured

**Steps** (based on detected project type):

1. **Detect test commands**:
   - Makefile: Check for `test`, `test-unit`, `test-integration` targets
   - package.json: Check `scripts.test` and related entries
   - pyproject.toml: Check for `pytest` config
   - Cargo.toml: Test config is implicit
   - go.mod: Test config is implicit

2. **Detect test frameworks**:
   - JavaScript: Jest, Vitest, Mocha config files
   - Python: pytest.ini, tox.ini
   - Go: Test files (*_test.go)
   - Rust: Test files (tests/)
   - Nix: checks in flake.nix

3. **Detect coverage tools**:
   - Coverage configs: .coveragerc, jest.config.js coverage section

**Analysis** (no execution):
- List detected test commands
- Note test framework and configuration
- Compare with CI test jobs

---

### Layer 4: CI Configuration Analysis

**Purpose**: Understand what CI is checking

**Steps** (based on detected CI provider):

1. **Parse CI configuration**:
   - GitHub Actions: Parse `.github/workflows/*.yml`
   - GitLab CI: Parse `.gitlab-ci.yml`
   - CircleCI: Parse `.circleci/config.yml`
   - Travis: Parse `.travis.yml`
   - Jenkins: Parse `Jenkinsfile`

2. **Extract validation steps**:
   - Identify all jobs/stages
   - Extract commands from each step
   - Categorize: format, lint, test, build, deploy, etc.
   - Note environment variables and setup steps

3. **Detect CI-specific checks**:
   - Security scans (CodeQL, Snyk, etc.)
   - Dependency checks (Dependabot, etc.)
   - Performance tests
   - Integration tests
   - Deployment verification

**Analysis** (no execution):
- List all CI validation jobs
- Show commands run in each job
- Note CI-only checks not in pre-commit
- Note local tools (act, gitlab-runner) availability for future testing

---

### Layer 5: Cross-Layer Consistency Analysis

**Purpose**: Ensure all layers check the same things

**Steps**:
1. Extract checks from each layer:
   - **Pre-commit**: Parse `.pre-commit-config.yaml` → hook IDs
   - **Lint/Format**: Detect from build tool scripts/commands
   - **Test**: Detect from test commands
   - **CI**: Parse CI config → extract validation steps

2. Build consistency matrix (example):
   ```text
   Check Type         | Pre-commit | Lint | Test | CI |
   ------------------|-----------|------|------|-----|
   Code formatting   |     ✓     |  ✓   |  -   |  ✓  |
   Linting           |     ✓     |  ✓   |  -   |  ✓  |
   Type checking     |     ✓     |  -   |  -   |  ✓  |
   Unit tests        |     -     |  -   |  ✓   |  ✓  |
   Integration tests |     -     |  -   |  ✓   |  ✓  |
   Security scan     |     ✓     |  -   |  -   |  ✓  |
   Dependency audit  |     -     |  -   |  -   |  ✓  |
   ```

3. Detect inconsistencies:
   - **Critical Gaps**: Checks in CI but not pre-commit (HIGH risk)
     - Example: Type checking in CI but not locally
   - **Optimization**: Checks in pre-commit but not CI (wasted effort)
     - Example: Local-only hooks that CI doesn't verify
   - **Version Drift**: Same tool, different versions
     - Example: eslint@8.0 locally, eslint@9.0 in CI
   - **Argument Drift**: Same tool, different flags
     - Example: `pytest` locally, `pytest --strict` in CI

4. Suggest alignment actions:
   - Add missing checks to pre-commit
   - Remove redundant checks
   - Align tool versions
   - Standardize arguments/flags

**Expected Results**:
- All critical checks exist in both pre-commit and CI
- No redundant checks
- Version alignment across layers
- Argument/flag consistency

**If Inconsistencies Detected**:
- Show consistency matrix with ❌ for gaps
- Prioritize gaps: 🔴 High (CI-only), 🟡 Medium (pre-commit-only), 🟢 Low (version drift)
- Offer to update `.pre-commit-config.yaml` or CI workflow
- Generate suggested `.pre-commit-config.yaml` updates

---

### Layer 6: Ecosystem-Specific Recommendations (Optional)

**Purpose**: Suggest best practices for detected ecosystems

**Checks** (based on Layer 0 detection):

**Nix Projects** (`flake.nix` detected):
1. ✅ Is `git-hooks.nix` in flake inputs?
   - If NO: Suggest adding for declarative hook management
2. ✅ Are pre-commit hooks in `flake checks`?
   - If NO: Suggest integration for `nix flake check` consistency
3. ✅ Is `.pre-commit-config.yaml` in `.gitignore`?
   - If using git-hooks.nix and NOT in .gitignore: Warn (should be auto-generated)

**Python Projects** (`pyproject.toml` detected):
1. ✅ Is `ruff` configured? (modern alternative to flake8, black, isort)
2. ✅ Is `mypy` or `pyright` configured for type checking?
3. ✅ Is `pytest` with coverage configured?

**JavaScript/TypeScript Projects** (`package.json` detected):
1. ✅ Is `prettier` + `eslint` configured?
2. ✅ Is `husky` configured for git hooks?
3. ✅ Is `typescript` strict mode enabled?

**Go Projects** (`go.mod` detected):
1. ✅ Is `golangci-lint` configured?
2. ✅ Are Go modules tidy? (`go mod tidy` check)
3. ✅ Is race detector used in tests?

**Rust Projects** (`Cargo.toml` detected):
1. ✅ Is `clippy` configured?
2. ✅ Is `rustfmt` configured?
3. ✅ Are tests run with `--all-features`?

**General Recommendations**:
- 💡 Consider adding `pre-commit.ci` for auto-fix PRs
- 💡 Consider adding `Cachix` for Nix build caching
- 💡 Consider adding dependency update automation (Dependabot, Renovate)
- 💡 Consider adding security scanning (Trivy, Snyk, etc.)

**Output**:
- List of missing best practices
- Priority: 🔴 Critical, 🟡 Recommended, 🟢 Optional
- Links to setup guides

---

## Execution Flow

```text
┌─────────────────────────────────────┐
│ 1. Parse Arguments & Set Mode       │
│    - Quick / Full / Layer-specific  │
│    - Fix mode enabled?              │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 2. Layer 0: Project Detection       │
│    ├─ Detect project type           │
│    ├─ Detect build tools            │
│    ├─ Detect CI provider            │
│    └─ Build command map             │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 3. Pre-Flight Checks                │
│    - Verify detected tools exist    │
│    - Check git status               │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 4. Layer 1: Pre-commit (always)     │
│    ├─ Install hooks if missing      │
│    ├─ Run all hooks                 │
│    └─ Collect results               │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 5. Layer 2: Format & Lint           │
│    ├─ Run detected format cmd       │
│    ├─ Run detected lint cmd         │
│    └─ Compare with Layer 1          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 6. Layer 3: Tests                   │
│    ├─ Run detected test cmd (quick) │
│    └─ Run full tests (if --full)    │
└────────────┬────────────────────────┘
             │
             ▼ (if --full)
┌─────────────────────────────────────┐
│ 7. Layer 4: CI Simulation           │
│    ├─ Run detected CI runner        │
│    └─ Or parse & run manually       │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 8. Layer 5: Consistency Analysis    │
│    ├─ Build check matrix            │
│    ├─ Detect gaps & duplicates      │
│    └─ Generate recommendations      │
└────────────┬────────────────────────┘
             │
             ▼ (optional)
┌─────────────────────────────────────┐
│ 9. Layer 6: Ecosystem Best Practices│
│    ├─ Check ecosystem patterns      │
│    └─ Suggest improvements          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 10. Report Generation               │
│    ├─ Summary: ✓ Passed / ❌ Failed │
│    ├─ Consistency matrix            │
│    ├─ Ecosystem recommendations     │
│    └─ Next steps                    │
└─────────────────────────────────────┘
```

## Implementation Steps

### Core Process

1. **Silent File Analysis** (no commands executed):
   - Use Read tool to read configuration files
   - Use Glob tool to find config files
   - Parse YAML/JSON/TOML/Makefile contents
   - Extract check definitions from each layer

2. **Build Knowledge Graph**:
   ```
   pre-commit checks:
     - nixfmt (v1.0.0)
     - statix
     - deadnix
     - markdownlint

   CI checks (GitHub Actions):
     - nixfmt (via nix develop)
     - statix (via nix develop)
     - pre-commit run --all-files
     - go test ./...

   Makefile targets:
     - make format → nix run .#format
     - make lint → pre-commit run --all-files
     - make test-core → nix build .#all

   Detected gaps:
     - Go tests in CI but not in pre-commit ❌
     - Go tests in CI but not in Makefile ❌
   ```

3. **Consistency Analysis**:
   - Compare checks across all layers
   - Identify gaps (CI-only checks)
   - Identify redundancies (pre-commit-only checks)
   - Detect version mismatches

4. **Generate Recommendations**:
   - Prioritize by impact
   - Provide specific fix commands
   - Offer to generate config updates

### Report Generation

```markdown
# Quality Gate Consistency Report

📊 **Project**: Nix Dotfiles (Nix + Go)
⏱️  **Analysis Time**: 5s (no commands executed)
📍 **Working Dir**: /Users/baleen/dotfiles

---

## Summary

✅ **Status**: 12/14 checks aligned
⚠️  **Gaps Found**: 2 CI checks missing locally
💡 **Recommendations**: 3 improvements suggested

---

## Configuration Coverage

### Layer Detection Results
- ✅ Pre-commit: `.pre-commit-config.yaml` (15 hooks)
- ✅ Lint/Format: Makefile + nix formatter
- ✅ Tests: Makefile (8 targets) + flake checks
- ✅ CI: GitHub Actions (.github/workflows/ci.yml)

### Check Matrix

| Check Type         | Pre-commit | Makefile | CI  | Status  | Issue |
|--------------------|-----------|----------|-----|---------|-------|
| nixfmt             | ✓         | ✓        | ✓   | ✅ OK    | -     |
| statix             | ✓         | ✓        | ✓   | ✅ OK    | -     |
| deadnix            | ✓         | ✓        | ✓   | ✅ OK    | -     |
| shellcheck         | ✓         | ✓        | ✓   | ✅ OK    | -     |
| shfmt              | ✓         | ✓        | ✓   | ✅ OK    | -     |
| yamlfmt            | ✓         | ✓        | ✓   | ✅ OK    | -     |
| markdownlint       | ✓         | ✓        | ✓   | ✅ OK    | -     |
| Go tests           | ✓         | -        | ✓   | ⚠️ GAP   | #1    |
| Go fmt             | -         | -        | ✓   | ⚠️ GAP   | #2    |
| Smoke test         | ✓         | ✓        | ✓   | ✅ OK    | -     |
| Structure check    | ✓         | ✓        | ✓   | ✅ OK    | -     |
| Flake check        | -         | ✓        | ✓   | ✅ OK    | -     |

---

## Issues Found

### 🔴 High Priority

**#1: Go tests not in Makefile**
- **Impact**: Local `make test` doesn't run Go tests, but CI does
- **CI command**: `cd modules/shared/programs/claude-hook && go test -v ./...`
- **Suggested fix**:
  ```makefile
  # Add to Makefile
  test-go:
      @echo "🧪 Running Go tests..."
      @cd modules/shared/programs/claude-hook && go test -v ./...

  # Update test-core to include Go tests
  test-core: test-go
      @$(NIX) build --impure --quiet .#packages.all
  ```

**#2: Go formatting not in pre-commit**
- **Impact**: CI runs `go fmt`, but pre-commit doesn't check it
- **Suggested fix**:
  ```yaml
  # Add to .pre-commit-config.yaml
  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.1
    hooks:
      - id: go-fmt
      - id: go-vet
  ```

### 🟡 Medium Priority

**#3: Consider git-hooks.nix for Nix projects**
- **Current**: Manual `.pre-commit-config.yaml`
- **Best practice**: Declarative hooks via `git-hooks.nix` in flake
- **Benefit**: Reproducible hook versions, automatic `.pre-commit-config.yaml` generation
- **Learn more**: https://github.com/cachix/git-hooks.nix

---

## Recommendations

### Immediate Actions
```bash
# 1. Add Go tests to Makefile (copy suggested code above)
# 2. Add Go hooks to .pre-commit-config.yaml (copy suggested code above)
# 3. Test the changes
make test-go              # Should pass
pre-commit run --all-files # Should check Go formatting
```

### Future Improvements
- 💡 Consider migrating to `git-hooks.nix` for better Nix integration
- 💡 Add `pre-commit.ci` for automatic PR fixes
- 💡 Document quality gates in CLAUDE.md

---

## Ecosystem-Specific Insights

**Nix Project Recommendations**:
- ✅ Pre-commit configured (good!)
- ⚠️  Not using `git-hooks.nix` (consider upgrading)
- ✅ Flake checks configured (good!)
- ℹ️  `.pre-commit-config.yaml` should be in `.gitignore` if using git-hooks.nix

**Go Project Recommendations**:
- ⚠️  Missing `golangci-lint` configuration (recommended)
- ⚠️  Missing Go hooks in pre-commit
- ✅ CI runs Go tests (good!)

---

## Next Steps

**Apply suggested fixes?**
- [ ] Yes, update Makefile with Go test target
- [ ] Yes, add Go hooks to pre-commit
- [ ] No, I'll do it manually
- [ ] Remind me later

Would you like me to apply these changes?
```

## Behavior Rules

1. **Analysis-Only**: NO commands executed - only file reading and parsing
2. **Fast**: Completes in 5-15 seconds (just reads files)
3. **Safe**: Cannot break anything - read-only operation
4. **Actionable**: Every gap includes specific fix with copy-pasteable code
5. **Universal**: Works on any project type through auto-detection
6. **Smart**: Automatically detects project type, tools, and CI provider
7. **Helpful**: Suggests ecosystem-specific best practices (Nix, Python, Go, etc.)

## Special Handling

### No Configuration Files Found
If no quality tools detected:
```text
ℹ️ No quality configuration detected:
  - No .pre-commit-config.yaml
  - No CI configuration files
  - No lint/format scripts

Recommendation: Start with pre-commit.com
  Visit: https://pre-commit.com/#quick-start
```

### Single Layer Detected
If only one layer configured (e.g., only CI, no pre-commit):
```text
⚠️ Quality checks only in CI

This means issues are caught late (after push).
Recommendation: Add pre-commit hooks for early feedback.
```

### Perfect Alignment
If all checks are aligned:
```text
✅ Perfect alignment!

All quality checks are consistent across:
  - Pre-commit hooks
  - Local commands (Makefile/package.json/etc.)
  - CI pipeline

No action needed. Great job! 🎉
```

## Output Format

Use emoji and clear formatting for readability:
- ✅ Success
- ❌ Failure
- ⏭️ Skipped
- ⚠️ Warning
- 💡 Recommendation
- 🔧 Fix Available

Use tables for consistency matrix (easier to scan)
Use code blocks for commands (copy-paste friendly)
Use collapsible sections for verbose output (if supported)

## Integration with Existing Tools

This command orchestrates existing tools:
- **Pre-commit**: `.pre-commit-config.yaml` hooks
- **Makefile**: `make lint`, `make format`, `make test-*`
- **CI**: `.github/workflows/ci.yml` jobs
- **act**: Local CI simulation
- **Nix**: `nix flake check`, test framework

Does NOT replace them - ensures they work together consistently.

## Success Criteria

After running `/validate-quality --full`, user should be confident:
1. ✅ All pre-commit hooks will pass on commit
2. ✅ All lint checks will pass in CI
3. ✅ All tests will pass in CI
4. ✅ No surprises in CI that weren't caught locally
5. ✅ Clear understanding of what needs fixing (if anything)

---

Context: $ARGUMENTS
