---
description: Find quality gate gaps and get instant fix suggestions - works with any project
---

User input:

$ARGUMENTS

**Goal**: CI 실패 전에 로컬에서 모든 문제를 발견하도록 품질 검사 일관성 검증 및 개선 제안

**Core Principle**: "If CI checks it, you should run it locally BEFORE pushing"

## Quick Start

```bash
/validate-quality
```

**What it does** (~5 seconds):

1. Auto-detect project (Python/JS/Go/Rust/Java/etc.)
2. Compare: pre-commit ↔ local scripts ↔ CI config
3. Show gaps with **instant fix code**
4. Apply fixes automatically (if you want)

**No commands executed** - read-only file analysis.

## Detection Strategy

### 1. Auto-Detect Project Type

**Scan for marker files** (no execution):

- Python: `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile`
- JavaScript/TypeScript: `package.json`, `tsconfig.json`
- Go: `go.mod`
- Rust: `Cargo.toml`
- Java: `pom.xml`, `build.gradle`, `build.gradle.kts`
- Ruby: `Gemfile`
- PHP: `composer.json`
- C#/.NET: `*.csproj`, `*.sln`

**Scan for build tools**:

- `Makefile`, `package.json` scripts, `pyproject.toml` scripts, etc.

**Scan for CI**:

- GitHub Actions, GitLab CI, CircleCI, Travis, Jenkins, Azure Pipelines

### 2. Extract Quality Checks

**From pre-commit** (`.pre-commit-config.yaml`):

```yaml
# Example: What checks are configured?
- prettier (formatting)
- eslint (linting)
- pytest (testing)
```

**From local scripts** (Makefile/package.json):

```bash
# What commands exist?
npm run lint → eslint .
npm run test → jest
npm run format → prettier --write .
```

**From CI** (`.github/workflows/*.yml`):

```yaml
# What does CI run?
- run: npm run lint
- run: npm test
- run: npm run type-check
```

### 3. Compare & Find Gaps

Build matrix to spot inconsistencies:

| Check      | Pre-commit | Local | CI  | Gap? |
| ---------- | ---------- | ----- | --- | ---- |
| Format     | ✓          | ✓     | ✓   | ✅   |
| Lint       | ✓          | ✓     | ✓   | ✅   |
| Type-check | ❌         | ❌    | ✓   | 🔴   |
| Tests      | ❌         | ✓     | ✓   | 🟡   |
| Security   | ✓          | ❌    | ✓   | 🟡   |

**Gap types**:

- 🔴 **Critical**: CI checks but you can't run locally → surprise failures
- 🟡 **Warning**: Inconsistent coverage → potential gaps
- ✅ **OK**: Fully aligned

### 4. Generate Fix Code

**For each gap, provide instant copy-paste fix**.

---

## Output Format: Action-Focused Report

Report structure (under 50 lines for simple projects):

**Project**: React + TypeScript
**Status**: 2 critical gaps found

---

## 🔴 Critical Gaps (Fix Now)

### Gap #1: Type checking only in CI

**Problem**: `tsc --noEmit` runs in CI but not locally → surprise failures

**Fix** (add to `.pre-commit-config.yaml`):

```yaml
- repo: local
  hooks:
    - id: typescript-check
      name: TypeScript type check
      entry: npx tsc --noEmit
      language: system
      files: \.(ts|tsx)$
      pass_filenames: false
```

**Test**: `pre-commit run --all-files`

---

### Gap #2: Missing `npm test` in pre-commit

**Problem**: Tests run in CI but not on commit → broken commits

**Fix** (add to `.pre-commit-config.yaml`):

```yaml
- repo: local
  hooks:
    - id: jest
      name: Jest tests
      entry: npm test -- --bail --findRelatedTests
      language: system
      files: \.(ts|tsx)$
      pass_filenames: true
```

**Test**: `git commit` (should run tests on changed files)

---

## 🟡 Warnings (Consider Fixing)

### Version Drift: eslint@8.57.0 locally vs eslint@9.0.0 in CI

**Fix**: Update `package.json`:

```json
{
  "devDependencies": {
    "eslint": "^9.0.0"
  }
}
```

Then: `npm install`

---

## ✅ Perfect Alignment (Keep These)

- ✅ Prettier: pre-commit ↔ CI
- ✅ ESLint: pre-commit ↔ CI
- ✅ Build check: local scripts ↔ CI

---

## Ecosystem Best Practices

**TypeScript Projects**:

- ✅ `strict: true` in tsconfig.json
- ⚠️ Consider `@typescript-eslint/recommended`
- 💡 Add `tsc-files` for faster pre-commit checks

**Testing**:

- ⚠️ Coverage threshold not configured (recommend 80%)
- 💡 Add `--coverage` to CI test command

---

## Apply Fixes?

Would you like me to:

1. [ ] Update `.pre-commit-config.yaml` with Gap #1 + #2 fixes
2. [ ] Update `package.json` dependencies
3. [ ] Show me the full changes first

```

**Key improvements**:
- Lead with **actionable fixes**, not statistics
- Show **exact code** to copy-paste
- Prioritize by **impact** (critical → warnings → suggestions)
- Keep ecosystem suggestions **optional and brief**

---

## Special Cases

### No Configuration Found

```

⚠️ No quality tools detected

Suggested setup:

1. Add pre-commit: curl https://pre-commit.com/install-local.py | python -
2. Create .pre-commit-config.yaml with language-specific hooks
3. Run: pre-commit install

Resources:

- Python: https://pre-commit.com/hooks.html#python
- JavaScript: https://pre-commit.com/hooks.html#javascript
- Go: https://pre-commit.com/hooks.html#go

```

### Perfect Alignment

```

✅ All checks aligned!

Pre-commit ↔ Local scripts ↔ CI are consistent.
No action needed.

```

### CI-Only Setup

```

⚠️ Quality checks only in CI

Problem: Issues caught AFTER pushing (slow feedback)
Solution: Add pre-commit hooks for instant feedback

Would you like me to generate .pre-commit-config.yaml from your CI config?

````

---

## Execution Rules

1. **Read-only**: Never execute commands, only analyze files
2. **Fast**: Complete in ~5 seconds
3. **Language-agnostic**: Adapt to any project automatically
4. **Fix-focused**: Every gap gets copy-paste code
5. **Prioritized**: Critical gaps first, nice-to-haves last

---

## Multi-Language Example Patterns

**Python** (pytest in CI, missing locally):
```yaml
- repo: local
  hooks:
    - id: pytest
      name: pytest
      entry: pytest tests/ -v
      language: system
      pass_filenames: false
````

**Go** (go test in CI, missing locally):

```yaml
- repo: local
  hooks:
    - id: go-test
      name: Go tests
      entry: go test ./...
      language: system
      pass_filenames: false
```

**Rust** (cargo test in CI, missing locally):

```yaml
- repo: local
  hooks:
    - id: cargo-test
      name: Cargo test
      entry: cargo test
      language: system
      pass_filenames: false
```

**Java** (mvn test in CI, missing locally):

```yaml
- repo: local
  hooks:
    - id: maven-test
      name: Maven test
      entry: mvn test
      language: system
      pass_filenames: false
```

---

Context: $ARGUMENTS
