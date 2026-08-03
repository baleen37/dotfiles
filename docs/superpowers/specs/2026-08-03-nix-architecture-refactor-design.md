# Nix 아키텍처 베스트 프랙티스 리팩토링 설계

**Date:** 2026-08-03
**Status:** 사용자 검토 대기
**Scope:** flake 평가 경계, 호스트 메타데이터, per-system 패키지 구성, 플랫폼 지원 정책, 캐시 권한

## 1. 목표

현재 dotfiles flake를 다음 기준에 맞게 개선한다.

1. `USER` 환경변수에 의존하지 않는 결정적 평가
2. 공개 flake output과 내부 호스트 메타데이터의 분리
3. 호스트 설정의 타입 검증과 확장 가능한 구조
4. `perSystem`/`withSystem`을 이용한 단계적 `pkgs` 중앙화
5. binary cache 설정과 daemon 권한의 분리된 감사
6. formatter와 CI 검증 경로의 단일화
7. 더 이상 지원되지 않는 `x86_64-darwin` 플랫폼 제거

Nix 공식 문서는 `builtins.getEnv`가 환경 의존성을 만든다고 설명한다. flake-parts는 `perSystem`과 `withSystem`을 통해 시스템별 값과 시스템 구성을 연결하는 구조를 제공한다.

- https://nix.dev/manual/nix/2.34/language/builtins.html
- https://flake.parts/system
- https://nixos.org/manual/nixos/stable/

## 2. 현재 상태와 확인된 문제

현재 저장소는 이미 flake-parts, import-tree, treefmt-nix, Home Manager 모듈 통합을 사용한다. 기존 2026-05 리팩토링을 다시 수행하지 않는다.

현재 기준선:

- `nix flake check --no-build --impure`는 현재 `aarch64-darwin`에서 평가 성공
- `nix fmt -- --ci`는 193개 파일을 검사하고 변경 없이 종료
- `git diff --check` 성공
- 현재 `nix`는 Determinate Nix 2.32.4
- `flake.hosts` 때문에 `nix flake check`가 `unknown flake output 'hosts'`를 출력
- devShell 평가에서 `nixfmt-rfc-style` deprecated 경고 출력
- all-systems 평가에서 `nixos-generators` deprecated 경고 출력
- `env -u USER`로 `macbook-pro`를 평가하면 Home Manager 사용자는 `baleen`으로 고정되어 결정적으로 평가됨
- `env -u USER nix flake check --no-build --all-systems`는 현재 nixpkgs의 `x86_64-darwin` 지원 중단으로 실패

Nixpkgs 26.05 release notes는 26.05를 `x86_64-darwin`을 지원하는 마지막 릴리스로 명시하고, 26.11부터 빌드·소스 지원을 중단한다고 설명한다.

- https://nixos.org/manual/nixpkgs/unstable/release-notes

## 3. 비목표

- 새 개발 도구나 사용자 기능 추가
- 기존 호스트 이름 변경
- 기존 패키지와 프로그램 설정의 의도하지 않은 변경
- 실제 `make switch` 실행과 현재 머신의 시스템 활성화
- Intel Mac 지원을 위한 별도 nixpkgs 호환 입력 추가
- secrets 관리 체계 도입
- disko, sops-nix, impermanence, nh 등 새 인프라 도입

## 4. 최종 구조

### 4.1 지원 시스템

`flake.nix`의 `systems`에서 다음만 유지한다.

```nix
systems = [
  "aarch64-darwin"
  "x86_64-linux"
  "aarch64-linux"
];
```

`x86_64-darwin`은 flake의 시스템 목록, README 플랫폼 표, CI matrix, 관련 테스트 문서에서 제거한다. 현재 호스트 목록에는 Intel Darwin 호스트가 없으므로 기존 사용자의 실제 시스템을 제거하지 않는다.

### 4.2 내부 typed host metadata

`flake.hosts`는 공개 flake output으로 만들지 않는다. `flake-modules/hosts.nix`에 내부 모듈 옵션을 선언한다.

```text
options.dotfiles.hosts
config.dotfiles.hosts
```

각 호스트의 필드:

- `system`: 문자열, 지원 시스템 assertion으로 검증
- `class`: `darwin` 또는 `nixos`
- `user`: 비어 있지 않은 문자열
- `homeModules`: attrset, 기본값 `{}`
- `machineModules`: module 목록, 기본값 `[]`

호스트 정의는 다음과 같이 결정적으로 유지한다.

