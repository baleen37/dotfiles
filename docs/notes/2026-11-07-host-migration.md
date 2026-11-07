# 호스트별 구성 이관 검증

기존 작업 트리의 설정을 기준으로 비교했다. 기존 Raycast·RustDesk·Karabiner·설치 스크립트 수정도 기준에 포함했다. 시스템 활성화나 앱 삭제는 실행하지 않았다.

## 설치 구성 보존

[이관 전 목록](2026-11-07-host-migration-inventory.json)에 호스트별 시스템 패키지, 사용자 패키지, Homebrew casks/brews/taps, App Store 앱, 기능 선택과 sudo 규칙을 기록했다. 동일 구성은 하나로 묶었다. 패키지 이름에는 버전을 포함한다.

이관 전후 다음 항목이 일치했다.

- 등록된 Mac 3대, NixOS/WSL 3대, 로컬 Mac의 패키지 집합과 Homebrew/App Store 목록.
- 독립 Home Manager 출력 4개의 패키지 집합.
- Mac의 NSGlobalDomain, Dock, Finder, Trackpad, CustomUserPreferences, 로그인 화면 설정과 sudo 규칙.
- 모든 출력의 Home Manager 활성화 derivation 경로. `.hammerspoon` 소스의 저장소 루트 해시만 달라졌으며 활성화 결과는 동일했다.

비교 원본은 `/tmp/dotfiles-host-migration/{before,after}.json`에 있다. 무시된 기존 `hosts.local.nix`는 기존 설치 보존을 위해 `macbook-pro.nix`를 참조하도록 로컬에서만 갱신했다. 설치 스크립트가 새로 등록하는 호스트는 계속 `common.nix`만 사용한다.

## 실제 CLI 관찰

격리 복사본에 새 호스트를 등록하고 `nix eval ...#darwinConfigurations.minimal-probe.config --json --apply ...`를 실행했다.

```json
{
  "casks": [],
  "masApps": {},
  "shell": true,
  "git": true,
  "ssh": true,
  "packages": [
    "zsh",
    "nix-zsh-completions",
    "man-db",
    "git",
    "git-lfs",
    "hm-session-vars.sh",
    "age"
  ],
  "daemons": ["activate-system"]
}
```

개인 활성화 훅은 없었다. `minimal-probe.system.drvPath`도 정상 평가됐다. Home Manager는 기본 Zsh dotDir의 향후 변경 경고를 표시했다. 기존 stateVersion을 유지했다.

다른 격리 복사본에서 `macbook-pro`의 Hammerspoon만 끄고 두 출력을 CLI로 읽었다.

```json
{
  "changed": { "app": false, "enabled": false, "files": false },
  "other": { "app": true, "enabled": true, "files": true }
}
```

## 자동 검증

| 검증                                                    | 결과                                        |
| ------------------------------------------------------- | ------------------------------------------- |
| `nix flake check --no-build --all-systems --show-trace` | Darwin·Linux x86_64·Linux aarch64 평가 통과 |
| Darwin `all-assertions` 실제 빌드                       | 117개 단위·통합 검증 통과                   |
| 최소 호스트·기능 제거·호스트 격리 회귀 테스트           | 통과                                        |
| Linux x86_64·aarch64 `all-assertions` 실제 빌드         | Linux 빌더 부재로 실행 불가                 |
| Linux VM 실행                                           | macOS이며 Linux/KVM 빌더가 없어 미실행      |

Linux 빌드 오류는 `Required system: x86_64-linux; Current system: aarch64-darwin` 또는 사용 가능한 빌더 부재다. Linux 실행 검증은 해당 플랫폼의 CI에서 남아 있다.

새 파일이 평가에 포함되도록 `path:` 복사본을 사용했다. 추적 호스트 목록을 검사하는 테스트에서는 무시된 로컬 등록을 제외했다. 상세 로그는 `/tmp/dotfiles-host-migration/`에 있다.

## 후속 재검증

현재 작업 트리를 새 격리 복사본으로 다시 검증했다.

- 전체 3개 플랫폼 평가와 Darwin `all-assertions` 빌드가 성공했다.
- 기존 `macbook-pro.system`과 새 `minimal-probe.system` 전체 빌드가 모두 종료 코드 0으로 성공했다. 활성화는 실행하지 않았다.
- 이관 전 스냅샷과 다시 비교해 시스템 호스트 7개·독립 Home Manager 4개의 설치 구성과 사용자 활성화 derivation이 일치했다.
- Hammerspoon·Karabiner·RustDesk·VS Code를 한 호스트에서 비활성화했을 때 앱과 관련 설정이 제외됐고 다른 호스트에는 유지됐다.
- Karabiner는 `xdg.configFile`이 아닌 `home.file.".config/karabiner/karabiner.json"`으로 배포된다. CLI에서 비활성 호스트는 파일 없음, 다른 호스트는 파일 존재를 확인했다. 회귀 테스트도 실제 경로를 검사하도록 바로잡았다.

Linux 실제 빌드·VM 실행은 앞서 확인한 Linux 빌더 부재로 여전히 미검증이다.
