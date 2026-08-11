# direnv와 Nix flake 캐시 조사

## 질문

`.envrc`에 `use flake`만 작성하는 현재 방식이 올바른지, 새 worktree 진입 시 Nix 평가가 오래 걸리는 이유를 공식 문서와 저장소 설정으로 대조했다.

## 결론

현재 `.envrc`의 다음 설정은 올바르다.

```text
use flake
```

현재 flake는 `devShells.default`를 제공하고, Home Manager 설정은 `programs.direnv.nix-direnv.enable = true`를 활성화한다. 따라서 `use flake`가 현재 디렉터리의 기본 devShell을 로드하는 구조가 맞다.

## 공식 문서 대조

- [nix-direnv README](https://github.com/nix-community/nix-direnv)는 기존 flake 통합 예시로 `use flake`와 `direnv allow`를 제시한다.
- `use_flake`는 내부적으로 `nix print-dev-env`를 호출한다.
- nix-direnv는 최초 실행 후 shell 환경을 캐시해 이후 로드를 빠르게 한다.
- `use flake`는 `.envrc`, `flake.nix`, `flake.lock`, `devshell.toml` 등을 감시한다. 이 파일이 바뀌면 캐시를 다시 만드는 것이 정상이다.
- [direnv의 캐시 위치 문서](https://github.com/direnv/direnv/wiki/Customizing-cache-location)는 기본적으로 direnv 활성 디렉터리마다 `.direnv`가 생기며, `direnv_layout_dir`로 위치를 바꿀 수 있다고 설명한다. 따라서 worktree별 `.direnv`와 최초 평가가 반복되는 것은 기본 동작과 일치한다.
- [Nix `eval-cache` 문서](https://releases.nixos.org/nix/nix-2.34.0/manual/command-ref/conf-file.html)는 flake 평가 캐시가 특정 flake 버전의 재평가를 줄이지만 중간 결과 전체를 캐시하지는 않는다고 설명한다.
- [Nix `print-dev-env` 문서](https://releases.nixos.org/nix/nix-2.24.1/manual/command-ref/new-cli/nix3-print-dev-env.html)는 devShell의 환경을 출력하고 `--profile` 경로를 사용할 수 있다고 설명한다.

## 저장소 대조

- `.envrc`: `use flake`
- `flake-modules/dev-shells.nix`: `devShells.default` 정의
- `users/shared/programs/zsh/default.nix`: `programs.direnv.enable`, zsh integration, `nix-direnv.enable` 활성화
- `flake.nix`: `substituters`와 `trusted-public-keys` 설정은 빌드 산출물(binary cache)용이다. flake 평가 결과 자체를 Cachix에서 가져오는 설정은 아니다.

## 판단

기본 캐시는 정상 동작한다. 새 worktree의 첫 진입에서는 평가가 끝날 때까지 기다리면 `.direnv/flake-profile-*`가 생성되고, 같은 worktree의 다음 진입은 캐시를 사용한다.

worktree 간 캐시 공유가 별도 목표라면 `direnv_layout_dir`를 flake 내용 또는 버전별 경로와 함께 설계해야 한다. 단일 공통 디렉터리를 무조건 공유하면 서로 다른 branch의 devShell 캐시가 충돌할 수 있으므로 별도 변경과 검증이 필요하다.

## 효율화 비교

### 1순위: direnv-instant

[direnv-instant](https://github.com/Mic92/direnv-instant)는 direnv를 백그라운드 daemon에서 실행해 프롬프트를 즉시 반환한다. 이전에 생성된 환경은 즉시 적용하고, 변경된 환경은 백그라운드에서 다시 만든다. nix-direnv와 함께 사용하도록 안내되어 있으므로 현재의 `use flake`와 캐시 모델을 유지하면서 체감 지연을 줄이는 방향이다.

Home Manager 모듈을 사용하려면 공식 README 기준으로 flake input과 `homeModules.direnv-instant` import, `programs.direnv-instant.enable = true`가 필요하다. 기존 `programs.direnv.enableZshIntegration`과 동시에 사용하면 안 되므로 zsh의 일반 direnv hook은 꺼야 한다.

### 2순위: 수동 reload

nix-direnv의 `nix_direnv_manual_reload`는 flake 파일이 바뀌었을 때 자동으로 긴 평가를 실행하지 않고, 사용자가 `nix-direnv-reload`를 실행하도록 한다. 자주 수정하는 flake에는 유용하지만 새 worktree의 cold start 자체를 줄이지는 않는다.

### 보류: worktree 간 layout 공유

direnv는 `direnv_layout_dir` override를 지원한다. 다만 현재 기본 동작은 디렉터리별 cache이고, worktree별로 flake 내용과 branch가 달라질 수 있다. 공통 경로를 단순히 하나로 지정하면 서로 다른 devShell 환경이 충돌할 수 있다. 저장소 전체 내용과 dirty diff를 포함한 안정적인 cache key를 설계하고 동시 실행을 검증하기 전에는 적용하지 않는다.

## 효율화 결론

현재 목적이 worktree 진입 시 터미널이 멈추지 않는 것이라면 `use flake`는 유지하고 `direnv-instant`를 Home Manager에 통합하는 것이 가장 적합하다. 현재 목적이 평가 CPU 시간 자체를 없애는 것이라면 layout 공유가 필요하지만, 안전한 key 설계가 선행되어야 한다.

## 적용 결과

- `flake.nix`에 커밋으로 고정한 `direnv-instant` input을 추가했다.
- `direnv-instant`의 `nixpkgs`는 저장소의 root `nixpkgs`를 follow하도록 설정해 별도 nixpkgs 평가를 피했다.
- 공통 Home Manager 모듈에서 `homeModules.direnv-instant`를 import하고 활성화했다.
- 일반 direnv zsh hook은 끄고 `direnv-instant` zsh hook을 사용하도록 변경했다.
- `.envrc`의 `use flake`와 `nix-direnv`는 유지했다.
- Home Manager activation package와 zsh 통합 테스트가 통과했다.
