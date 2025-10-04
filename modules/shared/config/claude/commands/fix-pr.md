---
name: fix-pr
description: "Fix PR conflicts and CI failures with automated resolution"
---

# /fix-pr - PR Conflict & CI Failure Resolution

**Purpose**: Automatically resolve PR conflicts, fix CI failures, and ensure PR readiness

## Usage

```bash
/fix-pr                      # Fix current PR conflicts and CI issues
/fix-pr [pr-number]          # Fix specific PR by number
```

## Execution Strategy

- **Status Assessment**: Check PR status, conflicts, and CI failures
- **Conflict Resolution**: Automated rebase and merge conflict resolution
- **CI Analysis**: Identify and fix common CI failures
- **Force Push Safety**: Use --force-with-lease for safe updates
- **Real-time Monitoring**: Watch CI progress and re-trigger if needed

## Resolution Logic

1. **Status Check**: `gh pr status && gh pr checks` - assess current state
2. **Auto-Commit**: Automatically commit any uncommitted changes before proceeding
3. **Branch Sync**: `git fetch origin main && git rebase origin/main`
4. **Conflict Resolution**: Interactive conflict resolution with file analysis
5. **CI Analysis**: Detailed failure analysis and automated fixes
6. **Safe Push**: `git push --force-with-lease` with verification
7. **Monitoring**: `gh pr checks --watch` until success

## CI 실패 분석 및 자동 수정

### 1. 실패 단계 자동 감지

```bash
# CI 체크 상태 분석
gh pr checks --json name,status,conclusion,detailsUrl | jq -r '.[] | select(.conclusion=="failure") | "\(.name): \(.status)"'
```

### 2. 단계별 실패 진단 및 수정

#### **Validate & Lint 실패**

**진단 방법**:

- `gh run view --log | grep -A5 -B5 "pre-commit\|flake check"`
- 로그에서 구체적인 오류 패턴 검색

**자동 수정**:

```bash
# Pre-commit 실패 → 자동 포맷팅
nix-shell -p pre-commit --run "pre-commit run --all-files --hook-stage manual"
git add -A && git commit -m "style: apply automated formatting fixes"

# Flake 구문 오류 → actionlint 실행
nix-shell -p actionlint --run "actionlint .github/workflows/*.yml"
```

#### **Build 실패 (Darwin/Linux)**

**진단 방법**:

- Nix evaluation 오류: `error: ` 패턴으로 검색
- 캐시 문제: `HTTP 418\|429\|rate limit` 패턴 검색
- Platform 특화 오류: `unsupported system\|missing attribute` 검색

**자동 수정**:

```bash
# 캐시 정리 및 재시도
nix-collect-garbage -d
nix flake update
nix build --impure --no-link --rebuild

# Platform 호환성 확인
nix flake check --impure --all-systems --no-build
```

#### **Test 실패**

**진단 방법**:

- 테스트 로그에서 실패한 테스트 케이스 식별
- Nix 환경 문제: `nix-instantiate not found\|PATH` 검색
- 타임아웃: `timeout\|killed` 패턴 검색

**자동 수정**:

```bash
# Nix 환경 재설정
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
export USER=${USER:-ci}

# 개별 테스트 카테고리 재실행
nix run --impure .#test-unit --verbose
nix run --impure .#test-integration --verbose
```

### 3. Nix 특화 문제 해결

#### **평가 오류 캐싱 문제**

```bash
# 캐시된 오류 정리
rm -rf ~/.cache/nix/eval-cache-v*
nix flake check --impure --no-build --refresh
```

#### **GitHub Actions 캐시 제한**

```bash
# 캐시 키 갱신 강제
gh run cancel $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
gh workflow run ci.yml
```

### 4. 자동화 레벨 분류

**🤖 완전 자동화 가능**:

- Pre-commit hook 실패 → 포맷팅 적용
- 캐시 정리 및 재빌드
- 환경 변수 설정 수정

**🔧 반자동 (진단 + 가이드)**:

- Flake 구문 오류 → actionlint 결과 제시
- 테스트 실패 → 실패한 케이스 식별 후 수동 수정 가이드
- Platform 호환성 → 누락된 attribute 알림

**👤 수동 개입 필요**:

- 로직 오류로 인한 테스트 실패
- 새로운 의존성 추가 필요
- 보안 관련 설정 변경

## Implementation

Use Task tool with subagent_type="git-specialist" to execute PR fix workflow:

Prompt: "Fix PR conflicts and CI failures with arguments: $ARGUMENTS. Execute these operations in parallel:

1. Run `gh pr status` and `gh pr checks` to assess current state
2. Run `git status` to check working directory state
3. Run `git log --oneline -5` to see recent commits

Before resolving conflicts:

- If uncommitted changes exist, automatically commit them with intelligent commit message
- Generate commit message based on file changes and conventional commit patterns
- Use `git add -A && git commit -m "[generated message]"` for auto-commit

For CI failures:

- Analyze `gh pr checks` output to identify failed stages (validate, build, test)
- Apply appropriate automated fixes based on failure type:
  - Lint failures: Run pre-commit hooks and auto-format
  - Build failures: Clear Nix caches and retry builds
  - Test failures: Reset Nix environment and re-run tests
- Use detailed CI failure analysis patterns from the CI 실패 분석 section

For conflicts:

- Perform safe rebase with `git fetch origin main && git rebase origin/main`
- Use `git push --force-with-lease` for safe updates
- Monitor CI progress with `gh pr checks --watch`

Use proper Git workflow expertise and Nix-specific knowledge for comprehensive PR fixing."

## Examples

```bash
/fix-pr                      # Fix conflicts and CI issues in current branch
/fix-pr 123                  # Fix specific PR #123 with full analysis
```
