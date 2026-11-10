# Repository Guidelines

## 프로젝트 구조와 모듈 배치

구조 참고 기준은 [Misterio77/nix-starter-configs의 standard](https://github.com/Misterio77/nix-starter-configs/tree/main/standard)입니다. **flake-parts는 유지**하며, 기존 호스트·사용자 구성에 필요한 부분만 반영합니다.

- `flake.nix`는 입력과 지원 플랫폼을 선언하고, `flake-modules/`가 flake-parts로 호스트 선언과 출력을 구성합니다. `lib/`에는 시스템 생성과 모듈 탐색 같은 공통 로직을 둡니다.
- `pkgs/default.nix`는 커스텀 패키지를 정의하고, `flake-modules/packages.nix`가 패키지 출력으로 연결합니다. 사용자에게 설치할 패키지 목록은 `users/shared/packages/`에 둡니다.
- `overlays/default.nix`는 `additions`, `modifications`, `worktree`를 이름으로 공개합니다. 적용 순서는 이 순서대로 명시하며, `flake-modules/args.nix`에서 개발용 패키지와 시스템 구성에 전달합니다.
- 호스트별 설정과 기능 선택은 `machines/`, 공유 사용자 설정은 `users/shared/`에 둡니다. `users/shared/programs/`와 `users/shared/packages/`의 `<name>.nix` 또는 `<name>/default.nix`는 자동으로 발견됩니다. 도구별 설정 자산은 해당 프로그램 디렉터리에 함께 둡니다.
- 운영 스크립트는 `scripts/`, 설계 기록은 `docs/`, 테스트는 `tests/`에 둡니다. 설정 정책과 패키지·의존성 선언은 Nix가 소유하고, 스크립트는 준비·빌드·적용 실행을 담당합니다.

`modules/nixos/`와 `modules/home-manager/` 공개 출력은 다른 저장소에서 재사용할 모듈이 실제로 필요할 때 추가합니다. 템플릿과 이름만 맞추기 위한 디렉터리 이동이나 빈 구조는 추가하지 않습니다.

## 빌드·테스트·개발 명령

Nix flakes와 Git을 준비하고 다음 명령을 사용하세요.

| 명령                                                    | 용도                                   |
| ------------------------------------------------------- | -------------------------------------- |
| `nix develop`                                           | 저장소 개발 도구가 포함된 셸 실행      |
| `make install-hooks`                                    | pre-commit 및 pre-push 훅 설치         |
| `nix flake check --no-build --all-systems --show-trace` | 지원 플랫폼 전체 평가                  |
| `make test-build`                                       | 현재 플랫폼의 단위·통합 assertion 빌드 |
| `./switch.sh --build`                                   | 호스트 설정을 활성화 없이 빌드         |

`./bootstrap.sh [host]`는 도구와 기존 age identity를 준비하고, `./switch.sh [host]`는 시스템에 설정을 적용합니다. 독립 Home Manager는 `HM_USER=jito.hello ./switch.sh --home`으로 적용합니다. 적용 명령은 실제 사용자 환경을 변경하므로 빌드 검증과 구분하세요.

## 코드 스타일과 이름 규칙

`.editorconfig`를 따르세요. Nix·셸·YAML·JSON은 공백 2칸, Python은 4칸, Makefile 레시피는 탭을 사용합니다. UTF-8, LF, 파일 끝 개행을 유지하세요.

`make format`은 treefmt를 통해 nixfmt, statix, deadnix, shfmt, Prettier를 실행합니다. `make lint`는 ShellCheck와 bashate를 포함한 pre-commit 검사를 실행합니다. 파일명은 기존의 설명적인 소문자·하이픈 패턴을 따르세요. 공유 구현은 `users/shared/`에, 호스트별 기능 선택은 머신 모듈에 둡니다.

## 테스트 작성 지침

테스트는 assertion 성공 시 빌드되는 Nix derivation입니다. `tests/unit/`와 `tests/integration/`에 `<feature>-test.nix`를 추가하고 `tests/lib/test-helpers.nix`의 `assertTest`와 `testSuite`를 활용하세요.

실제 모듈의 동작과 설정 간 불변조건을 검증하세요. 테스트 안에서 정의한 값만 재확인하는 assertion은 피하세요. 상세 계약은 `tests/README.md`를 확인하세요. 수치형 커버리지 기준은 지정되어 있지 않습니다.

`make test`는 Linux와 `/dev/kvm`이 없으면 평가만 수행합니다. assertion 실행은 `make test-build`로 확인하세요. VM 테스트는 Linux와 KVM에서 `make test-containers`로 실행합니다.

## 커밋과 Pull Request

최근 이력처럼 `fix(ci): ...`, `feat(darwin): ...`, `chore: ...` 형식을 사용하세요. 변경 목적이 드러나는 짧은 제목을 작성하고 커밋 범위를 한 가지 작업으로 제한하세요.

PR은 `.github/pull_request_template.md`를 따라 요약, 구체적 변경사항, 실행한 검증 명령과 결과, 검증 플랫폼을 기록하세요. 관련 문서를 갱신하고 새로운 의존성은 사전에 논의하세요.

## 비밀정보와 설정

개인 키와 복호화된 데이터는 저장소 및 Nix store 밖에 보관하세요. `--age-key-ref`에는 키 자체가 아닌 1Password 참조를 전달합니다. 호스트 사용자는 `flake-modules/hosts.nix`에서 선언하며, `HM_USER`는 독립 Home Manager 프로필만 선택합니다.
