# `bgc` macOS Cache Cleanup Design

## Goal

macOS에서 재생성 가능한 개발 캐시와 대형 사용자 캐시를 한 번에 점검하고 정리할 수 있는 `bgc` zsh 명령을 제공한다. 기존 `gc` alias (`git commit`)와 충돌하지 않아야 한다.

## User experience

- `bgc stats`: 삭제 후보별 예상 용량을 출력하고 종료한다.
- `bgc --dry-run`: 삭제하지 않고 각 후보의 현재 용량과 실행 예정 작업을 출력한다.
- `bgc`: 통계를 출력한 뒤 일반 후보를 정리할지 묻는다. 승인 후 정리하고, Docker는 별도로 한 번 더 묻는다.
- `bgc help`: 사용법과 안전 경계를 출력한다.
- 인자를 알 수 없으면 사용법을 출력하고 실패한다.
- 사용자가 확인 질문에 `y`가 아닌 답을 하면 해당 단계는 건너뛴다.

## Cleanup scope

일반 후보는 모두 재생성 가능한 사용자 캐시만 포함한다.

- Homebrew 다운로드 캐시: `brew cleanup`
- Nix store의 미사용 경로: `nix store gc`
- Node 계열 캐시: npm, pnpm, yarn
- Python 계열 캐시: uv, pip
- Gradle 캐시
- Xcode `DerivedData`
- 사용자 `~/Library/Caches` 아래의 캐시 내용

Docker는 데이터 손실 가능성이 더 크므로 일반 후보와 분리한다. Docker 정리 단계에서는 중지된 컨테이너, dangling 이미지, 빌드 캐시만 대상으로 하고, 실행 중 컨테이너와 named volume은 건드리지 않는다.

다음은 대상에서 제외한다.

- 프로젝트 소스와 빌드 산출물
- `~/Library/Application Support`, `~/Library/Preferences`, `~/Library/Containers`
- Nix profile과 system generation
- Docker named volume와 실행 중 컨테이너

## Implementation

Home Manager의 기존 `users/shared/programs/zsh/functions.nix`에 macOS 전용 `bgc` zsh 함수를 추가한다. 명령별 크기 계산과 cleanup은 작은 내부 함수로 분리하되, 별도 패키지나 외부 의존성은 추가하지 않는다. 각 대상이 없거나 해당 CLI가 설치되지 않은 경우에는 해당 항목을 건너뛰고 나머지 작업을 계속한다.

Linux/NixOS에서는 명령을 정의하지 않는다. 공통 zsh 설정에서 `isDarwin`을 이용해 macOS에서만 삽입한다.

## Verification

- Home Manager 모듈 평가 결과에 `bgc` 함수가 포함되고 `gc = "git commit"` alias가 유지되는지 unit assertion으로 검증한다.
- `bgc stats`, `bgc --dry-run`, 잘못된 인자의 사용법 출력 계약을 생성된 zsh 설정 텍스트에서 검증한다.
- `nix flake check`의 관련 unit check와 `make test-build`를 실행한다.
