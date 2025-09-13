# Auto-merge 기능 가이드

dotfiles 리포지토리의 향상된 auto-merge 기능에 대한 완전한 가이드입니다.

## 개요

Auto-merge 기능은 CI 검사가 통과한 후 PR을 자동으로 병합하는 시스템입니다. 두 가지 주요 구성 요소로 작동합니다:

1. **GitHub Actions 워크플로우**: `.github/workflows/auto-merge-pr.yml`
2. **Enhanced Handler Script**: `scripts/auto-merge-handler`

## 주요 특징

### 🚀 향상된 기능

- **지능형 조건 검사**: PR 상태, 라벨, CI 상태 자동 검증
- **유연한 트리거**: 라벨, PR 업데이트, 수동 실행 지원
- **안전한 실행**: 강력한 검증 및 롤백 메커니즘
- **상세한 로깅**: 모든 단계에 대한 명확한 피드백
- **Dry-run 모드**: 실행 전 미리보기 기능

### 🔒 안전성 기능

- Branch protection rules 준수
- CI 검사 완료 대기 (타임아웃 포함)
- 병합 충돌 자동 감지
- Draft PR 자동 제외
- 실패 시 자동 라벨 제거

## 사용법

### 1. PR에 Auto-merge 라벨 추가

```bash
# GitHub CLI 사용
gh pr edit [PR_NUMBER] --add-label "auto-merge"

# 또는 GitHub 웹 인터페이스에서 라벨 추가
```

### 2. 스크립트 직접 실행

```bash
# 현재 브랜치의 PR 자동 병합
./scripts/auto-merge-handler

# 특정 PR 번호 지정
./scripts/auto-merge-handler 123

# Dry-run 모드 (미리보기)
./scripts/auto-merge-handler --dry-run 123

# 타임아웃 설정 (1시간)
./scripts/auto-merge-handler --timeout 3600 123

# 강제 모드 (일부 검사 건너뜀)
./scripts/auto-merge-handler --force 123
```

### 3. GitHub Actions 수동 실행

1. GitHub 리포지토리 → Actions 탭
2. "Auto-merge PR" 워크플로우 선택
3. "Run workflow" 클릭
4. PR 번호 입력 후 실행

## 워크플로우 세부사항

### 트리거 조건

워크플로우는 다음 상황에서 자동 실행됩니다:

```yaml
on:
  pull_request:
    types: [labeled, synchronize, ready_for_review]
  pull_request_review:
    types: [submitted]
  check_suite:
    types: [completed]
  workflow_dispatch:  # 수동 실행
```

### 필수 조건 검사

Auto-merge가 실행되려면 다음 모든 조건을 만족해야 합니다:

- ✅ PR이 열린 상태 (open)
- ✅ Draft PR이 아님
- ✅ 병합 가능한 상태 (mergeable)
- ✅ `auto-merge` 라벨이 있음
- ✅ 모든 필수 CI 검사 통과

### CI 검사 대기

시스템은 다음 필수 검사가 완료될 때까지 대기합니다:

- `CI Summary`
- `Validate & Lint`

## 설정 옵션

### 스크립트 매개변수

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-t, --timeout` | 최대 대기 시간 (초) | 1800 (30분) |
| `-c, --check` | 검사 간격 (초) | 60 (1분) |
| `-r, --retry` | 재시도 횟수 | 3 |
| `-f, --force` | 강제 모드 (안전 검사 건너뜀) | false |
| `-d, --dry-run` | 미리보기 모드 | false |

### 환경 변수

```bash
# GitHub 토큰 (일반적으로 자동 설정됨)
export GITHUB_TOKEN="your_token_here"