```text
macbook-pro       aarch64-darwin  darwin  baleen
baleen-macbook    aarch64-darwin  darwin  baleen
kakaostyle-jito   aarch64-darwin  darwin  jito.hello
vm-aarch64-utm    aarch64-linux   nixos   baleen
vm-x86_64-utm     x86_64-linux    nixos   baleen
```

`flake-modules/systems.nix`는 `config.dotfiles.hosts`를 `class`로 필터링해 기존 `darwinConfigurations`와 `nixosConfigurations`를 생성한다. 호스트 메타데이터는 public output이 아니므로 `unknown flake output 'hosts'` 경고가 사라진다.

### 4.3 사용자 선택 경계

flake 평가에서 사용자 환경을 읽지 않는다.

- `flake-modules/args.nix`의 `resolveUser` 제거
- `builtins.getEnv "USER"` 제거
- standalone Home Manager 사용자는 `HM_USER` Make 변수로 선택
- 지원되는 standalone profile은 기존 `baleen`, `jito.hello`, `testuser`, `baleen-linux` 유지

예시:

```sh
make switch-home HM_USER=jito.hello
make switch-home HM_USER=baleen
```

`make switch`는 호스트 이름으로 시스템 구성을 선택하고, 시스템의 실제 사용자는 `hosts.nix`에 선언된 값을 사용한다. Home Manager standalone flake는 `homeConfigurations.<name>`을 선택하는 공식 경로를 사용한다.

- https://home-manager.dev/manual/unstable/nix-flakes/standalone.html

### 4.4 perSystem과 withSystem의 단계적 사용

`withSystem`을 모든 시스템에 즉시 적용하지 않는다. 다음 순서로 중앙화한다.

1. `perSystem`의 `pkgs`를 overlays와 `allowUnfree` 정책까지 명시적으로 구성한다.
2. devShell, formatter, checks, standalone Home Manager가 동일한 per-system pkgs를 사용하는지 확인한다.
3. `withSystem`을 사용해 top-level Home Manager와 system output에서 같은 per-system 패키지를 참조할 수 있는지 검증한다.
4. `lib/mksystem.nix`의 system-local nixpkgs 평가와 결과가 동일하다는 테스트가 통과한 뒤 system configuration까지 확장한다.

Darwin의 Determinate Nix 설정과 NixOS별 unsupported-system 예외가 있으므로, `readOnlyPkgs`를 첫 변경에서 강제하지 않는다. 중앙화는 결과 비교를 통과한 범위에서만 적용한다.

### 4.5 Cache와 daemon 권한

`lib/cache-config.nix`를 캐시 데이터의 기준으로 유지한다.

- substituter와 public key 값은 현재처럼 별도 데이터 파일에 둔다.
- `flake.nix`의 `nixConfig`와 CI 설정은 자동 생성 전 작은 fixture로 import 가능성을 검증한다.
- 기존 sync test는 유지하고, 설정이 삭제되었을 때도 drift를 감지할 수 있도록 방향성 테스트를 보강한다.
- `trusted-users`의 `root`, 사용자명, `@admin`, `@wheel` 각각이 실제로 필요한지 non-root cache/build smoke test로 확인한다.
- 필요한 cache URL은 `trusted-substituters`로 제공할 수 있는지 먼저 검증한다.
- `accept-flake-config = true`는 flake 전역에서 자동 승인할 필요가 있는지 검토하고, 명시적 명령 옵션과 CI `NIX_CONFIG`로 대체 가능한지 확인한다.

Nix 공식 문서는 `trusted-users`가 사실상 root 권한에 해당한다고 설명한다. 따라서 이 항목은 단순 정리 작업이 아니라 운영 권한 변경으로 취급하고, read-only preflight와 non-root 검증 뒤에만 적용한다.

- https://nix.dev/manual/nix/2.18/command-ref/conf-file.html
- https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake.html

### 4.6 Formatter와 deprecated tooling

- `flake-modules/dev-shells.nix`에서 `nixfmt-rfc-style` 제거
- `alejandra`를 직접 formatter 목록에서 제거해 treefmt-nix와 formatter 경쟁을 없앰
- `nix fmt`와 `nix fmt -- --ci`를 저장소의 canonical formatter 경로로 유지
- `packages.nix`의 `nixos-generators.nixosGenerate`를 upstream NixOS image/VM build interface로 교체하는 별도 단계 추가
- 기존 `nix run .#test-vm` 계약과 VM override 동작을 유지

## 5. 변경 파일

