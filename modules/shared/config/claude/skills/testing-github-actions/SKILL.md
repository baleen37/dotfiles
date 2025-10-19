---
name: Testing GitHub Actions
description: Tests and validates GitHub Actions workflows locally using act and gh CLI. Use when developing, debugging, or validating CI/CD workflows before pushing to GitHub.
allowed-tools: [Bash, Read, Write, Grep, Glob]
---

# Testing GitHub Actions

GitHub Actions 워크플로우를 로컬 테스트(act) 및 원격 제어(gh CLI)하는 스킬입니다.

## Core Workflow

### 1. 테스트 전략

**우선순위**: act 로컬 검증 → gh 원격 실행 → gh run watch 모니터링

### 2. act 로컬 테스트

**기본 명령어**:

```bash
act                          # 전체 실행
act -j <job-name>           # 특정 job
act -n                      # Dry-run
act -v                      # Verbose
```

**환경 설정**:

```bash
act --env-file .env --secret-file .secrets
echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" > .actrc
```

### 3. gh CLI 원격 제어

**실행 및 모니터링**:

```bash
gh workflow run <workflow.yml> --ref <branch> -f key=value
gh run watch
gh run list --workflow=<workflow.yml> --limit 5
gh run view <run-id> --log-failed
```

**재실행 및 아티팩트**:

```bash
gh run rerun <run-id> --failed
gh run download <run-id> -n <artifact-name>
```

### 4. 품질 체크리스트

**보안**:

- [ ] Action SHA pinning (`uses: actions/checkout@<sha>`)
- [ ] GITHUB_TOKEN 최소 권한 (`permissions:`)
- [ ] Secret 로그 노출 방지

**성능**:

- [ ] `timeout-minutes: 10-30` (기본 360분 대신)
- [ ] `concurrency` 중복 실행 취소
- [ ] 의존성 캐싱 (`cache: 'npm'`)
- [ ] `paths` 필터링

**테스트**:

- [ ] `matrix` 다중 환경
- [ ] Service containers (DB 등)
- [ ] 명확한 실패 로그

**유지보수**:

- [ ] Reusable workflows
- [ ] `workflow_dispatch` 트리거
- [ ] 명확한 네이밍

### 5. 문제 해결

**일반적 오류**:

- `Docker daemon not running` → Docker 실행
- `workflow_dispatch event not configured` → `on.workflow_dispatch` 추가
- `Resource not accessible` → `permissions` 설정
- `Secret not found` → `gh secret set` 또는 `.secrets` 파일

**디버깅**:

```bash
# 로컬
act --reuse -v

# 원격
gh secret set ACTIONS_STEP_DEBUG --body "true"
gh run view <run-id> --log
```

**Conflict 해결**:

```bash
git fetch origin main
git rebase origin/main
# ... conflict 해결 ...
act push  # 로컬 검증
git push --force-with-lease
```

**CI 실패 프로세스**:

1. `gh run view <id> --log-failed` (로그 분석)
2. `act -j <job> -v` (로컬 재현)
3. 수정 후 `act` 검증
4. Push → `gh run watch`

**Secret 설정**:

```bash
gh secret set <NAME>              # Repository
gh secret set <NAME> --env prod   # Environment
cat .secrets  # 로컬: KEY=value (절대 커밋 금지)
```

### 6. 개발 사이클

1. 워크플로우 작성/수정
2. `act -n` (dry-run)
3. `act` (로컬 테스트)
4. 체크리스트 검증
5. 커밋 & 푸시
6. `gh run watch`

## Validation

- Docker 실행 중? (act용)
- `.secrets` 파일 제공? (로컬용)
- `workflow_dispatch` 트리거 정의? (gh용)
- 체크리스트 충족?

## Success Criteria

- act 로컬 실행 성공
- 보안/성능 체크리스트 통과
- GitHub 실제 실행 정상
- commit-push-wait → test-commit-push 사이클 전환

## Reference

상세 가이드: `reference.md` (설치, 예제, 고급 기법, 트러블슈팅)
