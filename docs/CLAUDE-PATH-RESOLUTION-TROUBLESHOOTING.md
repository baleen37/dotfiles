# Claude 설정 경로 해결 문제 트러블슈팅 가이드

## 문제 개요

Claude Code 설정 파일들이 제대로 심볼릭 링크되지 않아 명령어나 에이전트가 누락되는 문제를 해결하는 가이드입니다.

## 증상

- `/do-todo` 같은 특정 Claude 명령어가 사용 불가능
- 새로 추가된 명령어 파일들이 Claude Code에서 인식되지 않음
- 심볼릭 링크가 잘못된 디렉토리를 가리킴

## 근본 원인

dotfiles 디렉토리가 여러 위치에 존재할 때, Claude 활성화 스크립트가 불완전한 디렉토리를 우선 선택하는 문제였습니다.

### 문제 상황

- `~/dotfiles` (불완전) - 일부 파일 누락
- `~/dev/dotfiles` (완전) - 모든 파일 존재

기존 로직은 첫 번째로 발견한 디렉토리를 무조건 사용했습니다.

## 해결 방법

### 1. 자동 수정 (권장)

```bash
# 빌드를 다시 실행하면 자동으로 수정됩니다
export USER=$(whoami) && ./apps/aarch64-darwin/build-switch
```

### 2. 수동 확인 및 수정

```bash
# 현재 심볼릭 링크 상태 확인
readlink ~/.claude/commands

# 올바른 경로인지 확인 (~/dev/dotfiles여야 함)
ls -la ~/.claude/commands/do-todo.md

# 잘못된 경우 수동 수정
rm ~/.claude/commands
ln -sf ~/dev/dotfiles/modules/shared/config/claude/commands ~/.claude/commands
```

### 3. 문제 진단

```bash
# 경로 해결 로직 테스트
./tests/unit/test-claude-symlink-path-resolution.sh

# 통합 테스트 실행
./tests/integration/test-claude-activation-integration.sh
```

## 예방 방법

### 1. 단일 dotfiles 위치 유지

가능하면 dotfiles를 한 곳에만 유지:

```bash
# 권장 위치
~/dev/dotfiles/
```

### 2. 정기적인 검증

빌드 후 항상 확인:

```bash
# 모든 필수 명령어가 있는지 확인
ls ~/.claude/commands/do-todo.md
ls ~/.claude/commands/analyze.md
ls ~/.claude/commands/build.md
```

## 개선된 해결 로직

### 기존 로직

```bash
if [[ -d "$SOURCE_DIR" ]]; then
    # 존재하면 무조건 사용 (문제)
    use_directory "$SOURCE_DIR"
fi
```

### 개선된 로직  

```bash
if [[ -d "$SOURCE_DIR" ]] && validate_completeness "$SOURCE_DIR"; then
    # 존재하고 완전할 때만 사용 (해결)
    use_directory "$SOURCE_DIR"
else
    # fallback으로 완전한 디렉토리 찾기
    find_complete_fallback_directory
fi
```

### 검증 기준

다음 파일들의 존재를 확인합니다:

- `CLAUDE.md`
- `settings.json`
- `commands/` 디렉토리
- 핵심 명령어 파일들:
  - `analyze.md`
  - `build.md`
  - `do-todo.md`
  - `implement.md`
  - `test.md`

## 로그 해석

### 정상 동작 로그

```text
✓ 기본 소스 디렉토리가 완전함: /Users/baleen/dev/dotfiles/modules/shared/config/claude
✓ commands 폴더 검증 통과 (27개 명령어 파일)
✓ 모든 핵심 명령어 파일 존재 확인
✓ do-todo.md 파일 접근 가능 확인
```

### 문제 상황 로그

```text
⚠ 기본 소스 디렉토리가 불완전함: /Users/baleen/dotfiles/modules/shared/config/claude
  누락된 핵심 명령어: do-todo.md
✓ 완전한 Fallback 소스 발견: /Users/baleen/dev/dotfiles/modules/shared/config/claude
```

## 관련 파일

- **구현**: `modules/shared/lib/claude-activation.nix`
- **단위 테스트**: `tests/unit/test-claude-symlink-path-resolution.sh`
- **통합 테스트**: `tests/integration/test-claude-activation-integration.sh`

## 추가 도움

문제가 지속되면:

1. 테스트 실행으로 상태 확인
2. 로그에서 실제 사용된 디렉토리 확인
3. 수동으로 올바른 심볼릭 링크 생성
4. 필요시 불완전한 dotfiles 디렉토리 제거 고려

---

*이 가이드는 TDD 방식으로 문제를 해결한 과정을 문서화한 것입니다.*
