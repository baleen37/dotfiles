# mitchellh식 시스템 조립 리팩토링 검증

- 날짜: 2026-11-12
- 실행 플랫폼: aarch64-darwin
- 범위: 머신 + 사용자 OS + Home Manager 조립, Darwin 시스템/HM 파일 분리, 공통 개발 도구 선택 추출
- 실제 시스템 활성화·앱 삭제는 실행하지 않았다.

## 변경 구조

`lib/mksystem.nix`는 머신 모듈, `users/shared/darwin.nix` 또는 `nixos.nix`, `home-manager.nix`를 조립한다. 플랫폼별 Nix·GC·셸 정책은 OS 진입점으로 이동했다. 기존 머신별 앱·추가 기능 선택은 유지했다.

Darwin의 공유 OS 구현은 `users/shared/darwin/system/`, 사용자 세션을 다루는 HM 구현은 `darwin/home/`으로 분리했다. 이동한 스크립트 내용과 실행 권한을 유지했다. 중복된 24개 개발 도구 선택은 `users/shared/development.nix`로 모아 기존 진입점에서만 명시적으로 가져온다.

## 검증 결과

| 검증                                                                     | 결과                                      |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| 지원 플랫폼 전체 `nix flake check --no-build --all-systems --show-trace` | 성공. 평가 결과이며 assertion 실행과 구분 |
| aarch64-darwin `all-assertions` 빌드                                     | 최종 121개 검사 통과                      |
| `darwinConfigurations.macbook-pro.system` 빌드                           | 성공, 활성화하지 않음                     |
| `homeConfigurations.baleen.activationPackage` 빌드                       | 성공, 활성화하지 않음                     |
| WSL toplevel derivation 평가                                             | 성공                                      |
| WSL toplevel 실제 빌드                                                   | 실패: 필요한 x86_64-linux 빌더가 없음     |

일반 Git flake는 새 파일을 staging 전에는 보지 못하므로, `git ls-files -co --exclude-standard`의 파일을 격리된 디렉터리에 복사하고 `path:` 참조로 실행했다. 삭제된 파일과 ignored 로컬 호스트는 제외하고 symlink를 보존했다. 개인 identity를 복사하거나 사용하지 않았다.

## 변경 전후 비교

Mac 4개, WSL 1개, 독립 HM 4개에서 다음 항목을 비교했다.

- 사용자·홈 경로, hostname, 프로그램·패키지 그룹·Darwin 기능 선택
- 사용자·시스템 패키지 store 경로 집합과 HM 파일 배포 대상
- casks·brews·taps·MAS 앱과 관리하는 defaults, sudo 규칙
- 시스템/HM activation 내용과 Darwin launchd 구성
- Nix 캐시·trusted-users와 HM 통합 옵션

비교한 항목에서 동작 변경을 발견하지 못했다. Hammerspoon 소스 경로 7곳은 전체 소스 스냅샷 해시 변화로 달라졌으나, 해당 디렉터리 안의 파일·링크 내용과 권한은 일치했다. 경로를 일괄 제거해 차이를 숨기지 않고 실제 디렉터리 내용을 비교했다. GC·셸·Determinate 정책은 기존 assertion도 통과했다.

## 실제 Nix CLI probe

별도 격리 복사본에만 `minimal-probe`와 `selected-probe`를 등록하고 `nix eval`로 설정과 시스템 derivation을 평가했다. 둘 다 `machines/darwin/common.nix`를 사용하며 후자만 Terraform을 선택했다.

| 관찰                           | minimal-probe | selected-probe |
| ------------------------------ | ------------- | -------------- |
| GUI casks·MAS 앱               | 없음          | 없음           |
| 개발 패키지 그룹               | 비활성        | 비활성         |
| Terraform                      | 비활성        | 활성           |
| 키보드·VS Code 개인 activation | 없음          | 없음           |
| 시스템 derivation 조립         | 성공          | 성공           |

호스트 하나의 선택이 다른 호스트에 전파되지 않았으며 공통 개발 모듈이 최소 호스트에 자동 적용되지 않았다.

## 검증 범위의 한계

현재 Mac에는 Linux 원격 빌더가 등록되어 있지 않다. WSL 빌드는 `boot.json.drv` 등에서 `Required system: x86_64-linux`, `Current system: aarch64-darwin`으로 실패했다. Linux 빌더 또는 기존 CI에서 전체 빌드해야 한다. NixOS VM 부팅·Windows 앱 설치·Debian 실제 서비스 적용은 실행하지 않았다. 기존 assertion 안의 준비·적용 시나리오와 Debian 선언 검증은 통과했다.

