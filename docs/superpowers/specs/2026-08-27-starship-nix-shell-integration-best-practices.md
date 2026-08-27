# Starship와 Nix/Home Manager zsh 통합 베스트 프랙티스

**Date:** 2026-08-27
**Status:** 조사 완료, 적용 결론
**Scope:** Starship zsh 초기화 경로, 장기 실행 zsh의 stale store 경로, 사용자 안정 경로, Nix profile/garbage collection, zsh startup 파일

이 문서는 Starship 공식 문서와 소스, Home Manager 공식 옵션과 소스, Nix 공식 매뉴얼, zsh 공식 매뉴얼만 외부 근거로 사용했다. 저장소의 현재 설정과 로컬 경로 관찰은 `현재 저장소 적용` 절에 별도로 표시했다. 연구 단계는 코드 변경과 분리했고, 적용된 변경은 `현재 저장소 적용` 절에 기록했다.

## 결론

- Home Manager의 `programs.starship.enableZshIntegration`은 안정적인 사용자 경로를 만드는 옵션이 아니다. 현재 저장소가 고정한 Home Manager 소스는 `programs.zsh.initContent`에 다음 형태를 생성한다.

  ```zsh
  if [[ $TERM != "dumb" ]]; then
    eval "$(${lib.getExe cfg.package} init zsh)"
  fi
  ```

  `cfg.package`의 실행 파일은 Nix store 경로로 평가되므로, 실제 생성된 `.zshrc`에는 `/nix/store/<hash>-starship-<version>/bin/starship` 같은 세대별 절대 경로가 들어간다.

- Starship의 zsh 초기화는 실행 파일 경로를 초기화 시점에 해석하고, zsh 초기화 스크립트의 `PROMPT`와 `RPROMPT` 명령에도 그 경로를 치환한다. 프롬프트가 다시 그려질 때마다 같은 경로가 실행된다. 따라서 이 문제는 우선 zsh command hash 문제가 아니라 이미 평가된 zsh 상태가 이전 경로를 보유하는 문제로 봐야 한다.

- Home Manager 세대를 전환해 `.zshrc` 링크를 바꿔도 이미 실행 중인 zsh는 `.zshrc`를 다시 읽지 않는다. 새 터미널을 열거나 `exec zsh -l`로 셸 프로세스를 교체해야 새 초기화와 새 경로가 적용된다. 같은 파일을 `source`하는 방식은 현재 프로세스에 다시 실행하는 것이므로 깨끗한 상태 경계가 아니다.

- 일반적인 Nix 환경에서는 공식 Home Manager 통합을 유지하고 switch 뒤 새 셸을 여는 것이 기본 선택이다. 세대별 실행 파일 고정, 재현성, rollback, Home Manager의 패키지 관리 경계를 보존하기 때문이다.
- 이 저장소는 herdr가 셸을 장시간 유지하고, old prompt가 GC 이후 사라진 Starship 경로를 반복 호출하는 문제가 이미 확인됐다. 따라서 이 환경에서는 Home Manager가 `~/.local/bin/starship`를 현재 `pkgs.starship`로 갱신하게 하고, zsh 초기화는 이 사용자 경로를 호출하는 방식으로 적용한다. 이는 수동으로 고정한 `/nix/store` 링크가 아니라 Home Manager가 세대 전환마다 갱신하는 선언적 링크다.

- 안정 경로가 필요하면 직접 `/nix/store`를 가리키는 수동 symlink보다 Nix profile 또는 Home Manager가 갱신하는 선언적 link를 사용한다. Nix 공식 매뉴얼은 profile 세대 링크를 garbage collector root로 설명하고, 사용자 profile 링크의 `bin`을 `PATH`에 넣는 방식을 설명한다. 실제 Home Manager profile 위치는 standalone, XDG, NixOS/nix-darwin submodule 여부에 따라 먼저 확인해야 하므로, 이 저장소는 profile 위치를 추측하지 않고 Home Manager-managed `~/.local/bin/starship` link를 사용한다.

