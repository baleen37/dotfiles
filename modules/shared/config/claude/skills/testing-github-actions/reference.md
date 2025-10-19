# Testing GitHub Actions - Reference Guide

Comprehensive guide for act and gh CLI: installation, practical examples, troubleshooting, and advanced techniques.

**Progressive Disclosure**: This reference is loaded on-demand when detailed information is needed. For quick workflows, refer to `SKILL.md`.

## Table of Contents

1. [Installation and Setup](#설치-및-초기-설정)
2. [Practical Examples](#실전-예제)
3. [Common Troubleshooting](#일반적인-문제-해결)
4. [Advanced Usage](#고급-사용법)
5. [Checklist Deep Dive](#체크리스트-상세-설명)
6. [Official Resources](#official-resources)

## 설치 및 초기 설정

### act 설치

**macOS (Homebrew)**:
```bash
brew install act
```

**Linux**:
```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Docker 설치 확인**:
```bash
docker --version
# Docker가 없으면 설치: https://docs.docker.com/get-docker/
```

### gh CLI 설치 및 인증

**설치**:
```bash
brew install gh
```

**인증**:
```bash
gh auth login
# 브라우저에서 GitHub 로그인 후 토큰 발급
```

### 프로젝트 초기 설정

**.actrc 생성** (프로젝트 루트):
```bash
cat > .actrc << 'EOF'
# 경량 Ubuntu 이미지 사용 (성능 최적화)
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04

# 시크릿 파일 자동 로드
--secret-file .secrets

# 환경 변수 파일 자동 로드
--env-file .env
EOF
```

**.secrets 생성** (절대 커밋하지 말것!):
```bash
cat > .secrets << 'EOF'
GITHUB_TOKEN=ghp_your_token_here
NPM_TOKEN=npm_your_token_here
DOCKER_PASSWORD=your_docker_password
EOF

# .gitignore에 추가
echo ".secrets" >> .gitignore
```

**.env 생성**:
```bash
cat > .env << 'EOF'
NODE_ENV=test
CI=true
DATABASE_URL=sqlite://test.db
EOF
```

## 실전 예제

### 예제 1: Node.js CI 워크플로우 테스트

**워크플로우 파일** (`.github/workflows/ci.yml`):
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:
    inputs:
      debug:
        description: 'Enable debug logging'
        required: false
        default: 'false'

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    strategy:
      matrix:
        node-version: [18, 20, 22]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        if: matrix.node-version == 20
        with:
          name: coverage
          path: coverage/
```

**로컬 테스트**:
```bash
# 1. Dry-run으로 실행 계획 확인
act -n

# 2. 특정 Node 버전만 테스트 (빠른 검증)
act -j test --matrix node-version:20

# 3. 전체 matrix 테스트
act

# 4. workflow_dispatch 이벤트로 테스트
act workflow_dispatch -j test

# 5. 디버그 모드로 실행
act -v -j test
```

**GitHub에서 실행**:
```bash
# 워크플로우 트리거
gh workflow run ci.yml

# 실행 상태 모니터링
gh run watch

# 최근 실행 목록
gh run list --workflow=ci.yml --limit 5

# 특정 실행의 로그 확인
gh run view $(gh run list --workflow=ci.yml --limit 1 --json databaseId -q '.[0].databaseId') --log
```

### 예제 2: Docker 빌드 워크플로우

**워크플로우 파일** (`.github/workflows/docker.yml`):
```yaml
name: Docker Build

on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332  # v4.1.7 (SHA pinned)

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@988b5a0280414f521da01fcc63a27aeeb4b104db  # v3.6.1

      - name: Login to GitHub Container Registry
        uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567  # v3.3.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@5176d81f87c23d6fc96624dfdbcd9f3830bbe445  # v6.5.0
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**로컬 테스트** (Docker 빌드만 검증):
```bash
# Docker 이미지로 act 실행 (Docker-in-Docker)
act -j build --container-architecture linux/amd64

# GITHUB_TOKEN 시크릿 제공
act -j build --secret GITHUB_TOKEN=$(gh auth token)
```

### 예제 3: Multi-stage 배포 워크플로우

**워크플로우 파일** (`.github/workflows/deploy.yml`):
```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment: ${{ inputs.environment }}

    concurrency:
      group: deploy-${{ inputs.environment }}
      cancel-in-progress: false

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to ${{ inputs.environment }}
        run: |
          echo "Deploying to ${{ inputs.environment }}"
          # 실제 배포 스크립트...
```

**로컬 테스트** (이벤트 파일 사용):
```bash
# 이벤트 JSON 파일 생성
cat > deploy-event.json << 'EOF'
{
  "inputs": {
    "environment": "staging"
  }
}
EOF

# 이벤트 파일로 테스트
act workflow_dispatch -j deploy -e deploy-event.json

# production 환경 테스트
cat > deploy-prod-event.json << 'EOF'
{
  "inputs": {
    "environment": "production"
  }
}
EOF

act workflow_dispatch -j deploy -e deploy-prod-event.json
```

**GitHub에서 실행**:
```bash
# staging 배포
gh workflow run deploy.yml -f environment=staging

# production 배포
gh workflow run deploy.yml -f environment=production

# 실행 대기 중인 job 확인
gh run list --workflow=deploy.yml --status=queued

# 실행 취소 (필요시)
gh run cancel <run-id>
```

## 일반적인 문제 해결

### 1. Commit Conflict 문제

**증상**: PR에서 merge conflict 발생, CI 워크플로우가 실행되지 않음

**해결 방법**:

```bash
# 1. 최신 main 브랜치 가져오기
git fetch origin main

# 2. 현재 브랜치에서 rebase
git rebase origin/main

# 3. Conflict 해결
# 파일을 수동으로 편집하고 conflict 마커 제거
# <<<<<<<, =======, >>>>>>> 부분을 찾아 수정

# 4. 해결된 파일 추가
git add <resolved-files>

# 5. Rebase 계속
git rebase --continue

# 6. Force push (주의: 협업 시 팀원과 조율 필요)
git push --force-with-lease

# 7. CI가 자동으로 다시 실행되는지 확인
gh run list --branch=$(git branch --show-current) --limit 1
```

**로컬에서 미리 테스트**:
```bash
# Rebase 전에 act로 CI 검증
git checkout feature-branch
act push

# Conflict 해결 후 다시 테스트
git rebase origin/main
# ... conflict 해결 ...
act push
```

**주의사항**:
- `git push --force`는 절대 main/master 브랜치에 사용하지 말 것
- `--force-with-lease`를 사용해 다른 사람의 커밋을 덮어쓰지 않도록 보호
- Rebase 중 conflict 해결 시 테스트가 여전히 통과하는지 확인

### 2. CI 실패 문제

**증상**: GitHub Actions 워크플로우가 실패함

**체계적 디버깅 프로세스**:

```bash
# 1단계: 로그 상세 분석
gh run view <run-id> --log > failure.log
less failure.log  # 오류 메시지 찾기

# 2단계: 실패한 step 식별
gh run view <run-id> --log-failed

# 3단계: 로컬에서 재현
act -j <job-name> -v

# 4단계: 특정 step만 디버깅 (act에서)
# act는 이전 실행 결과를 캐싱하므로 --reuse로 빠르게 재시도
act --reuse -j <job-name>

# 5단계: 디버그 로깅 활성화 (GitHub)
gh secret set ACTIONS_STEP_DEBUG --body "true"
gh secret set ACTIONS_RUNNER_DEBUG --body "true"

# 워크플로우 재실행
gh run rerun <run-id>

# 디버그 로그 확인
gh run view <run-id> --log
```

**일반적인 실패 원因과 해결책**:

**테스트 실패**:
```bash
# 로컬에서 동일한 환경 재현
act -j test --env CI=true

# 특정 Node 버전 테스트
act -j test --matrix node-version:18

# 의존성 캐시 문제 가능성 확인
# 워크플로우에서 캐시 무효화:
gh workflow run ci.yml --ref $(git branch --show-current)
```

**빌드 실패**:
```bash
# 환경 변수 누락 확인
act -j build --env-file .env --secret-file .secrets

# Docker 이미지 차이 문제
# act에서 GitHub과 동일한 이미지 사용
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest
```

**권한 문제**:
```yaml
# 워크플로우에 명시적 권한 추가
permissions:
  contents: read
  packages: write
  issues: write
```

### 3. Secret Key 설정 문제

**증상**: 워크플로우에서 secret에 접근할 수 없음

**Repository Secret 설정**:
```bash
# gh CLI로 secret 추가
gh secret set SECRET_NAME

# 또는 파일에서 읽기
gh secret set SECRET_NAME < secret.txt

# Secret 목록 확인
gh secret list

# Secret 삭제
gh secret delete SECRET_NAME
```

**Environment Secret 설정** (환경별 분리):
```bash
# Environment는 웹 UI에서만 생성 가능
# Settings > Environments > New environment

# 생성 후 secret 추가
gh secret set DATABASE_URL --env staging
gh secret set DATABASE_URL --env production

# Environment secret 목록
gh secret list --env production
```

**Organization Secret** (여러 저장소 공유):
```bash
# Organization 레벨 secret 설정 (admin 권한 필요)
gh secret set ORG_SECRET --org my-org --visibility all

# 특정 저장소만 접근 허용
gh secret set ORG_SECRET --org my-org --repos "repo1,repo2"
```

**로컬 테스트에서 Secret 사용**:
```bash
# .secrets 파일 (절대 커밋 금지!)
cat > .secrets << 'EOF'
NPM_TOKEN=npm_xxx
DOCKER_PASSWORD=xxx
DATABASE_URL=postgresql://user:pass@localhost/db  # pragma: allowlist secret
EOF

# act로 테스트
act --secret-file .secrets -j deploy

# 또는 명령줄에서 직접 전달
act --secret NPM_TOKEN=npm_xxx -j deploy

# GitHub Personal Access Token 사용
act --secret GITHUB_TOKEN=$(gh auth token) -j build
```

**Secret 디버깅**:
```yaml
# 워크플로우에서 secret 존재 확인 (값은 출력하지 말것!)
- name: Check secrets
  run: |
    if [ -z "${{ secrets.NPM_TOKEN }}" ]; then
      echo "::error::NPM_TOKEN is not set"
      exit 1
    fi
    echo "NPM_TOKEN is configured"
```

**보안 주의사항**:
```bash
# ❌ 절대 하지 말것
echo "${{ secrets.SECRET_KEY }}"  # 로그에 노출됨

# ✅ 안전한 방법
if [ -z "$SECRET_KEY" ]; then
  echo "::error::Secret not configured"
  exit 1
fi
```

### 4. Workflow Dispatch 트리거 문제

**증상**: `gh workflow run`이 "workflow_dispatch event not configured" 오류

**해결 방법**:
```yaml
# 워크플로우 파일에 workflow_dispatch 추가
on:
  push:
    branches: [main]
  workflow_dispatch:  # 이 부분 추가
    inputs:           # 선택사항
      debug:
        description: 'Enable debug mode'
        required: false
        default: 'false'
```

**변경사항 커밋 후 테스트**:
```bash
git add .github/workflows/ci.yml
git commit -m "feat: Add workflow_dispatch trigger"
git push

# 기본 브랜치에 머지된 후에만 동작
gh workflow run ci.yml
```

### 5. 권한 부족 문제

**증상**: "Resource not accessible by integration" 오류

**GITHUB_TOKEN 권한 확인 및 수정**:
```yaml
# 워크플로우에 명시적 권한 설정
permissions:
  contents: write      # 코드 변경 (커밋, 태그)
  packages: write      # 패키지 발행
  pull-requests: write # PR 코멘트
  issues: write        # Issue 생성/수정
  deployments: write   # 배포 상태 업데이트
```

**최소 권한 원칙** (보안 베스트 프랙티스):
```yaml
# Job별로 필요한 권한만 부여
jobs:
  build:
    permissions:
      contents: read   # 코드 읽기만
    steps:
      - uses: actions/checkout@v4

  publish:
    needs: build
    permissions:
      contents: read
      packages: write  # 패키지 발행에만 필요
    steps:
      - uses: docker/login-action@v3
```

**Personal Access Token (PAT) 사용** (GITHUB_TOKEN으론 부족할 때):
```yaml
steps:
  - uses: actions/checkout@v4
    with:
      token: ${{ secrets.PAT }}  # 더 넓은 권한 필요 시
```

```bash
# PAT 생성 (Settings > Developer settings > Personal access tokens)
# Fine-grained token 권장 (2024+)
gh secret set PAT
```

### 6. 캐시 관련 문제

**증상**: 빌드가 느리거나 캐시가 작동하지 않음

**의존성 캐싱 최적화**:
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'  # 자동 캐싱

# 또는 수동 캐싱
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

**캐시 무효화** (문제 발생 시):
```bash
# GitHub UI에서: Actions > Caches > 특정 캐시 삭제
# 또는 워크플로우에서 캐시 키 변경

# 캐시 목록 조회 (gh CLI 2.40+)
gh cache list

# 특정 캐시 삭제
gh cache delete <cache-id>

# 전체 캐시 삭제
gh cache delete --all
```

**Docker layer 캐싱**:
```yaml
- name: Build Docker image
  uses: docker/build-push-action@v6
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max  # 모든 레이어 캐싱
```

### 7. Timeout 문제

**증상**: 워크플로우가 timeout으로 실패

**Timeout 최적화**:
```yaml
jobs:
  test:
    timeout-minutes: 10  # Job 전체 timeout (기본값: 360분)
    steps:
      - name: Long running task
        timeout-minutes: 5  # Step별 timeout
        run: npm test
```

**로컬에서 실행 시간 측정**:
```bash
time act -j test  # 전체 실행 시간
```

**병렬 실행으로 속도 개선**:
```yaml
strategy:
  matrix:
    node-version: [18, 20, 22]
  max-parallel: 3  # 동시 실행 개수 제한
```

### 8. Concurrency 충돌

**증상**: 동일한 브랜치에서 여러 워크플로우가 동시 실행되어 충돌

**Concurrency 전략 설정**:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # 이전 실행 자동 취소
```

**배포 워크플로우** (취소하지 않도록):
```yaml
concurrency:
  group: deploy-${{ inputs.environment }}
  cancel-in-progress: false  # 배포 중엔 취소 금지
```

**실행 중인 워크플로우 확인 및 취소**:
```bash
# 실행 중인 워크플로우 확인
gh run list --status in_progress

# 특정 실행 취소
gh run cancel <run-id>

# 브랜치의 모든 실행 취소
for run in $(gh run list --branch feature-x --status in_progress --json databaseId -q '.[].databaseId'); do
  gh run cancel $run
done
```

### 9. Path 필터링 문제

**증상**: 코드 변경과 무관하게 워크플로우가 계속 실행됨

**Path 필터 최적화**:
```yaml
on:
  push:
    paths:
      - 'src/**'           # src 디렉토리만
      - 'package.json'     # 의존성 변경
      - '.github/workflows/ci.yml'  # 워크플로우 자체 변경
    paths-ignore:
      - 'docs/**'          # 문서 변경 무시
      - '**.md'            # Markdown 파일 무시
```

**로컬에서 path 필터 테스트**:
```bash
# 특정 파일 변경 시뮬레이션
git diff origin/main -- src/

# act는 path 필터를 완벽히 지원하지 않으므로
# 실제 GitHub에서 테스트 권장
```

### 10. Artifact 업로드/다운로드 문제

**증상**: Artifact가 생성되지 않거나 다운로드 실패

**Artifact 업로드**:
```yaml
- name: Upload test results
  uses: actions/upload-artifact@v4
  if: always()  # 실패해도 업로드
  with:
    name: test-results-${{ matrix.node-version }}
    path: |
      test-results/
      coverage/
    retention-days: 7  # 보관 기간 (기본: 90일)
```

**Artifact 다운로드** (다른 job에서):
```yaml
jobs:
  test:
    # ... 테스트 실행 및 artifact 업로드

  report:
    needs: test
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: test-results-20
          path: ./results
```

**gh CLI로 로컬에 다운로드**:
```bash
# 최근 실행의 모든 artifact 다운로드
gh run download

# 특정 실행의 artifact
gh run download <run-id>

# 특정 artifact만
gh run download <run-id> -n test-results-20

# Artifact 목록 확인
gh run view <run-id> --log | grep "Uploaded artifact"
```

**로컬 테스트 (act)**:
```bash
# act는 artifact를 로컬 디렉토리에 저장
mkdir -p /tmp/artifacts
act -j test --artifact-server-path /tmp/artifacts

# 업로드된 artifact 확인
ls -la /tmp/artifacts/
```

## 고급 사용법

### Reusable Workflows

**재사용 가능한 워크플로우 정의** (`.github/workflows/reusable-test.yml`):
```yaml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      coverage:
        required: false
        type: boolean
        default: false
    secrets:
      npm-token:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

      - run: npm ci
        env:
          NPM_TOKEN: ${{ secrets.npm-token }}

      - run: npm test

      - name: Coverage
        if: inputs.coverage
        run: npm run coverage
```

**재사용** (`.github/workflows/ci.yml`):
```yaml
jobs:
  test-node-18:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '18'
      coverage: true
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

### Composite Actions

**자체 Action 생성** (`.github/actions/setup-project/action.yml`):
```yaml
name: 'Setup Project'
description: 'Install dependencies and setup environment'

inputs:
  node-version:
    description: 'Node.js version'
    required: true
    default: '20'

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      shell: bash
      run: npm ci

    - name: Setup environment
      shell: bash
      run: |
        cp .env.example .env
        echo "Setup complete"
```

**사용**:
```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/setup-project
    with:
      node-version: '20'
```

### Matrix 전략 고급 활용

**동적 Matrix**:
```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: |
          echo "matrix={\"node\":[18,20,22],\"os\":[\"ubuntu-latest\",\"macos-latest\"]}" >> $GITHUB_OUTPUT

  test:
    needs: prepare
    strategy:
      matrix: ${{ fromJson(needs.prepare.outputs.matrix) }}
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

**Include/Exclude**:
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    node: [18, 20, 22]
    include:
      # 특정 조합에만 추가 변수
      - os: ubuntu-latest
        node: 20
        experimental: true
    exclude:
      # Windows에서 Node 18 제외
      - os: windows-latest
        node: 18
```

### 조건부 실행 패턴

**파일 변경 감지**:
```yaml
jobs:
  check-changes:
    runs-on: ubuntu-latest
    outputs:
      backend: ${{ steps.filter.outputs.backend }}
      frontend: ${{ steps.filter.outputs.frontend }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            backend:
              - 'backend/**'
            frontend:
              - 'frontend/**'

  test-backend:
    needs: check-changes
    if: needs.check-changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing backend"
```

**PR 라벨 기반 실행**:
```yaml
jobs:
  deploy:
    if: contains(github.event.pull_request.labels.*.name, 'deploy')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### 성능 모니터링

**빌드 시간 측정**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Record start time
        id: start
        run: echo "time=$(date +%s)" >> $GITHUB_OUTPUT

      - name: Build
        run: npm run build

      - name: Record end time
        run: |
          START=${{ steps.start.outputs.time }}
          END=$(date +%s)
          DURATION=$((END - START))
          echo "Build took $DURATION seconds"
          echo "build_duration=$DURATION" >> $GITHUB_STEP_SUMMARY
```

**리소스 사용량 모니터링**:
```yaml
- name: System info
  run: |
    echo "## System Resources" >> $GITHUB_STEP_SUMMARY
    echo "CPU: $(nproc)" >> $GITHUB_STEP_SUMMARY
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')" >> $GITHUB_STEP_SUMMARY
    echo "Disk: $(df -h / | awk 'NR==2 {print $2}')" >> $GITHUB_STEP_SUMMARY
```

## 체크리스트 상세 설명

### 보안 검증 체크리스트

#### 1. 액션 SHA Pinning

**왜 필요한가?**
- 브랜치/태그는 언제든 변경 가능 → 악의적 코드 주입 위험
- SHA는 불변 → 항상 동일한 코드 실행 보장

**적용 방법**:
```yaml
# ❌ 취약: 태그 사용
uses: actions/checkout@v4

# ✅ 안전: SHA pinning
uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332  # v4.1.7
```

**SHA 확인**:
```bash
# GitHub에서 릴리스 태그의 SHA 확인
gh api repos/actions/checkout/git/ref/tags/v4.1.7 --jq '.object.sha'

# 또는 웹에서: https://github.com/actions/checkout/releases/tag/v4.1.7
```

**도구 활용** (자동 pinning):
```bash
# GitHub App: Dependabot (Settings > Security > Dependabot)
# 또는 CLI 도구
npx pin-github-action .github/workflows/ci.yml
```

#### 2. 최소 권한 원칙

**기본 권한 비활성화**:
```yaml
# 저장소 설정: Settings > Actions > General > Workflow permissions
# "Read repository contents and packages permissions" 선택

# 또는 워크플로우별 설정
permissions: {}  # 모든 권한 제거

jobs:
  build:
    permissions:
      contents: read  # 필요한 권한만 명시
```

**권한 스코프**:
- `contents`: 코드 읽기/쓰기, 태그, 릴리스
- `packages`: 패키지 레지스트리
- `pull-requests`: PR 코멘트, 리뷰
- `issues`: Issue 생성/수정
- `deployments`: 배포 상태
- `checks`: Check run 생성/업데이트

#### 3. 시크릿 보호

**로그 노출 방지**:
```yaml
# ❌ 절대 금지
- run: echo "Token: ${{ secrets.TOKEN }}"

# ✅ 안전한 검증
- run: |
    if [ -z "$TOKEN" ]; then
      echo "::error::Token not configured"
      exit 1
    fi
  env:
    TOKEN: ${{ secrets.TOKEN }}
```

**시크릿 스캐닝 활성화**:
```bash
# Settings > Security > Secret scanning
# "Secret scanning" 활성화
# "Push protection" 활성화 (커밋 전 차단)
```

#### 4. OIDC 인증

**credential-less 배포**:
```yaml
permissions:
  id-token: write  # OIDC 토큰 발급
  contents: read

jobs:
  deploy:
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1

      # AWS CLI 사용 (credential 없이)
      - run: aws s3 sync ./dist s3://my-bucket/
```

**장점**:
- 장기 credential 불필요
- 자동 만료 (15분)
- IAM Role 기반 권한 관리

### 성능 최적화 체크리스트

#### 1. Timeout 설정

**권장값**:
```yaml
jobs:
  test:
    timeout-minutes: 10     # 유닛 테스트

  integration:
    timeout-minutes: 30     # 통합 테스트

  deploy:
    timeout-minutes: 15     # 배포
```

**Step별 timeout**:
```yaml
steps:
  - name: Install dependencies
    timeout-minutes: 5
    run: npm ci

  - name: Run tests
    timeout-minutes: 10
    run: npm test
```

#### 2. Concurrency 전략

**자동 취소**:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**효과**:
- 불필요한 중복 실행 방지
- GitHub Actions 분 절약
- 빠른 피드백

**배포는 예외**:
```yaml
concurrency:
  group: deploy-${{ inputs.environment }}
  cancel-in-progress: false  # 배포 중단 방지
```

#### 3. 캐싱 전략

**의존성 캐싱**:
```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'  # package-lock.json 기반 자동 캐싱

# 또는 수동
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: ${{ runner.os }}-npm-
```

**빌드 캐싱**:
```yaml
- uses: actions/cache@v4
  with:
    path: |
      .next/cache
      node_modules/.cache
    key: ${{ runner.os }}-build-${{ hashFiles('**/*.js', '**/*.jsx') }}
```

**Docker layer 캐싱**:
```yaml
- uses: docker/build-push-action@v6
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

#### 4. Path 필터링

**변경된 파일만 테스트**:
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
      - 'package.json'
    paths-ignore:
      - 'docs/**'
      - '**.md'
```

**효과**:
- 문서 변경 시 CI 스킵
- 관련 없는 파일 변경 시 실행 안 함

### 테스트 전략 체크리스트

#### 1. Matrix 테스트

**다중 환경 동시 테스트**:
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    node: [18, 20, 22]
  fail-fast: false  # 하나 실패해도 나머지 계속
```

**효과**:
- 9개 조합 동시 실행 (3 OS × 3 Node)
- 환경별 이슈 조기 발견

#### 2. Service Containers

**통합 테스트용 DB**:
```yaml
jobs:
  test:
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test  # pragma: allowlist secret
```

#### 3. 테스트 로그 품질

**명확한 실패 메시지**:
```yaml
- name: Run tests
  run: |
    npm test -- --verbose --coverage || {
      echo "::error::Tests failed. Check logs above."
      exit 1
    }
```

**Step summary 활용**:
```yaml
- name: Test results
  if: always()
  run: |
    echo "## Test Results" >> $GITHUB_STEP_SUMMARY
    echo "Total: $(jq '.numTotalTests' coverage/coverage-summary.json)" >> $GITHUB_STEP_SUMMARY
    echo "Passed: $(jq '.success' coverage/coverage-summary.json)" >> $GITHUB_STEP_SUMMARY
    echo "Failed: $(jq '.failed' coverage/coverage-summary.json)" >> $GITHUB_STEP_SUMMARY
```

### 유지보수성 체크리스트

#### 1. Reusable Workflows

**중복 제거**:
```yaml
# Before: 여러 워크플로우에서 동일한 steps 반복
# After: 재사용 가능한 워크플로우로 추출

# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        type: string
        required: true

jobs:
  deploy:
    environment: ${{ inputs.environment }}
    steps:
      # 공통 배포 로직
```

**사용**:
```yaml
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
```

#### 2. workflow_dispatch

**수동 실행 지원**:
```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version'
        required: true
      dry-run:
        description: 'Dry run mode'
        type: boolean
        default: false
```

**효과**:
- 긴급 배포 가능
- 테스트 용이
- 매개변수화된 실행

#### 3. 명확한 네이밍

**워크플로우 이름**:
```yaml
name: CI  # ❌ 너무 짧음
name: "Build, Test, and Deploy"  # ✅ 명확
```

**Job 이름**:
```yaml
jobs:
  test:  # ❌ 모호함
    name: "Unit Tests (Node ${{ matrix.node }})"  # ✅ 구체적
```

**Step 이름**:
```yaml
- run: npm ci  # ❌ 이름 없음
- name: Install dependencies  # ✅ 명확
  run: npm ci
```

## Official Resources

### Essential Documentation
- **GitHub Actions**: [Official Docs](https://docs.github.com/actions) - Complete reference for workflow syntax and features
- **Security Best Practices**: [Security Hardening](https://docs.github.com/actions/security-guides/security-hardening-for-github-actions) - SHA pinning, permissions, OIDC
- **act Documentation**: [nektos/act](https://github.com/nektos/act) - Local testing tool
- **gh CLI Manual**: [GitHub CLI](https://cli.github.com/manual/gh_workflow) - Workflow management commands

### Community Resources
- **Awesome Actions**: [sdras/awesome-actions](https://github.com/sdras/awesome-actions) - Curated list of actions
- **Action Examples**: [actions/starter-workflows](https://github.com/actions/starter-workflows) - Official templates
- **Marketplace**: [GitHub Actions Marketplace](https://github.com/marketplace?type=actions) - Pre-built actions

### Security Tools
- **Dependabot**: [Automated dependency updates](https://docs.github.com/code-security/dependabot)
- **CodeQL**: [Code scanning](https://docs.github.com/code-security/code-scanning)
- **Secret Scanning**: [Detect exposed secrets](https://docs.github.com/code-security/secret-scanning)

## Quick Reference

### act 명령어 치트시트

```bash
# 기본 실행
act                                    # push 이벤트로 실행
act pull_request                       # PR 이벤트
act -j test                           # 특정 job만

# 옵션
act -n                                # Dry-run
act -v                                # Verbose
act -W .github/workflows/ci.yml       # 특정 워크플로우
act --list                            # 실행 가능한 job 목록

# 환경 설정
act --env-file .env                   # 환경 변수
act --secret-file .secrets            # 시크릿
act --secret KEY=value                # 명령줄 시크릿
act -P ubuntu-latest=image:tag        # 커스텀 이미지

# 이벤트
act -e event.json                     # 이벤트 파일
act workflow_dispatch -j deploy       # workflow_dispatch

# 디버깅
act --reuse                           # 컨테이너 재사용
act -b                                # Bind 마운트
act --container-architecture linux/amd64  # 아키텍처 지정
```

### gh run 명령어 치트시트

```bash
# 조회
gh run list                           # 실행 목록
gh run list --workflow=ci.yml         # 특정 워크플로우
gh run list --status=in_progress      # 상태 필터
gh run list --limit 10                # 개수 제한
gh run view <run-id>                  # 실행 상세
gh run view <run-id> --log            # 로그 출력
gh run view <run-id> --log-failed     # 실패 로그만

# 제어
gh run watch                          # 실시간 모니터링
gh run rerun <run-id>                 # 재실행
gh run rerun <run-id> --failed        # 실패한 job만
gh run cancel <run-id>                # 취소
gh run download <run-id>              # Artifact 다운로드
gh run download <run-id> -n name      # 특정 Artifact
```

### gh workflow 명령어 치트시트

```bash
# 조회
gh workflow list                      # 워크플로우 목록
gh workflow view ci.yml               # 워크플로우 요약
gh workflow view ci.yml --yaml        # YAML 출력
gh workflow view ci.yml --web         # 브라우저에서 열기

# 실행
gh workflow run ci.yml                # 트리거
gh workflow run ci.yml --ref branch   # 특정 브랜치
gh workflow run ci.yml -f key=value   # 입력 변수

# 제어
gh workflow enable ci.yml             # 활성화
gh workflow disable ci.yml            # 비활성화
```

### gh secret 명령어 치트시트

```bash
# Repository secret
gh secret list                        # Secret 목록
gh secret set NAME                    # 입력받아 설정
gh secret set NAME < file.txt         # 파일에서 읽기
gh secret set NAME --body "value"     # 값 직접 전달
gh secret delete NAME                 # 삭제

# Environment secret
gh secret list --env production       # 환경별 목록
gh secret set NAME --env production   # 환경별 설정
gh secret delete NAME --env staging   # 환경별 삭제

# Organization secret (admin 권한 필요)
gh secret set NAME --org my-org --visibility all
gh secret set NAME --org my-org --repos "repo1,repo2"
```

### 문제 해결 플로우차트

```
CI 실패
  ├─ 로그 확인: gh run view <id> --log-failed
  ├─ 로컬 재현: act -j <job> -v
  ├─ 원인 파악
  │   ├─ 테스트 실패 → 코드 수정
  │   ├─ 빌드 오류 → 의존성/환경 확인
  │   ├─ Secret 누락 → gh secret set
  │   ├─ 권한 부족 → permissions 설정
  │   └─ Timeout → timeout-minutes 증가
  └─ 수정 후 재테스트: act → push → gh run watch

Merge Conflict
  ├─ git fetch origin main
  ├─ git rebase origin/main
  ├─ Conflict 해결
  ├─ act push (로컬 검증)
  └─ git push --force-with-lease

Secret 문제
  ├─ gh secret list (존재 확인)
  ├─ gh secret set NAME (설정/업데이트)
  ├─ 워크플로우에서 검증 step 추가
  └─ act --secret-file .secrets (로컬 테스트)
```