macOS 기본값 전체를 무차별적으로 직렬화하면 upstream에서 제거한 옵션까지 평가하므로 실제 관리하는 defaults를 비교했다. 기존 probe의 Zsh dotDir 관련 경고는 정책을 변경하지 않고 유지했다.

## 2026-11-13 후속 검증과 보완

실제 실행 계약에 맞춰 AGENTS.md와 CONTRIBUTING.md를 보완했다. 지원하지 않는 호스트 인자·`--home`·`make switch-home` 예제를 수정하고, 검증 절차에서 사용자 환경을 활성화하던 명령을 activationPackage 빌드로 바꿨다. 점이 들어간 `jito.hello` 출력 키는 Nix 속성 경로에서 따옴표로 감싼다.

독립 Home Manager 검사는 activationPackage 속성 존재 확인에서 실제 `.drvPath` 평가로 강화했다. 호스트 격리 검사는 한 Mac에서 Terraform을 비활성화했을 때 설정 파일·activation이 제거되며 다른 Mac과 독립 HM에는 유지되는지를 확인하도록 보완했다.

| 최종 확인                            | 결과                                                                                    |
| ------------------------------------ | --------------------------------------------------------------------------------------- |
| 보강한 assertion 전체 빌드           | 121개 검사 통과                                                                         |
| 지원 플랫폼 전체 flake 평가          | 통과                                                                                    |
| 실제 `./switch.sh --build` 실행      | 호스트 선택·필터링된 소스·실제 Nix 빌드 후 비활성화 종료까지 통과                       |
| 나머지 Mac 시스템 빌드               | baleen-macbook·baleen-m2-pro·kakaostyle-jito 성공. 앞선 macbook-pro와 합쳐 Mac 4개 확인 |
| macOS 독립 HM activationPackage 빌드 | baleen·jito.hello·testuser 성공                                                         |
| 지원하지 않는 CLI 인자               | `switch.sh --home`, `bootstrap.sh macbook-pro` 모두 usage 오류로 거부                   |
| 변경한 Nix·셸 파일                   | 구문 검사 통과                                                                          |
| 변경 파일 포맷·diff 검사             | 이동한 경로로 길어진 Nix 문자열 한 곳을 정리한 뒤 통과                                  |

실제 build-only 실행은 격리된 Git 복사본에서 수행했다. hostname만 macbook-pro로 지정하는 외부 명령 대역을 두었으며 Nix 명령은 실제 실행했다. HOME·XDG 경로·GNUPGHOME은 임시 디렉터리로 분리했고, sudo가 호출되면 실패하도록 막았다. 실제 시스템 설정·사용자 프로필을 활성화하지 않았고 개인 키를 사용하지 않았다. Bootstrap·일반 switch의 실패·준비·적용 경로는 기존 합성 fixture 시나리오로 검증했다.

Linux 전체 빌드의 플랫폼 제약은 여전히 남아 있다. 이번 검증에서 Linux 빌더를 새로 설치하거나 운영 중인 호스트에 설정을 적용하지 않았다.

## 2026-11-14 전체 검증

리팩토링과 Debian 청크 다운로드 수정을 함께 포함한 작업 트리로 실행했다. 도구 연결 갱신으로 초기 임시 세션이 사라져, 최종 실행 로그와 종료 코드는 ignored `.direnv/refactor-verification/`에 보관했다. 아래는 재실행해 확인한 결과다.

| 범위                                    | 결과                                                                                  |
| --------------------------------------- | ------------------------------------------------------------------------------------- |
| aarch64-darwin 단위·통합 assertion 전체 | 121개 검사 통과                                                                       |
| 지원 플랫폼 전체 평가                   | aarch64-darwin·x86_64-linux·aarch64-linux 통과                                        |
| Mac 시스템 빌드                         | macbook-pro·baleen-macbook·baleen-m2-pro·kakaostyle-jito 성공                         |
| macOS 독립 HM 빌드                      | baleen·jito.hello·testuser 성공                                                       |
| Debian 다운로드·원격 접속 fixture       | 3개 통과. 청크 크기·해시 실패 시 기존 파일 보존·성공 시 권한 유지 포함                |
| Debian 준비·적용 CLI fixture            | 8개 통과. 합성 identity와 외부 명령 대역 사용                                         |
| 상태줄 수동 검사                        | 현재 출력 계약에 맞춘 10개 시나리오 통과                                              |
| Nix 앱 링크 수동 검사                   | 최초 링크와 반복 실행 멱등성 통과                                                     |
| 전체 pre-commit                         | ShellCheck·bashate·파일 검사·캐시 설정 검사 통과. 중복 평가용 test/test-all 훅만 생략 |
| 전체 treefmt                            | 255개 파일 탐색, 233개 처리, 변경 0개로 통과                                          |
| 실제 switch build-only                  | 격리된 Git 복사본에서 호스트 선택·실제 빌드·비활성화 종료 성공                        |

