# Codebase Health Checkup: Doc Alignment & Dead Code Cleanup

Date: 2026-05-13
Branch: `refactor/improve-structure`

## Goal

이미 두 번의 대규모 리팩토링(2026-04-10 파일 분할, 2026-04-17 flake-parts 마이그레이션)을 거친 건강한 코드베이스에 남아 있는 두 종류의 잔재를 정리한다.

1. **문서-현실 괴리**: README/CONTRIBUTING이 존재하지 않는 Make 타겟을 안내하고, `.envrc`가 USER를 자동화하지 못해 매번 manual export를 요구함
2. **이전 리팩토링이 남긴 작은 잔재**: 사용되지 않는 헬퍼 파일, 거짓 의존 신호, 흩어진 테스트 문서

모든 변경은 외과적이고 가역적이며, 회귀가 없어야 한다.

## Non-Goals

- 새 기능 추가
- 큰 구조 변경 (3단계 항목 — `apps` 출력 추가, e2e 정리, cache-sync 테스트 승격 — 은 별도 동기가 생겼을 때 다시 검토)
- 의도된 패턴 손대기 (test fixture의 dead let 바인딩, 플랫폼 규약상 다른 stateVersion 표기 등)
- 새 의존성 추가

## Scope

총 9-11개 파일 변경, 신규 0개, 삭제 1개.

### Stage 1 — Doc-Reality Alignment

#### 1.1 Makefile: 3개 타겟 추가

문서가 안내하는 명령 중 실제로 자주 쓰이는 3개만 별칭으로 추가한다.

```makefile
install-hooks:
	pre-commit install --hook-type pre-commit --hook-type pre-push

lint:
	pre-commit run --all-files

update:
	nix flake update
```

`make build`, `make build-darwin`, `make build-linux`, `make vm`은 추가하지 않는다. `nix build '.#...'` 직접 호출로 충분하고, Makefile에 alias를 추가하면 그것대로 또 표류한다. 대신 README가 직접 호출 방식으로 안내하도록 수정한다.

#### 1.2 README.md / CONTRIBUTING.md 수정

- `make build`, `make build-darwin`, `make build-linux`, `make vm` 참조를 `nix build '.#darwinConfigurations.<name>.system'` 같은 직접 호출로 교체
- 새로 생긴 `make install-hooks`, `make lint`, `make update`는 그대로 사용 가능
- "Required before any Nix commands" 문구를 "direnv 사용 시 자동, 그 외에는 export USER=$(whoami)" 로 완화

#### 1.3 nixfmt 일괄 적용

`make format`을 1회 실행해 다음 9개 파일을 정렬한다.

- flake.nix
- lib/mksystem.nix
- flake-modules/dev-shells.nix
- flake-modules/checks.nix
- flake-modules/packages.nix
- users/shared/zsh/env.nix
- users/shared/zsh/functions.nix
- users/shared/zsh/ssh-agent.nix
- users/shared/ghostty.nix

이전 리팩토링 후 pre-commit이 우회된 흔적. 1회 정렬로 베이스라인 회복.

#### 1.4 `.envrc`: USER 자동화

```bash
# Before
use flake

# After
export USER=${USER:-$(whoami)}
use flake
```

`${USER:-…}` 형태라 명시적 override를 보존한다 (다른 USER로 빌드하는 시나리오 영향 없음).

### Stage 2 — Dead Code Removal

#### 2.1 `tests/lib/test-helpers-darwin.nix` 삭제

- 현황: 161줄, 어떤 테스트에서도 import되지 않음. `darwin-test-helpers.nix`(514줄, 실제 사용)와 함수 정의가 중복됨
- 검증: `grep -rn "test-helpers-darwin" tests/`로 사용처 0 확인 후 삭제
- `tests/lib/test-helpers.nix` 내부에 이 파일을 언급하는 주석/import가 있다면 함께 정리

#### 2.2 `users/shared/claude-code.nix` 파라미터 정리

```nix
# Before
{ pkgs, lib, ... }:
{ }

# After
_: { }
```

거짓 의존 신호 제거. 14줄 파일이므로 변경 폭 최소.

#### 2.3 테스트 문서 통합

현재 3개 파일이 같은 주제를 다룸:
- `tests/README.md` (1890줄, 자동 발견 패턴 설명, 가장 최신)
- `tests/TESTING_GUIDE.md` (585줄)
- `docs/testing-guide.md` (475줄, 구식 파일명 나열)

처리:
- `tests/README.md`를 canonical source로 지정
- `docs/testing-guide.md`는 삭제하고, `docs/` 안의 다른 문서에서 이 파일을 링크하는 곳을 `tests/README.md`로 갱신
- `tests/TESTING_GUIDE.md`는 `tests/README.md`와 겹치는 내용은 제거하고 보완 정보만 남기거나 통합 후 삭제 (실제 내용 비교 후 작업 시 결정)

링크 깨짐 검증: `fd -e md | xargs grep -l 'testing-guide\|TESTING_GUIDE'`

## Verification Plan

각 변경을 독립적으로 검증한다.

1. **Makefile 신규 타겟**:
   - `make install-hooks` → pre-commit hooks 설치됨
   - `make lint` → pre-commit 전체 통과 또는 실제 issue 보고
   - `make update --dry-run` 또는 `make -n update`로 호출 검증
2. **README/CONTRIBUTING**: 변경한 명령을 셸에서 그대로 1회 실행해 동작 확인
3. **nixfmt 일괄**: `make format && git diff --quiet`로 idempotent 확인
4. **`.envrc`**: `direnv reload && [ -n "$USER" ]`
5. **test-helpers-darwin.nix 삭제**: `make test-all` PASS
6. **claude-code.nix**: `nix build '.#homeConfigurations."jito.hello".activationPackage' --impure --dry-run` 성공
7. **문서 통합**: 통합 후 `fd -e md | xargs grep -l 'docs/testing-guide.md'` 결과 0개
8. **전체 회귀**: `make test-all` PASS + `pre-commit run --all-files` PASS

## Rollback Plan

각 변경이 독립 커밋이므로 단일 `git revert <sha>`로 되돌릴 수 있다. 삭제된 파일(`test-helpers-darwin.nix`, `docs/testing-guide.md`)도 git history에서 복원 가능.

## Out of Scope (Audit이 발견했으나 이번엔 손대지 않음)

문서화만 해두고 손대지 않을 항목:

- **flake outputs `apps` 부재**: `nix run .#build-switch` 표준화 가치 있으나 별도 작업
- **e2e 23개 실행 매핑**: 일부가 CI에서 안 도는 듯하지만 정확한 매핑 조사 필요
- **cache-config sync 검증**: pre-commit script → `nix flake check` 테스트 승격
- **deadnix가 잡은 ~20개 test let 바인딩**: 의도된 fixture/시그니처 — 손대면 가독성 손해
- **`flake.lock` 간접 nixpkgs node**: 제어 밖 (간접 의존)
- **machines stateVersion 표기 차이**: 플랫폼 규약대로라 정상