- profile 세대를 삭제하고 garbage collection을 실행하면 오래된 Starship store 경로가 수집 대상이 될 수 있다. 기존 zsh가 그 경로를 프롬프트에 계속 들고 있으면 다음 프롬프트 렌더링에서 실행 파일 없음이 발생할 수 있다. 세대/profile root가 남아 있는 동안에는 오래된 경로가 남는 것이 정상이며, 단순히 셸 변수에 경로가 들어 있다는 사실을 durable GC root로 간주하면 안 된다.

## 실제 경로의 성격

### 생성 흐름

```text
Home Manager 평가
  -> 생성된 .zshrc에 /nix/store/.../bin/starship init zsh 삽입
  -> 새 interactive zsh가 .zshrc 실행
  -> eval이 Starship init 출력물을 현재 zsh에 평가
  -> Starship가 init 스크립트의 PROMPT/RPROMPT에 실행 파일 경로 삽입
  -> 각 prompt redraw가 그 절대 경로를 다시 실행
```

이 흐름의 각 경계는 다음과 같다.

| 대상            | 생성/사용 방식                                                           | lifecycle 성격                                                              |
| --------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| Starship binary | Home Manager의 `home.packages`에 `cfg.package`를 추가                    | Nix store의 immutable한 package 경로                                        |
| Starship config | `settings`가 비어 있지 않으면 `home.file.${cfg.configPath}`로 생성       | 생성된 store 파일을 사용자 경로에 materialize                               |
| `.zshrc`        | `programs.zsh.initContent`가 `home.file."${dotDirRel}/.zshrc".text`가 됨 | Home Manager 세대의 생성 파일이며, switch 때 사용자 링크가 새 세대를 가리킴 |
| zsh integration | `lib.getExe cfg.package`가 들어간 `eval` 문자열                          | PATH lookup을 매 prompt마다 수행하는 안정 wrapper가 아니라 세대별 직접 경로 |
| prompt runtime  | Starship init 소스의 `PROMPT`/`RPROMPT` command substitution             | 현재 zsh 프로세스가 초기화 때 가진 경로를 계속 사용                         |

근거는 다음 공식 소스에 있다.