직접 수정 대상:

- `flake.nix`
- `flake-modules/args.nix`
- `flake-modules/hosts.nix`
- `flake-modules/systems.nix`
- `flake-modules/home.nix`
- `flake-modules/dev-shells.nix`
- `flake-modules/packages.nix`
- `lib/mksystem.nix`
- `Makefile`
- `.envrc`
- `.github/workflows/ci.yml`
- `lib/cache-config.nix`, 필요한 경우 cache data schema만 보강
- `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`

테스트 대상:

- `tests/integration/machine-builds-test.nix`
- `tests/integration/home-configurations-test.nix`
- `tests/unit/makefile-switch-commands-test.nix`
- 신규 `tests/unit/host-metadata-test.nix`
- `tests/unit/cache-config-test.nix`
- 관련 tests README 및 CI 문서

## 6. 성공 기준

1. `env -u USER nix flake check --no-build --all-systems --show-trace`가 통과한다.
2. `nix flake show --all-systems`에 `unknown flake output 'hosts'`가 없다.
3. `nix flake show --all-systems`에 `x86_64-darwin` 출력이 없다.
4. 기존 Darwin 3개, NixOS 2개 configuration이 `--impure` 없이 평가된다.
5. `homeConfigurations`의 기존 4개 profile이 activation package를 만든다.
6. `make -n switch-home HM_USER=jito.hello`와 `HM_USER=baleen`에 `--impure`가 없다.
7. `USER` 값이 달라도 호스트 configuration의 user mapping이 변하지 않는다.
8. `nix fmt -- --ci`가 통과하고 `nixfmt-rfc-style` deprecated 경고가 없다.
9. `nix run .#test-vm`의 build/run 계약이 유지된다.
10. cache 권한 변경 전후에 non-root binary cache smoke test 결과가 기록된다.
11. 기존 패키지 목록과 Home Manager module enable 상태가 baseline과 동일하다.
12. `git diff --check`가 통과한다.

## 7. 마이그레이션 순서

각 단계는 독립적으로 평가·검증하고 논리적으로 분리된 커밋으로 남긴다.

1. 지원 시스템에서 `x86_64-darwin` 제거와 문서/CI matrix 갱신
2. pure host user와 `HM_USER` 경계 도입
3. typed internal host metadata와 `flake.hosts` 제거
4. formatter 중복 및 deprecated devShell package 제거
5. perSystem pkgs 구성과 standalone Home Manager/devShell/checks 중앙화
6. `withSystem` system configuration 재사용 검증
7. `nixos-generators` native VM/image build 전환
8. cache import/drift fixture 검증
9. `trusted-users`와 `accept-flake-config` read-only preflight
10. 승인된 권한 축소 적용과 non-root smoke test
11. 전체 문서 정합성 확인 및 baseline 비교

## 8. 위험과 완화

| 위험                                                        | 완화                                                                                                      |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | --------------- | ------------------------------------- |
| Intel Mac 사용자가 실제로 존재함                            | 지원 제거를 반영하기 전에 현재 호스트 목록과 CI matrix에서 확인하고, 필요하면 별도 26.05 입력 설계로 분기 |
| 사용자 고정으로 기존 `make switch`가 다른 사용자에게 적용됨 | 호스트별 user assertion과 `HM_USER` standalone 경로를 함께 검증                                           |
| typed option이 flake-parts 고정점과 충돌함                  | 최소 host metadata fixture를 먼저 평가하고, 실패 시 `_module.args` 내부 전달로 축소                       |
| perSystem pkgs가 system pkgs와 달라짐                       | standalone/devShell/checks부터 적용하고 결과 비교 후 system으로 확대                                      |
| trusted-users 축소로 cache 사용이 깨짐                      | 변경 전후 non-root build와 `trusted-substituters` smoke test 수행                                         |
| native VM 전환으로 `test-vm` 계약이 깨짐                    | 기존 `nix run .#test-vm`을 전환 전후 실행해 동일한 SSH/포트 계약 확인                                     |
| 문서와 운영 명령이 어긋남                                   | `rg -- '--impure                                                                                          | builtins.getEnv | x86_64-darwin'` 기반 정합성 검사 추가 |

## 9. 승인 후 다음 단계

이 설계 문서 승인 후 `docs/superpowers/plans/2026-08-03-nix-architecture-refactor.md`에 파일별 구현 계획과 검증 명령을 작성한다. 그 전까지는 저장소 코드를 수정하지 않는다.
