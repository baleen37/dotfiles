# Claude Commands 테스트 가이드

Claude commands git 파일 이동 문제 해결을 위한 포괄적인 테스트 스위트입니다.

## 🎯 테스트 목적

`nix run #build-switch` 실행 시 Claude commands의 git 관련 파일들이 서브디렉토리(`commands/git/`)에서 `~/.claude/commands/git/`로 올바르게 복사되는지 검증합니다.

## 📁 테스트 구조

```text
tests/
├── run-claude-tests.sh           # 통합 테스트 러너
├── unit/
│   └── test-claude-activation.sh # 단위 테스트
├── integration/
│   └── test-build-switch-claude-integration.sh # 통합 테스트
├── e2e/
│   └── test-claude-commands-end-to-end.sh # E2E 테스트
└── TESTING_GUIDE.md              # 이 파일
```

## 🚀 빠른 시작

### 모든 테스트 실행

```bash
# 프로젝트 루트에서 실행
./tests/run-claude-tests.sh
```

### 개별 테스트 실행

```bash
# 단위 테스트만
./tests/run-claude-tests.sh --unit-only

# 통합 테스트만  
./tests/run-claude-tests.sh --integration-only

# E2E 테스트만
./tests/run-claude-tests.sh --e2e-only

# 상세 출력으로 모든 테스트
./tests/run-claude-tests.sh --verbose
```

## 📋 테스트 종류

### 1. 단위 테스트 (Unit Tests)

**파일**: `tests/unit/test-claude-activation.sh`

**검증 내용**:

- ✅ 서브디렉토리 지원 기능
- ✅ 디렉토리 구조 보존
- ✅ 파일 내용 무결성
- ✅ Dry run 모드
- ✅ 존재하지 않는 소스 파일 처리

**직접 실행**:

```bash
./tests/unit/test-claude-activation.sh
```

### 2. 통합 테스트 (Integration Tests)

**파일**: `tests/integration/test-build-switch-claude-integration.sh`

**검증 내용**:

- ✅ Claude 디렉토리 생성
- ✅ Git commands 파일 통합
- ✅ 메인 설정 파일 처리
- ✅ Agent 파일 통합
- ✅ 파일 권한 설정
- ✅ 통합 완성도

**직접 실행**:

```bash
./tests/integration/test-build-switch-claude-integration.sh
```

### 3. E2E 테스트 (End-to-End Tests)

**파일**: `tests/e2e/test-claude-commands-end-to-end.sh`

**검증 시나리오**:

- 🆕 **첫 번째 설정**: 새로운 사용자가 dotfiles를 처음 설정
- 🔄 **업데이트**: 기존 설정이 있는 상태에서 업데이트
- 🔧 **Git 워크플로우**: git commands 실제 사용 가능성
- 📁 **다중 서브디렉토리**: 여러 레벨의 서브디렉토리 처리
- 🧹 **정리**: 소스에서 제거된 파일들의 정리

**직접 실행**:

```bash
./tests/e2e/test-claude-commands-end-to-end.sh
```

## 🎯 테스트가 검증하는 핵심 기능

### 서브디렉토리 지원

이전에는 `modules/shared/config/claude/commands/*.md` 패턴만 처리했지만, 이제는 `find`를 사용하여 모든 서브디렉토리의 `.md` 파일을 처리합니다:

```bash
# 기존 (서브디렉토리 미지원)
for cmd_file in "$SOURCE_DIR/commands"/*.md; do
    # git/ 서브디렉토리 파일들 무시됨
done

# 개선 (서브디렉토리 지원)
find "$SOURCE_DIR/commands" -name "*.md" -type f | while read -r cmd_file; do
    # 모든 서브디렉토리 파일들 처리됨
done
```

### Git Commands 특별 검증

다음 git command 파일들이 올바르게 복사되는지 확인합니다:

- `commands/git/commit.md` → `~/.claude/commands/git/commit.md`
- `commands/git/fix-pr.md` → `~/.claude/commands/git/fix-pr.md`
- `commands/git/upsert-pr.md` → `~/.claude/commands/git/upsert-pr.md`

### 사용자 수정사항 보존

중요한 설정 파일들(`CLAUDE.md`, `settings.json`)의 사용자 수정사항은 보존하고, 새 버전은 `.new` 파일로 저장합니다.

## 🔧 테스트 환경 요구사항

### 필수 도구