- Home Manager Starship 모듈은 `package`, `settings`, `enableZshIntegration` 옵션을 선언하고, `home.packages`, `STARSHIP_CONFIG`, 생성 config, zsh init 문자열을 구성한다. [고정된 Home Manager Starship 소스의 옵션 부분](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/starship.nix#L25-L117), [패키지/config 부분](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/starship.nix#L120-L163), [zsh integration 부분](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/starship.nix#L167-L180)
- Starship 소스는 `which("starship")`를 먼저 시도하고 실패하면 현재 실행 파일을 사용하며, zsh init template의 placeholder를 이 경로로 치환한다. [Starship init path resolution](https://github.com/starship/starship/blob/0b48f454da65c147b360c3d7357d16412d00df4c/src/init/mod.rs#L23-L45), [zsh init stub와 placeholder 치환](https://github.com/starship/starship/blob/0b48f454da65c147b360c3d7357d16412d00df4c/src/init/mod.rs#L104-L168)
- 생성된 zsh init template은 `setopt promptsubst`를 설정하고 `PROMPT`와 `RPROMPT`의 command substitution에 Starship 경로를 넣는다. [Starship zsh init source](https://github.com/starship/starship/blob/0b48f454da65c147b360c3d7357d16412d00df4c/src/init/starship.zsh#L89-L102)
- Starship 공식 설치 문서도 zsh 설정으로 `eval "$(starship init zsh)"`를 `.zshrc`에 두고 새 shell instance를 시작하라고 안내한다. [Starship 공식 zsh setup](https://starship.rs/guide/)

## 장기 실행 zsh에서 stale 경로가 생기는 이유

1. Nix store 경로는 입력과 package 결과에 따라 달라지는 고유 경로다. 같은 이름의 Starship라도 새 package나 새 설정을 평가하면 다른 `/nix/store/<hash>-...` 경로가 생길 수 있다. [Nix profiles와 store path 설명](https://nix.dev/manual/nix/2.34/package-management/profiles), [Nix store path 설명](https://nix.dev/manual/nix/2.34/store/store-path)

2. Home Manager는 switch 때 새 세대의 `.zshrc`와 package를 만들고 사용자 파일 링크를 갱신한다. 하지만 이미 실행 중인 zsh가 그 파일을 자동으로 재독해하는 동작은 없다. zsh 공식 매뉴얼상 `.zshrc`는 interactive shell startup 단계에서 읽히며, `source`와 `eval`은 현재 shell process에서 명령을 실행한다. [zsh startup/shutdown files](https://zsh.sourceforge.io/Doc/Release/Files.html), [zsh `eval`, `source`, `exec`](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html)

3. Starship init 결과는 `PROMPT`/`RPROMPT`와 hook function을 현재 zsh에 등록한다. 이후 prompt redraw는 이미 등록된 문자열과 function을 사용하므로 새 `.zshrc` symlink를 가리키는 것만으로 이전 경로가 바뀌지 않는다. 이 항목은 위 Starship 소스와 zsh의 startup 동작을 결합한 적용 판단이다.

4. 오래된 경로가 실제로 사라지는 시점은 profile history와 GC root에 달려 있다. 이전 profile 세대가 root로 남아 있으면 store path는 유지된다. 이전 세대와 기타 root가 제거된 뒤 GC가 unreachable path를 수집하면 stale zsh가 참조하는 직접 경로가 dangling 상태가 될 수 있다. [Nix profile generation은 GC root](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-profile), [Nix garbage collection](https://nix.dev/manual/nix/2.34/package-management/garbage-collection), [Nix garbage collector roots](https://nix.dev/manual/nix/2.34/package-management/garbage-collector-roots)

따라서 다음 현상을 분리해야 한다.

- **설정 갱신 전후의 버전 차이:** old zsh가 정상 동작하지만 이전 Starship binary를 계속 사용한다.
- **GC 이후 실행 실패:** old zsh가 매 prompt에서 이전 직접 경로를 실행하려 하지만 해당 store path가 더 이상 없다.
- **새 shell의 정상 동작:** 새 zsh는 현재 `.zshrc`와 현재 profile/package를 읽는다.

`rehash`는 PATH에서 명령을 다시 찾는 문제에는 유용할 수 있지만, 이미 `PROMPT` 문자열에 들어간 `/nix/store/.../bin/starship` 자체를 바꾸지는 않는다. 이 결론은 현재 Home Manager와 Starship 소스에 대한 적용 판단이다.

## 안정 사용자 경로와 wrapper 선택지

공식 문서가 Starship용 사용자 wrapper를 별도 권장하는 것은 아니다. 아래 비교는 Nix profile의 공식 안정 링크와 Starship의 공식 path resolution 동작을 바탕으로 한 설계 선택이다.

| 선택지                                                                           | 장점                                                                                                                               | 단점/위험                                                                                                                                                         | 현재 저장소 판단               |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Home Manager 기본 direct store path                                              | package와 init script가 같은 세대에 고정됨. 재현성, rollback, Home Manager 경계가 명확함. 추가 파일 없음                           | switch 후 장기 실행 shell은 old path를 유지함. old 세대가 GC되면 prompt 실행 실패 가능                                                                            | 일반 환경의 기본값             |
| Home Manager-managed `~/.local/bin/starship` link                                | prompt가 세대별 store 경로 대신 사용자 경로를 호출하고, switch 때 link target이 현재 package로 바뀜. 현재 profile 위치 차이를 피함 | 공식 built-in integration 대신 작은 custom zsh seam이 필요함. 기존에 이미 로드된 shell은 한 번 refresh해야 함                                                     | **현재 저장소에 적용**         |
| `~/.nix-profile/bin/starship` 같은 profile-backed stable path를 사용하는 symlink | 사용자-facing 경로가 안정적이고 profile 전환을 따라감. Nix profile 세대가 GC root가 됨                                             | 현재 Home Manager option은 direct `lib.getExe`를 생성하므로 별도 zsh init 설계가 필요함. init 시 PATH에서 stable entry가 실제로 선택되는지 검증 필요              | hot update 요구가 있을 때 검토 |
| stable user wrapper가 매번 현재 profile로 dispatch                               | 기존 shell의 prompt가 stable wrapper를 호출하면 profile 전환을 따라갈 수 있음. fallback/진단을 넣을 수 있음                        | 매 prompt마다 wrapper overhead가 추가됨. old init script와 new binary가 섞일 수 있음. quoting, recursion, Home Manager ownership, profile 위치를 직접 관리해야 함 | 요구가 명확할 때만 별도 설계   |
| switch 뒤 `exec zsh -l` 또는 새 terminal                                         | 구현 변경 없이 새 `.zshrc`와 현재 경로를 적용함. 프로세스 상태가 깨끗함                                                            | 사용자가 세션을 refresh해야 함. 자동 hot update는 아님                                                                                                            | **현재 운영 절차로 권장**      |

### stable path를 선택할 때의 조건

1. 수동으로 한 번 만든 `~/.local/bin/starship -> /nix/store/...` 링크를 안정 경로로 부르지 않는다. 이번 방식은 `home.file`이 package source를 선언하고 Home Manager가 switch 때 링크를 갱신한다는 점이 다르다.
2. 이 저장소에서는 `~/.nix-profile`을 고정 경로로 되살리지 않는다. Nix 공식 매뉴얼은 일반 사용자 profile 링크를 `~/.nix-profile` 또는 XDG profile 링크로 설명하지만, Home Manager submodule은 `/etc/profiles/per-user/<user>`를 사용할 수도 있다. [Nix profile filesystem layout](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-profile), [Home Manager `home.profileDirectory`](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/home-environment.nix#L229-L237)
3. 현재 Home Manager integration을 그대로 둔 채 stable path가 자동으로 쓰일 것이라고 가정하지 않는다. 소스상 integration은 `lib.getExe cfg.package`를 사용한다. stable path가 필요한 경우 `enableZshIntegration`을 끄고 stable executable을 호출하는 명시적 `programs.zsh.initContent` seam을 둔다.
4. Starship 소스는 init 시 PATH에서 `starship`을 먼저 해석할 수 있고, 최종 init 결과의 경로는 실제 실행 방식의 영향을 받는다. 이번 구현은 stable executable을 직접 호출하고, 생성된 prompt가 stable path를 보유하는지 smoke test한다. symlink canonicalization까지를 Starship의 별도 보장으로 간주하지 않는다.
5. stable link를 도입해도 이미 로드된 old Starship shell function과 hook이 자동으로 새 버전으로 바뀌는 것은 아니다. stable executable은 이후 prompt의 실행 파일 선택 문제를 줄일 뿐, 기존 zsh process refresh를 대체하지 않는다.

## Nix profile과 garbage collection

Nix 공식 매뉴얼의 모델은 다음과 같다.

- package는 고유한 Nix store path에 놓인다.
- profile은 package store path로 연결되는 세대들의 집합이다.
- profile 세대 링크는 garbage collector root다.
- 현재 사용자 profile을 가리키는 안정 링크는 `~/.nix-profile` 또는 XDG 경로이며, 그 `bin`을 `PATH`에 넣는다.
- GC는 root에서 도달할 수 없는 store path를 제거한다. 이전 세대를 삭제하지 않으면 rollback을 위해 old package가 남을 수 있다.

Home Manager도 현재 세대의 GC root를 activation에서 생성하는 경로를 갖고 있다. 공식 Home Manager 소스는 `home.activationGenerateGcRoot`의 기본값을 `true`로 두고, activation 중 임시 root와 현재 generation root를 만든다. [Home Manager GC root option와 activation](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/home-environment.nix#L533-L541), [Home Manager generation root 생성](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/home-environment.nix#L868-L883)

여기서의 운영 결론은 다음과 같다.

- GC를 stale session의 refresh 수단으로 사용하지 않는다. GC는 storage lifecycle 작업이고, zsh process state를 갱신하지 않는다.
- old session의 직접 store path가 아직 실행되는지 확인하려면 먼저 현재 profile, 남은 세대, GC roots를 확인한다.
- old generation을 지우고 GC를 실행하기 전에는 장기 실행 shell, tmux, editor가 old store path를 계속 호출할 수 있다는 점을 고려한다.
- stable 경로를 만들더라도 그 링크가 profile generation 또는 명시적인 GC root에 의해 보존되는지 확인한다. Nix 공식 root 규칙상 임의의 사용자 디렉터리 symlink를 자동 root로 가정하지 않는다. [Nix garbage collector roots 규칙](https://nix.dev/manual/nix/2.34/package-management/garbage-collector-roots)

## zsh startup 파일 동작

zsh 공식 매뉴얼의 기본 순서는 다음과 같다. `ZDOTDIR`이 unset이면 `HOME`이 사용된다.

| 파일                                  | 읽히는 조건                                                                   | 이 문제와의 관계                                                |
| ------------------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `/etc/zshenv`, `$ZDOTDIR/.zshenv`     | 모든 zsh 실행. 단, `RCS`가 꺼지거나 `zsh -f`이면 사용자 startup 파일이 생략됨 | 환경과 매우 이른 초기화. Starship prompt를 두기에는 범위가 넓음 |
| `/etc/zprofile`, `$ZDOTDIR/.zprofile` | login shell                                                                   | login 환경. interactive 여부와 별개                             |
| `/etc/zshrc`, `$ZDOTDIR/.zshrc`       | interactive shell                                                             | Home Manager Starship integration이 들어가는 위치               |
| `/etc/zlogin`, `$ZDOTDIR/.zlogin`     | login shell, `.zshrc` 뒤                                                      | login 전용 후처리                                               |
| `$ZDOTDIR/.zlogout`, `/etc/zlogout`   | login shell 종료 시                                                           | `exec`로 다른 프로세스로 교체하면 읽히지 않음                   |

Home Manager zsh module도 `envExtra`를 `.zshenv`, `profileExtra`를 `.zprofile`, `initContent`를 `.zshrc`, `loginExtra`를 `.zlogin`, `logoutExtra`를 `.zlogout`에 연결한다. 현재 고정 소스는 마지막에 `programs.zsh.initContent`를 `.zshrc`의 `text`로 넣는다. [Home Manager zsh startup option 정의](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/zsh/default.nix#L316-L365), [Home Manager zsh 파일 생성](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/zsh/default.nix#L518-L578), [Home Manager `.zshrc` materialization](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/zsh/default.nix#L700-L712)

따라서 switch 후 적용 절차는 다음처럼 해석한다.

- 새 터미널: 새 interactive zsh가 `.zshrc`를 읽고 current generation의 Starship init을 평가한다.
- 기존 터미널: 기존 process state를 유지하므로 자동 갱신되지 않는다.
- 명시적 refresh: `exec zsh -l`은 현재 shell을 새 login zsh로 교체한다. zsh 공식 문서상 `exec`로 교체된 이전 login shell의 logout 파일은 실행되지 않는다.
- `source ~/.zshrc`: 현재 shell에서 파일을 다시 실행한다. 즉시 실험에는 쓸 수 있지만, clean process refresh의 대안으로 취급하지 않는다.

## 현재 저장소에 대한 적용

### 현재 선언과 로컬 관찰

- `users/shared/programs/starship.nix`는 `programs.starship.enable = true`, `enableZshIntegration = true`를 선언하고 비어 있지 않은 `settings`를 제공한다.
- `users/shared/programs/zsh/default.nix`는 `programs.zsh.dotDir = config.home.homeDirectory`를 선언한다. 따라서 이 설정의 zsh startup 파일은 home directory 기준이다.
- `users/shared/home-manager.nix`는 `home.stateVersion = "24.11"`과 `xdg.enable = true`를 사용한다. zsh `dotDir`는 별도로 home directory로 고정되어 있다.
- 2026-08-27에 파일 내용의 비밀값을 출력하지 않고 링크와 Starship 관련 행만 읽은 결과, `/Users/jito.hello/.zshrc`는 `/nix/store/<hash>-home-manager-files/.zshrc`를 가리켰고 생성 파일에는 다음 형태의 행이 있었다.

  ```zsh
  eval "$(/nix/store/<hash>-starship-1.26.0/bin/starship init zsh)"
  ```

  이 로컬 관찰은 Home Manager와 Starship 공식 소스가 설명하는 경로 모델과 일치한다.

### 적용 판단

1. `users/shared/programs/starship.nix`는 `programs.starship.enableZshIntegration = false`로 두고, 같은 `pkgs.starship`를 `home.file.".local/bin/starship"`의 source로 선언한다.
2. `programs.zsh.initContent`는 `TERM != "dumb"`와 stable executable 존재 여부를 확인한 뒤 `"$HOME/.local/bin/starship" init zsh`를 평가한다.
3. `tests/integration/starship-configuration-test.nix`는 built-in integration 비활성화, stable path 사용, zsh init 내 `/nix/store` 부재, source target 일치를 검증한다.
4. `make switch-home` 또는 시스템 activation 뒤 기존 stale prompt가 보이면 old shell의 장애로 먼저 분류하고 `exec zsh -l`로 refresh한다. active agent가 있는 herdr pane은 자동으로 재시작하지 않는다.
5. `rehash`만으로 해결됐다고 판단하지 않는다. old `PROMPT`에 direct store path가 남아 있는지와 현재 `.zshrc`의 path를 별도로 확인한다.

### 비밀값을 노출하지 않는 확인 항목

다음 확인은 경로와 상태만 출력하도록 제한한다.

```zsh
readlink /Users/jito.hello/.zshrc
rg -n 'starship init zsh' /Users/jito.hello/.zshrc
readlink /Users/jito.hello/.nix-profile
readlink /Users/jito.hello/.nix-profile/bin/starship
nix-store --gc --print-roots | rg 'home-manager|starship'
```

실행 중인 shell의 prompt가 어떤 경로를 보유하는지 확인할 때도 prompt 변수 전체나 환경 전체를 수집하지 말고 Starship 경로만 필터링한다.

## 공식 자료와 확인 날짜

모든 외부 자료는 2026-08-27 (Asia/Seoul)에 확인했다. Home Manager 링크는 현재 저장소의 `flake.lock`이 고정한 `6840c9a8f50722944eb106ce8bb237c138584f2a` 커밋을 사용했고, Starship 소스 링크는 같은 날짜에 확인한 `main`의 `0b48f454da65c147b360c3d7357d16412d00df4c` 커밋을 사용했다.

### Starship

- [Starship 공식 설치 및 zsh 설정 문서](https://starship.rs/guide/)
- [Starship 공식 init path resolution 소스](https://github.com/starship/starship/blob/0b48f454da65c147b360c3d7357d16412d00df4c/src/init/mod.rs)
- [Starship 공식 zsh init template](https://github.com/starship/starship/blob/0b48f454da65c147b360c3d7357d16412d00df4c/src/init/starship.zsh)

### Home Manager

- [Home Manager Starship 옵션 문서](https://home-manager.dev/manual/unstable/options.html#opt-programs.starship.enableZshIntegration)
- [Home Manager Starship module source](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/starship.nix)
- [Home Manager zsh module source](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/programs/zsh/default.nix)
- [Home Manager home environment와 GC root source](https://github.com/nix-community/home-manager/blob/6840c9a8f50722944eb106ce8bb237c138584f2a/modules/home-environment.nix)

### Nix

- [Nix Profiles](https://nix.dev/manual/nix/2.34/package-management/profiles)
- [`nix profile` filesystem layout와 generation roots](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-profile)
- [Nix Garbage Collection](https://nix.dev/manual/nix/2.34/package-management/garbage-collection)
- [Nix Garbage Collector Roots](https://nix.dev/manual/nix/2.34/package-management/garbage-collector-roots)
- [Nix Store Path](https://nix.dev/manual/nix/2.34/store/store-path)

### zsh

- [zsh 공식 Startup/Shutdown Files](https://zsh.sourceforge.io/Doc/Release/Files.html)
- [zsh 공식 Shell Builtin Commands: `eval`, `source`, `exec`](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html)
- [zsh 공식 Options: `RCS`, `GLOBAL_RCS`, `INTERACTIVE`, `LOGIN`](https://zsh.sourceforge.io/Doc/Release/Options.html)