# 리포지토리 설정 (Actions에서 자동 설정됨)
export REPO="owner/repository"
```

## 문제 해결

### 일반적인 문제

#### 1. "PR not found" 오류

```bash
# 현재 브랜치에 연결된 PR이 없음
# 해결: PR 번호를 명시적으로 지정
./scripts/auto-merge-handler 123
```

#### 2. "CI checks failed" 오류

```bash
# CI 검사가 실패했거나 아직 실행 중
# 해결: CI 상태 확인 및 문제 수정
gh pr checks [PR_NUMBER]
```

#### 3. "Not mergeable" 오류

```bash
# 병합 충돌 또는 브랜치 보호 규칙 위반
# 해결: 충돌 해결 및 브랜치 업데이트
git pull origin main
git rebase main
```

### 로그 확인

#### GitHub Actions 로그

1. Repository → Actions 탭
2. 실패한 워크플로우 실행 선택
3. 각 단계의 상세 로그 확인

#### 로컬 실행 로그

스크립트는 컬러 코딩된 로그를 제공합니다:

- 🔵 **INFO**: 일반 정보
- 🟢 **SUCCESS**: 성공한 작업
- 🟡 **WARNING**: 경고 메시지
- 🔴 **ERROR**: 오류 및 실패

## 보안 고려사항

### 권한 설정

워크플로우는 최소 필요 권한만 요청합니다:

```yaml
permissions:
  contents: write      # 코드 변경사항 쓰기
  pull-requests: write # PR 관리
  checks: read         # CI 상태 읽기
  actions: read        # 워크플로우 상태 읽기
```

### 토큰 관리

- `GITHUB_TOKEN`: Actions에서 자동 제공
- `REPO_PAT`: 개인 액세스 토큰 (필요한 경우)

## 모니터링 및 알림

### PR 댓글 알림

시스템은 auto-merge 상태를 PR에 자동으로 댓글로 추가합니다:

#### 성공 시:

```markdown
🤖 **Auto-merge enabled** ✅

이 PR은 모든 CI 검사가 통과한 후 자동으로 병합됩니다.

- ✅ 모든 필수 CI 검사 통과
- ✅ Auto-merge 라벨 확인됨  
- ✅ PR 병합 가능 상태 확인

🔄 Branch protection rules이 허용하는 즉시 자동 병합이 실행됩니다.
```

#### 실패 시:

```markdown
❌ **Auto-merge failed**

Auto-merge 프로세스가 실패했습니다. 다음을 확인해주세요:

- CI 검사가 모두 통과했는지 확인
- 브랜치 보호 규칙을 충족하는지 확인
- 병합 충돌이 없는지 확인
```

### 상태 모니터링

```bash
# PR 상태 확인
gh pr view [PR_NUMBER]

# CI 검사 상태 확인
gh pr checks [PR_NUMBER]

# Auto-merge 상태 확인
gh pr view [PR_NUMBER] --json mergeStateStatus,mergeable
```

## 모범 사례

### 1. 점진적 롤아웃

- 중요하지 않은 PR부터 시작
- 팀 내 규칙 및 프로세스 확립
- 정기적인 검토 및 개선

### 2. CI 최적화

- 빠르고 안정적인 CI 파이프라인 구축
- 필수 검사 최소화로 대기 시간 단축
- 병렬 실행으로 전체 실행 시간 최적화

### 3. 라벨 관리

```bash
# auto-merge 라벨 생성
gh label create "auto-merge" --description "PR을 자동으로 병합합니다" --color "0e8a16"

# 관련 라벨들
gh label create "dependencies" --description "의존성 업데이트" --color "0366d6"
gh label create "automation" --description "자동화 관련" --color "7057ff"
```

### 4. 브랜치 보호 설정

```bash
# Branch protection rule 설정 예시
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI Summary","Validate & Lint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```

## 통합 예시

### 완전한 PR 생성 및 Auto-merge 워크플로우

```bash
# 1. 피처 브랜치 생성 및 작업
git checkout -b feat/auto-merge-enhancement
# ... 코드 변경 및 커밋 ...

# 2. PR 생성
gh pr create --title "feat: enhance auto-merge functionality" \
             --body "Auto-merge 기능 개선사항" \
             --label "enhancement,auto-merge"

# 3. CI가 통과하면 자동 병합됨
# 또는 수동으로 즉시 실행:
./scripts/auto-merge-handler

# 4. 상태 모니터링
gh pr view --web
```

이 가이드를 통해 dotfiles의 향상된 auto-merge 기능을 효과적으로 활용할 수 있습니다. 추가 질문이나 문제가 있으면 GitHub Issues를 통해 문의해주세요.