- `bash` (4.0+)
- `find`
- `shasum` 또는 `sha256sum` (해시 검증용)
- 기본적인 Unix 도구들 (`mkdir`, `cp`, `chmod`, etc.)

### 필수 디렉토리 구조

테스트가 성공하려면 다음 구조가 있어야 합니다:

```text
modules/shared/config/claude/
├── CLAUDE.md
├── settings.json
├── commands/
│   ├── *.md (루트 레벨 명령어들)
│   └── git/
│       ├── commit.md
│       ├── fix-pr.md
│       └── upsert-pr.md
└── agents/
    └── *.md (에이전트 파일들)
```

## 📊 테스트 결과 해석

### 성공 사례

```text
================= E2E 테스트 결과 =================
통과: 25
모든 E2E 테스트가 통과했습니다! 🎉
Claude commands git 파일들이 완전히 작동합니다.

검증된 기능:
✅ 첫 번째 설정 시나리오
✅ 업데이트 및 사용자 수정사항 보존
✅ Git 워크플로우 완전 지원
✅ 다중 서브디렉토리 처리
✅ 전체 시스템 통합
```

### 실패 사례

실패한 경우 상세한 디버그 정보가 출력됩니다:

```text
================= 디버그 정보 ==================
테스트 Claude 디렉토리 내용:
/tmp/test_123/.claude/commands/task.md
/tmp/test_123/.claude/CLAUDE.md
# git/ 디렉토리 파일들이 없음 - 서브디렉토리 처리 실패
```

## 🐛 문제 해결

### 공통 문제들

1. **권한 오류**

   ```bash
   chmod +x tests/**/*.sh
   ```

2. **Git commands 파일 누락**
   - `modules/shared/config/claude/commands/git/` 디렉토리 확인
   - 필요한 `.md` 파일들이 있는지 확인

3. **해시 도구 없음**
   - macOS: `shasum` 사용
   - Linux: `sha256sum` 설치
   - Fallback: 파일 크기 비교 사용

### 디버그 모드

상세한 출력을 보려면 `--verbose` 옵션을 사용하세요:

```bash
./tests/run-claude-tests.sh --verbose
```

## 🔄 CI/CD 통합

### GitHub Actions 예시

```yaml
name: Claude Commands Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Claude Commands Tests
        run: ./tests/run-claude-tests.sh --verbose
```

### 로컬 개발 워크플로우

```bash
# 변경사항 테스트
git add .
./tests/run-claude-tests.sh

# 특정 기능만 테스트
./tests/run-claude-tests.sh --unit-only

# 커밋 전 전체 검증
./tests/run-claude-tests.sh --verbose
git commit -m "feat: claude commands 서브디렉토리 지원 추가"
```

## 📈 테스트 확장

새로운 명령어나 서브디렉토리를 추가할 때:

1. **단위 테스트에 추가**:

   ```bash
   # test-claude-activation.sh에 새 테스트 케이스 추가
   test_new_subdirectory_support() {
       # 새 서브디렉토리 테스트 로직
   }
   ```

2. **E2E 테스트에 시나리오 추가**:

   ```bash
   # test-claude-commands-end-to-end.sh에 새 시나리오 추가
   simulate_new_feature_scenario() {
       # 새 기능 시나리오 테스트
   }
   ```

3. **통합 테스트에 검증 추가**:

   ```bash
   # 새 파일들이 올바르게 복사되는지 확인
   test_new_commands_integration() {
       # 새 명령어들 통합 테스트
   }
   ```

## 💡 팁과 요령

### 효율적인 테스트 실행

```bash
# 개발 중에는 단위 테스트만 빠르게 실행
./tests/run-claude-tests.sh --unit-only

# 완전한 검증이 필요할 때는 E2E 테스트
./tests/run-claude-tests.sh --e2e-only

# PR 전에는 전체 테스트
./tests/run-claude-tests.sh --verbose
```

### 테스트 데이터 정리

테스트는 자동으로 임시 파일들을 정리하지만, 수동으로 정리하려면:

```bash
# 임시 디렉토리들 정리
rm -rf /tmp/test_*
rm -rf /tmp/claude_test_*
```

## 📚 참고 자료

- [Claude-activation.nix 소스 코드](../modules/shared/lib/claude-activation.nix)
- [Build-switch 통합](../modules/darwin/home-manager.nix#L76-78)
- [Git Commands 파일들](../modules/shared/config/claude/commands/git/)

---

**문제가 있거나 개선 제안이 있으시면 이슈를 생성해주세요!** 🚀