기존 수동 상태줄 검사는 이미 제거된 `Ctx:` 접두사·소수 토큰 표시·percentage/transcript fallback을 기대해 실패했다. 현재 제품 코드와 단위 검사에 맞게 기대값을 갱신했다. 실제 stdin/stdout 명령을 실행하고 전체 표시 문자열을 비교한다. Claude 인증과 Git 저장소에 의존하지 않는 fixture를 사용한다. 제품 상태줄 코드는 변경하지 않았다.

전체 포맷 검사에서 실패한 조사 문서 3개의 표 정렬만 수정한 뒤 다시 통과했다. 사용자의 원격 접속 정책 값은 변경하지 않았다.

Linux 원격 빌더와 KVM이 없어 Linux assertion 실행·WSL 전체 빌드·NixOS VM 부팅은 실행하지 못했다. 실제 Debian의 APT 설치·systemd 서비스 적용과 Windows 네이티브 실행도 이번 Mac 검증 범위에 포함하지 않는다. 따라서 플랫폼 평가 성공이나 fixture 통과를 실제 운영 호스트 적용 성공으로 해석하지 않는다.

Python은 Debian 네이티브 실행 절차에 한정하는 구성을 유지한다. JSON·해시·임시 파일·서비스 상태 복원은 표준 라이브러리로 처리하고, 최초 Python 준비는 셸, 패키지·구성 선언은 기존 Nix 또는 플랫폼별 선언 파일이 담당한다. 별도 pip 라이브러리는 추가하지 않았다.

## 2026-11-14 WSL·UTM 지원 제거

WSL 호스트, NixOS-WSL input과 전용 lock 의존성, tarball Make target,
Windows WSL 설치 항목과 설치 안내를 제거했다. UTM 실행 구성은 이미 없었으며
현재 운영 안내의 잔여 참조를 정리했다. 과거 조사·설계 기록은 이력으로 유지한다.
Windows 네이티브 앱과 SSH 구성, Debian 네이티브 적용기, Linux 독립 Home Manager는 유지한다.

CI의 x86_64-linux 빌드 대상은 `homeConfigurations.baleen-linux.activationPackage`다.
기존 branch protection과의 호환을 위해 required-check 이름은 유지한다.
공통 NixOS 시스템 생성기는 배포 호스트 등록 없이 테스트 전용 fixture로 검증한다.

| 검증                       | 결과                                                                              |
| -------------------------- | --------------------------------------------------------------------------------- |
| Darwin 전체 assertion 빌드 | 121개 통과. Debian 원격 접속 3개·CLI 8개 포함                                     |
| 전체 플랫폼 평가           | aarch64-darwin·x86_64-linux·aarch64-linux 통과                                    |
| macbook-pro 시스템 빌드    | 활성화 없이 성공                                                                  |
| pre-commit                 | ShellCheck·bashate·파일 검사·캐시 동기화 통과. test/test-all은 별도 실행으로 대체 |
| 제거된 인터페이스          | NixOS 호스트 목록 `[]`, `make wsl` 미지원 확인                                    |

실제 CLI 추가 검증 중 디스크 여유 부족이 발생했다. 사용자 파일·시스템 프로필·Nix store의
전역 정리는 수행하지 않았다. 임시 공간 반환 후 CLI를 단독 재실행하여
`System build finished; not activated.`와 종료 코드 0을 확인했다.
격리된 HOME·XDG 경로와 sudo 호출을 거부하는 대역을 사용했다.
전체 assertion과 시스템 빌드도 통과했다.
Linux 원격 빌더·KVM 및 Windows 실행 환경이 없어 Linux 빌드·VM 부팅·winget 네이티브
실행은 검증하지 않았다. 실제 Debian APT 설치·서비스 적용도 수행하지 않았다.

Debian 패키지·버전·접속 정책의 실제 선언은 `machines/remote-access.json`이며 Nix 선언이 아니다.
Python은 Nix 설치 없이 APT·systemd를 준비·적용하는 실행기다. 사용자 도구·설정을
Nix/Home Manager로 옮기는 작업은 이번 지원 제거에 포함하지 않는다.
