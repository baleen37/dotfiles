# Sub-project 1: `modules.*` 네임스페이스 도입 — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `users/shared/programs/*.nix` 10개와 `users/shared/packages/*.nix` 11개를 NixOS-style `modules.<programs|packages>.<name>.enable` 옵션 모듈로 변환해 일관된 패턴을 확립한다.

**Architecture:** mkEnableOption은 default=false 원칙 유지 (안티패턴 제거). 활성화는 `users/shared/home-manager.nix`에서 명시적으로. 플랫폼 종속 모듈(hammerspoon/karabiner/ghostty)만 home-manager 공식 `launchd.enable` 패턴 따라 `default = pkgs.stdenv.hostPlatform.isDarwin`.

**Tech Stack:** Nix, nixpkgs `lib.mkEnableOption` / `lib.mkIf` / `lib.types`, home-manager modules.

**Spec:** `docs/superpowers/specs/2026-05-25-home-manager-module-options-design.md` — Sub-project 1

---

## 파일 구조

| 경로                                    | 책임                                                                                                        | 변경 종류 |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------- |
| `users/shared/programs/*.nix` (10개)    | 각 프로그램 모듈 — `modules.programs.<name>.enable` 정의                                                    | 수정      |
| `users/shared/programs/zsh/default.nix` | zsh 모듈 진입점 — `modules.programs.zsh.enable` 정의                                                        | 수정      |
| `users/shared/packages/*.nix` (11개)    | 각 패키지 카테고리 — `modules.packages.<name>.enable` 정의 (`myHome` → `modules` 리네임, default=true 제거) | 수정      |
| `users/shared/home-manager.nix`         | 모듈 활성화 정책                                                                                            | 수정      |
| `tests/unit/modules-namespace-test.nix` | 새 unit test — 모든 모듈에 enable 옵션 존재 검증                                                            | 신규      |
| `CLAUDE.md`                             | enable-flag 패턴 서술 정합                                                                                  | 수정      |

**Sub-task 그룹:**

- A. packages/ 11개 리네임·default=true 제거 (가장 단순, 회귀 위험 적음)
- B. programs/ 10개 옵션화 (도메인별로 4개 단계 분할)
- C. home-manager.nix 활성화 블록 추가
- D. 새 unit test
- E. CLAUDE.md 업데이트
- F. 최종 검증

### Task 1: packages/core.nix 변환 (참조 모델)

이 첫 task는 packages 11개 변환의 표준 형태를 확립한다. 나머지 packages는 같은 패턴으로 일괄.

**Files:**

- Modify: `users/shared/packages/core.nix`

- [ ] **Step 1: 현재 파일 확인**

```bash
cat users/shared/packages/core.nix
```

Expected: `options.myHome.packages.core.enable = lib.mkEnableOption "core utilities" // { default = true; };` 라인 존재.

- [ ] **Step 2: 파일 수정 (네임스페이스 리네임 + default=true 제거)**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.core;
in
{
  options.modules.packages.core.enable = lib.mkEnableOption "core utilities";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wget
      curl
      zip
      unzip
      tree
      htop
      jq
      ripgrep
      fd
      bat
      eza
      fzf
    ];
  };
}
```

변경점: `myHome` → `modules`, `// { default = true; }` 제거. 패키지 리스트는 그대로.

- [ ] **Step 3: 빌드는 아직 깨진 상태 (활성화 누락) — diff만 확인**

```bash
git diff users/shared/packages/core.nix
```

Expected: 정확히 `myHome` → `modules` 1줄과 `// { default = true; }` 제거 1줄.

- [ ] **Step 4: Commit (incremental — 활성화는 Task 12에서 한꺼번에)**

```bash
git add users/shared/packages/core.nix
git commit -m "refactor(packages): rename myHome.packages.core to modules.packages.core"
```

> 빌드는 packages 활성화가 home-manager.nix에 추가될 때까지 깨진다. Task 12까지 누적된다. Sub-task 그룹 A 전체를 한 PR로 머지하므로 OK.

### Task 2: packages/dev.nix 변환

**Files:** Modify: `users/shared/packages/dev.nix`

- [ ] **Step 1: 파일 수정**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.dev;
in
{
  options.modules.packages.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_22
      bun
      python3
      python3Packages.pipx
      virtualenv
      uv
      direnv
      pre-commit
      vscode
      gnumake
      cmake
    ];
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/packages/dev.nix
git commit -m "refactor(packages): rename myHome.packages.dev to modules.packages.dev"
```

### Task 3: packages/lsp.nix 변환

**Files:** Modify: `users/shared/packages/lsp.nix`

- [ ] **Step 1: 파일 읽고 패키지 리스트 확인**

```bash
cat users/shared/packages/lsp.nix
```

- [ ] **Step 2: Task 1과 동일한 패턴으로 변환**

핵심 변경 2개만:

- `myHome.packages.lsp` → `modules.packages.lsp`
- `lib.mkEnableOption "..." // { default = true; }` → `lib.mkEnableOption "..."`

패키지 리스트(`home.packages = ...`)는 절대 건드리지 않는다.

- [ ] **Step 3: diff 확인**

```bash
git diff users/shared/packages/lsp.nix
```

Expected: 정확히 2줄 변경 (네임스페이스 1줄 + default 제거 1줄), 패키지 리스트 변화 0.

- [ ] **Step 4: Commit**

```bash
git add users/shared/packages/lsp.nix
git commit -m "refactor(packages): rename myHome.packages.lsp to modules.packages.lsp"
```

### Task 4-11: packages/{nix-tools, cloud, security, ssh, media, fonts, databases, ai}.nix 변환

각 파일에 대해 Task 3과 동일한 단계 (읽기 → 2줄 수정 → diff 확인 → commit).

**Files:**

- Modify: `users/shared/packages/nix-tools.nix`
- Modify: `users/shared/packages/cloud.nix`
- Modify: `users/shared/packages/security.nix`
- Modify: `users/shared/packages/ssh.nix`
- Modify: `users/shared/packages/media.nix`
- Modify: `users/shared/packages/fonts.nix`
- Modify: `users/shared/packages/databases.nix`
- Modify: `users/shared/packages/ai.nix`

각 파일에 대해:

- [ ] **Step 1: 파일 읽기로 enable description 문구 확인**

```bash
grep "mkEnableOption" users/shared/packages/<name>.nix
```

Expected: `options.myHome.packages.<name>.enable = lib.mkEnableOption "<desc>" // { default = true; };`

- [ ] **Step 2: 정확히 2줄 수정**
  - `cfg = config.myHome.packages.<name>;` → `cfg = config.modules.packages.<name>;`
  - `options.myHome.packages.<name>.enable = lib.mkEnableOption "<desc>" // { default = true; };` → `options.modules.packages.<name>.enable = lib.mkEnableOption "<desc>";`

- [ ] **Step 3: diff 확인**

```bash
git diff users/shared/packages/<name>.nix
```

- [ ] **Step 4: Commit**

```bash
git add users/shared/packages/<name>.nix
git commit -m "refactor(packages): rename myHome.packages.<name> to modules.packages.<name>"
```

8개 파일 모두 동일한 단계. 총 8개 커밋.

### Task 12: packages 전체 활성화 — home-manager.nix에 활성화 블록 추가

이 task로 그룹 A(packages) 완료. 빌드가 다시 통과한다.

**Files:** Modify: `users/shared/home-manager.nix`

- [ ] **Step 1: 현재 home-manager.nix 확인**

```bash
cat users/shared/home-manager.nix
```

Expected: imports 블록과 home {...} 블록만 존재.

- [ ] **Step 2: imports 블록 직후, home {...} 직전에 활성화 블록 추가**

home-manager.nix 끝 부분 (`xdg.enable = true;` 직전 또는 직후)에 다음을 추가:

```nix
  # Enable all package categories (default=false in module, explicitly enabled here)
  modules.packages = {
    core.enable = true;
    dev.enable = true;
    lsp.enable = true;
    nix-tools.enable = true;
    cloud.enable = true;
    security.enable = true;
    ssh.enable = true;
    media.enable = true;
    fonts.enable = true;
    databases.enable = true;
    ai.enable = true;
  };
```

- [ ] **Step 3: 빌드 통과 확인**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -20
```

Expected: error 없이 완료. (warning은 OK)

- [ ] **Step 4: 실제 머신 빌드 확인 (가장 흔한 머신 1개)**

```bash
export USER=$(whoami)
nix build '.#darwinConfigurations.macbook-pro.system' --impure --no-link 2>&1 | tail -10
```

Expected: 빌드 성공. (이미 캐시되어 있으면 즉시 완료.)

- [ ] **Step 5: Commit**

```bash
git add users/shared/home-manager.nix
git commit -m "feat(home): explicitly enable modules.packages.* (default=false)"
```

### Task 13: programs/git.nix 옵션화

여기부터 그룹 B(programs). git은 가장 단순한 케이스 — `programs.git.enable = true`를 우리 게이트 안으로 옮긴다.

**Files:** Modify: `users/shared/programs/git.nix`

- [ ] **Step 1: 현재 파일 확인**

```bash
head -40 users/shared/programs/git.nix
```

Expected: `_:` 인자, `userInfo` let 바인딩, `programs.git = { enable = true; ... }` config 블록.

- [ ] **Step 2: 모듈을 NixOS-style options + config로 래핑**

수정 후 모양:

```nix
# Git 버전 관리 설정
# ... (기존 주석 그대로 유지)

{ config, lib, ... }:

let
  # User information from lib/user-info.nix
  userInfo = import ../../../lib/user-info.nix;
  inherit (userInfo) name email;
  cfg = config.modules.programs.git;
in
{
  options.modules.programs.git.enable = lib.mkEnableOption "Git configuration";

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs = {
        enable = true;
      };
      signing.format = "openpgp";

      settings = {
        # ... 기존 settings 블록 그대로
      };

      # ... 기존 모든 설정 그대로
    };
  };
}
```

주의:

- 인자: `_:` → `{ config, lib, ... }:`
- let 블록에 `cfg = config.modules.programs.git;` 한 줄 추가
- 전체 `programs.git = { ... }`을 `config = lib.mkIf cfg.enable { ... }`로 감싸기
- 기존 settings, aliases, ignores 모두 그대로 유지

- [ ] **Step 3: 평가만 빠르게 확인 (활성화 아직 안 함, eval error만 검출)**

```bash
export USER=$(whoami)
nix eval '.#homeConfigurations."baleen".config.modules.programs.git.enable' --impure 2>&1 | tail -5
```

Expected: `false` (default).

- [ ] **Step 4: Commit**

```bash
git add users/shared/programs/git.nix
git commit -m "refactor(programs): gate git config behind modules.programs.git.enable"
```

### Task 14: programs/vim.nix 옵션화

**Files:** Modify: `users/shared/programs/vim.nix`

- [ ] **Step 1: 모듈 래핑**

```nix
# Vim Editor Configuration
# ... (기존 주석 유지)

{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.vim;
in
{
  options.modules.programs.vim.enable = lib.mkEnableOption "Vim editor configuration";

  config = lib.mkIf cfg.enable {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-airline
        vim-airline-themes
        vim-tmux-navigator
      ];
      settings = {
        ignorecase = true;
      };
      extraConfig = ''
        # ... 기존 extraConfig 멀티라인 문자열 그대로
      '';
    };
  };
}
```

주의: 기존 `extraConfig` 멀티라인은 1글자도 건드리지 않는다.

- [ ] **Step 2: eval 확인**

```bash
export USER=$(whoami)
nix eval '.#homeConfigurations."baleen".config.modules.programs.vim.enable' --impure 2>&1 | tail -5
```

Expected: `false`.

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/vim.nix
git commit -m "refactor(programs): gate vim config behind modules.programs.vim.enable"
```

### Task 15: programs/zsh/default.nix 옵션화

zsh는 디렉토리 모듈. `default.nix` 한 군데에만 enable 추가, 하위 imports는 그대로.

**Files:** Modify: `users/shared/programs/zsh/default.nix`

- [ ] **Step 1: 현재 파일 전체 확인**

```bash
cat users/shared/programs/zsh/default.nix
```

- [ ] **Step 2: 모듈 래핑 — imports/let은 유지, 나머지를 `config = lib.mkIf cfg.enable {...}`로**

```nix
# Zsh Shell Environment Configuration
# ... (기존 주석 유지)

{
  lib,
  config,
  isDarwin,
  ...
}:

let
  cfg = config.modules.programs.zsh;
in
{
  imports = [
    ./env.nix
    ./functions.nix
    ./gw.nix
    ./claude-wrappers.nix
    ./ssh-agent.nix
  ];

  options.modules.programs.zsh.enable = lib.mkEnableOption "Zsh shell environment";

  config = lib.mkIf cfg.enable {
    # ... 기존 programs.zsh = {...} 등 나머지 전부 들여쓰기 한 단계 추가
  };
}
```

> `imports`는 options/config과 같은 레벨에 있어야 한다. options와 config 안에 들어가면 안 됨. 위 구조 그대로.

- [ ] **Step 3: 하위 zsh 모듈들도 cfg.enable에 게이팅되는지 확인**

`./env.nix`, `./functions.nix`, `./gw.nix`, `./claude-wrappers.nix`, `./ssh-agent.nix`는 각각 자체 `programs.zsh.*` 또는 `home.*` 설정을 한다. 이들은 zsh.enable의 mkIf로 감싸지지 **않는다** (imports는 상위 mkIf의 영향을 받지 않음). 다만 이들의 효과는 `programs.zsh.enable = true`에 의존하므로, default.nix의 cfg.enable=false이면 programs.zsh.enable도 false가 되어 하위 모듈의 zsh 관련 설정은 home-manager가 무시한다.

→ 즉, 하위 모듈 수정 불필요. **단** 만약 하위 모듈이 `programs.zsh.enable`과 무관한 home.\* 설정을 한다면 (예: ssh-agent.nix의 환경변수), 그건 cfg.enable과 별개로 적용된다. 이 부분은 의도된 동작인지 확인 필요.

```bash
grep -l "programs.zsh" users/shared/programs/zsh/*.nix
grep -l "home\." users/shared/programs/zsh/*.nix | xargs grep -L "programs.zsh"
```

첫 번째 명령: zsh 관련 모듈. 두 번째 명령: zsh 비의존 home.\* 만 쓰는 모듈 (있다면 별도 검토 필요).

- [ ] **Step 4: Commit**

```bash
git add users/shared/programs/zsh/default.nix
git commit -m "refactor(programs): gate zsh config behind modules.programs.zsh.enable"
```

### Task 16: programs/tmux.nix 옵션화

**Files:** Modify: `users/shared/programs/tmux.nix`

- [ ] **Step 1: 파일 읽기**

```bash
head -30 users/shared/programs/tmux.nix
```

- [ ] **Step 2: Task 13/14와 동일한 패턴으로 래핑**

```nix
# ... (기존 주석)

{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.tmux;
in
{
  options.modules.programs.tmux.enable = lib.mkEnableOption "Tmux multiplexer configuration";

  config = lib.mkIf cfg.enable {
    # ... 기존 programs.tmux = {...} 전체
  };
}
```

기존 인자 시그니처가 `{ pkgs, ... }`이면 `config`와 `lib`을 추가. 다른 인자가 있다면 모두 보존.

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/tmux.nix
git commit -m "refactor(programs): gate tmux config behind modules.programs.tmux.enable"
```

### Task 17: programs/starship.nix 옵션화

**Files:** Modify: `users/shared/programs/starship.nix`

- [ ] **Step 1: 파일 읽기**

```bash
head -30 users/shared/programs/starship.nix
```

- [ ] **Step 2: 동일 패턴 래핑**

```nix
# ... (기존 주석)

{ config, lib, ... }:

let
  cfg = config.modules.programs.starship;
in
{
  options.modules.programs.starship.enable = lib.mkEnableOption "Starship prompt configuration";

  config = lib.mkIf cfg.enable {
    # ... 기존 programs.starship = {...} 전체
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/starship.nix
git commit -m "refactor(programs): gate starship config behind modules.programs.starship.enable"
```

### Task 18: programs/codex.nix 옵션화

**Files:** Modify: `users/shared/programs/codex.nix`

- [ ] **Step 1: 파일 읽기**

```bash
head -40 users/shared/programs/codex.nix
```

- [ ] **Step 2: 동일 패턴 래핑**

기존 인자 + `config`와 `lib` 보장. let 블록에 `cfg = config.modules.programs.codex;`. options + config wrap.

```nix
# ... (기존 주석)

{ config, lib, ... }:  # 또는 기존 인자에 config, lib 보강

let
  cfg = config.modules.programs.codex;
in
{
  options.modules.programs.codex.enable = lib.mkEnableOption "Codex CLI configuration";

  config = lib.mkIf cfg.enable {
    # ... 기존 내용 전체 들여쓰기
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/codex.nix
git commit -m "refactor(programs): gate codex config behind modules.programs.codex.enable"
```

### Task 19: programs/opencode.nix 옵션화

**Files:** Modify: `users/shared/programs/opencode.nix`

- [ ] **Step 1: 동일 패턴 (description: "OpenCode CLI configuration")**

```nix
{ config, lib, ... }:
let cfg = config.modules.programs.opencode; in
{
  options.modules.programs.opencode.enable = lib.mkEnableOption "OpenCode CLI configuration";
  config = lib.mkIf cfg.enable {
    # ... 기존
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add users/shared/programs/opencode.nix
git commit -m "refactor(programs): gate opencode config behind modules.programs.opencode.enable"
```

### Task 20: programs/claude-code.nix 옵션화 (빈 모듈)

claude-code.nix는 외부 plugin로 이전되어 빈 모듈(`_: { }`)이다. 통일성을 위해 옵션은 추가하지만 config는 빈 채로.

**Files:** Modify: `users/shared/programs/claude-code.nix`

- [ ] **Step 1: 수정**

```nix
# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix
#
# NOTE: commands, agents, skills, and hooks are now managed via external plugin:
# https://github.com/baleen37/claude-plugins

{ config, lib, ... }:

let
  cfg = config.modules.programs.claude-code;
in
{
  options.modules.programs.claude-code.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf cfg.enable { };
}
```

> 빈 config여도 enable 옵션을 노출하는 이유: 일관성. 미래에 설정이 추가될 때 옵션 인터페이스가 이미 자리잡혀 있음. 빈 모듈에 옵션 추가가 "over-engineering"이라는 우려가 있다면, 이 한 모듈만 imports에서 제거하는 것도 대안이지만 그건 별도 결정.

- [ ] **Step 2: Commit**

```bash
git add users/shared/programs/claude-code.nix
git commit -m "refactor(programs): gate claude-code module behind modules.programs.claude-code.enable"
```

### Task 21: programs/hammerspoon.nix 옵션화 (플랫폼 종속)

여기부터 플랫폼 종속 모듈. `default = pkgs.stdenv.hostPlatform.isDarwin` 패턴 사용.

**Files:** Modify: `users/shared/programs/hammerspoon.nix`

- [ ] **Step 1: 수정**

```nix
# users/shared/hammerspoon.nix
# Hammerspoon configuration

{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.hammerspoon;
in
{
  options.modules.programs.hammerspoon.enable = lib.mkEnableOption "Hammerspoon (macOS)" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    # Pattern: Tool-specific home directory (destination: ~/.hammerspoon/)
    # Hammerspoon requires configuration in ~/.hammerspoon/ (non-XDG)
    home.file.".hammerspoon" = {
      source = ./.config/hammerspoon;
      recursive = true;
      force = true;
    };
  };
}
```

변경점:

- 인자: `{ lib, isDarwin, ... }` → `{ config, lib, pkgs, ... }` (specialArgs `isDarwin` 의존 제거)
- 기존 `lib.mkIf isDarwin {...}` 게이트 제거 (default가 isDarwin이라서 이중 게이트 불필요)
- options에 default 추가

- [ ] **Step 2: eval 확인**

```bash
export USER=$(whoami)
# Darwin 머신에서 enable=true (default)
nix eval '.#darwinConfigurations.macbook-pro.config.home-manager.users.baleen.modules.programs.hammerspoon.enable' --impure 2>&1 | tail -5
# NixOS 머신에서 enable=false (default)
nix eval '.#nixosConfigurations.vm-aarch64-utm.config.home-manager.users.baleen.modules.programs.hammerspoon.enable' --impure 2>&1 | tail -5
```

Expected: 첫 번째 `true`, 두 번째 `false`.

> 위 명령이 실패하면 eval 경로가 다를 수 있다. `nix eval '.#darwinConfigurations.macbook-pro.config' --apply 'c: c ? home-manager' --impure`로 home-manager 모듈 노출 여부 먼저 확인.

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/hammerspoon.nix
git commit -m "refactor(programs): gate hammerspoon behind modules.programs.hammerspoon.enable (default=isDarwin)"
```

### Task 22: programs/karabiner.nix 옵션화 (플랫폼 종속)

**Files:** Modify: `users/shared/programs/karabiner.nix`

- [ ] **Step 1: 수정 — Task 21과 동일 패턴**

```nix
# ... (기존 주석)

{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs.karabiner;
  # ... 기존 hyperApps 정의 그대로
in
{
  options.modules.programs.karabiner.enable = lib.mkEnableOption "Karabiner-Elements (macOS)" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    # ... 기존 lib.mkIf isDarwin 내부의 모든 내용을 한 단계 들여서 옮김
  };
}
```

주의: 기존 `lib.mkIf isDarwin {...}` 통째로 `cfg.enable` 게이트 안으로 이동. `isDarwin` specialArgs 의존 제거.

- [ ] **Step 2: Commit**

```bash
git add users/shared/programs/karabiner.nix
git commit -m "refactor(programs): gate karabiner behind modules.programs.karabiner.enable (default=isDarwin)"
```

### Task 23: programs/ghostty.nix 옵션화 (플랫폼 종속)

**Files:** Modify: `users/shared/programs/ghostty.nix`

ghostty는 플랫폼 분기가 있지만(`lib.optional isDarwin ghostty-bin`) 모듈 자체는 Darwin 한정이 아니다. ghostty.terminfo는 Linux에서도 설치된다. 즉 ghostty 모듈 전체를 `default = isDarwin`로 게이팅하면 Linux에서도 ghostty 관련 설정이 사라진다 — 의도와 다를 수 있음.

- [ ] **Step 1: 의도 확인**

ghostty는 양 플랫폼에서 의미 있다 (Darwin은 GUI, Linux는 terminfo만). 그래서 **ghostty는 `default = true`로 두고 플랫폼 분기는 내부에서 유지**한다. 즉 hammerspoon/karabiner와 다른 처리.

- [ ] **Step 2: 수정**

```nix
# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{
  config,
  pkgs,
  lib,
  isDarwin,
  ...
}:

let
  cfg = config.modules.programs.ghostty;
in
{
  options.modules.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal configuration";

  config = lib.mkIf cfg.enable {
    # ... 기존 home.packages, terminfo 설정 등 전체 그대로 (isDarwin 분기는 내부 유지)
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add users/shared/programs/ghostty.nix
git commit -m "refactor(programs): gate ghostty config behind modules.programs.ghostty.enable"
```

### Task 24: home-manager.nix에 programs 활성화 블록 추가

이제 모든 programs가 옵션화되었다. home-manager.nix에서 일괄 활성화.

**Files:** Modify: `users/shared/home-manager.nix`

- [ ] **Step 1: 수정**

기존 `modules.packages = {...}` 블록 바로 위 또는 아래에 추가:

```nix
  # Enable all programs (default=false in module, explicitly enabled here).
  # Platform-conditional modules (hammerspoon, karabiner) use module default
  # `default = pkgs.stdenv.hostPlatform.isDarwin` — do NOT override here.
  modules.programs = {
    git.enable = true;
    vim.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    starship.enable = true;
    claude-code.enable = true;
    codex.enable = true;
    opencode.enable = true;
    ghostty.enable = true;
    # hammerspoon, karabiner: module default = isDarwin
  };
```

- [ ] **Step 2: 빌드 확인 (모든 머신)**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -20
```

Expected: error 없음.

```bash
nix build '.#darwinConfigurations.macbook-pro.system' --impure --no-link 2>&1 | tail -10
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' --impure --no-link 2>&1 | tail -10
```

Expected: 둘 다 성공.

- [ ] **Step 3: Commit**

```bash
git add users/shared/home-manager.nix
git commit -m "feat(home): explicitly enable modules.programs.* (default=false)"
```

### Task 25: 새 unit test — 모든 모듈의 enable 옵션 존재 검증

**Files:** Create: `tests/unit/modules-namespace-test.nix`

- [ ] **Step 1: 테스트 파일 작성**

```nix
# tests/unit/modules-namespace-test.nix
#
# Verifies that every program and package module exposes its
# `modules.programs.<name>.enable` / `modules.packages.<name>.enable` option.
# This guards against accidental drift from the unified options pattern.

{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Names must match the actual options.modules.* paths declared in the modules.
  programNames = [
    "git"
    "vim"
    "zsh"
    "tmux"
    "starship"
    "claude-code"
    "codex"
    "opencode"
    "ghostty"
    "hammerspoon"
    "karabiner"
  ];

  packageNames = [
    "core"
    "dev"
    "lsp"
    "nix-tools"
    "cloud"
    "security"
    "ssh"
    "media"
    "fonts"
    "databases"
    "ai"
  ];

  # Evaluate users/shared/home-manager.nix as a standalone module to inspect its option tree.
  evalHmConfig = pkgs.lib.evalModules {
    modules = [
      ../../users/shared/home-manager.nix
      # Stub home-manager + nixpkgs interfaces just enough that the module loads.
      ({ ... }: {
        _module.args = {
          pkgs = pkgs;
          currentSystemUser = "testuser";
          isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
        };
        # Minimal home-manager option surface — only what's read by our modules.
        options.home = lib.mkOption { type = lib.types.attrs; default = { }; };
        options.programs = lib.mkOption { type = lib.types.attrs; default = { }; };
        options.xdg = lib.mkOption { type = lib.types.attrs; default = { }; };
      })
    ];
  };

  hasOption =
    path:
    let
      attrs = evalHmConfig.options;
      walk =
        a: parts:
        if parts == [ ] then
          true
        else if a ? ${builtins.head parts} then
          walk a.${builtins.head parts} (builtins.tail parts)
        else
          false;
    in
    walk attrs path;

  programTests = lib.listToAttrs (
    map (n: {
      name = "program-${n}-has-enable";
      value = helpers.assertTest "modules.programs.${n}.enable exists" (
        hasOption [ "modules" "programs" n "enable" ]
      ) "Module users/shared/programs/${n}.nix must declare options.modules.programs.${n}.enable";
    }) programNames
  );

  packageTests = lib.listToAttrs (
    map (n: {
      name = "package-${n}-has-enable";
      value = helpers.assertTest "modules.packages.${n}.enable exists" (
        hasOption [ "modules" "packages" n "enable" ]
      ) "Module users/shared/packages/${n}.nix must declare options.modules.packages.${n}.enable";
    }) packageNames
  );

in
programTests // packageTests
```

> 위 테스트는 evalModules로 home-manager.nix를 평가한다. 실제 home-manager 모듈을 다 import하지 않아도 옵션 트리만 확인하기 위함. 만약 home-manager의 imports로 인해 evalModules가 실패하면, 더 단순한 접근(각 모듈 파일을 직접 evalModules에 넣어 그 모듈의 options만 검사)으로 폴백.

- [ ] **Step 2: 테스트 실행**

```bash
export USER=$(whoami)
nix build '.#checks.aarch64-darwin.modules-namespace' --impure 2>&1 | tail -10
```

Expected: 빌드 성공.

> tests/default.nix가 unit/\*-test.nix를 자동 발견하면 위 명령이 작동. 안 되면 tests/default.nix 등록 필요 — 그 경우 `cat tests/default.nix | head -30`로 자동 발견 메커니즘 확인 후 등록.

- [ ] **Step 3: Commit**

```bash
git add tests/unit/modules-namespace-test.nix
git commit -m "test(modules): verify all programs/packages expose modules.*.enable"
```

### Task 26: 플랫폼 default 검증 unit test

**Files:** Create: `tests/unit/platform-defaults-test.nix`

- [ ] **Step 1: 테스트 작성**

```nix
# tests/unit/platform-defaults-test.nix
#
# Verifies that platform-conditional program modules (hammerspoon, karabiner)
# default to enable=false on non-Darwin platforms.

{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Evaluate the hammerspoon module standalone with a Linux-like pkgs to
  # confirm enable defaults to false.
  linuxPkgs = pkgs // {
    stdenv = pkgs.stdenv // {
      hostPlatform = pkgs.stdenv.hostPlatform // {
        isDarwin = false;
      };
    };
  };

  darwinPkgs = pkgs // {
    stdenv = pkgs.stdenv // {
      hostPlatform = pkgs.stdenv.hostPlatform // {
        isDarwin = true;
      };
    };
  };

  evalModule = modulePath: pkgsOverride:
    (pkgs.lib.evalModules {
      modules = [
        modulePath
        ({ ... }: {
          _module.args.pkgs = pkgsOverride;
        })
      ];
    }).config;

  hammerspoonOnLinux = evalModule ../../users/shared/programs/hammerspoon.nix linuxPkgs;
  hammerspoonOnDarwin = evalModule ../../users/shared/programs/hammerspoon.nix darwinPkgs;
  karabinerOnLinux = evalModule ../../users/shared/programs/karabiner.nix linuxPkgs;
  karabinerOnDarwin = evalModule ../../users/shared/programs/karabiner.nix darwinPkgs;

in
{
  hammerspoon-disabled-on-linux = helpers.assertTest
    "hammerspoon default=false on Linux"
    (hammerspoonOnLinux.modules.programs.hammerspoon.enable == false)
    "Hammerspoon module must default to enable=false on non-Darwin platforms";

  hammerspoon-enabled-on-darwin = helpers.assertTest
    "hammerspoon default=true on Darwin"
    (hammerspoonOnDarwin.modules.programs.hammerspoon.enable == true)
    "Hammerspoon module must default to enable=true on Darwin";

  karabiner-disabled-on-linux = helpers.assertTest
    "karabiner default=false on Linux"
    (karabinerOnLinux.modules.programs.karabiner.enable == false)
    "Karabiner module must default to enable=false on non-Darwin platforms";

  karabiner-enabled-on-darwin = helpers.assertTest
    "karabiner default=true on Darwin"
    (karabinerOnDarwin.modules.programs.karabiner.enable == true)
    "Karabiner module must default to enable=true on Darwin";
}
```

> hammerspoon/karabiner는 home-manager나 다른 모듈을 import 안 하므로 단순 evalModules로 충분.

- [ ] **Step 2: 테스트 실행**

```bash
export USER=$(whoami)
nix build '.#checks.aarch64-darwin.platform-defaults' --impure 2>&1 | tail -10
```

Expected: 성공.

- [ ] **Step 3: Commit**

```bash
git add tests/unit/platform-defaults-test.nix
git commit -m "test(modules): verify platform-conditional modules default to isDarwin"
```

### Task 27: CLAUDE.md 업데이트

기존 CLAUDE.md의 _"enable-flag pattern (default true)"_ 서술이 이제 틀렸다 (default=false, home-manager.nix에서 활성화).

**Files:** Modify: `CLAUDE.md`

- [ ] **Step 1: 해당 부분 찾기**

```bash
grep -n "enable-flag pattern" CLAUDE.md
```

Expected: 1줄 또는 그 부근에서 발견. 위치 기억.

- [ ] **Step 2: 수정**

해당 라인을 다음과 같이 변경:

```text
- Or create/modify specific tool configuration in `users/shared/programs/*.nix`

# Package categories (modules.packages.*.enable; default=false, enabled in home-manager.nix)
# Program modules (modules.programs.*.enable; default=false, enabled in home-manager.nix)
# Platform-conditional modules (hammerspoon, karabiner) default to pkgs.stdenv.hostPlatform.isDarwin
```

> 정확한 위치와 문구는 기존 CLAUDE.md 컨텍스트에 맞춰 자연스럽게. 핵심: "enable-flag pattern (default true)" 표현이 제거되고 "default=false, enabled in home-manager.nix"가 들어간다.

- [ ] **Step 3: grep 재확인 — 안티패턴 잔존 0건**

```bash
grep -rn "default = true" users/shared/{programs,packages}/*.nix
```

Expected: 결과 없음. (있다면 누락된 모듈 — 수정.)

```bash
grep -rn "myHome" users/shared/ CLAUDE.md
```

Expected: 결과 없음.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): align enable-flag pattern description with modules.* namespace"
```

### Task 28: 최종 검증 — 모든 머신 빌드

**Files:** (검증만)

- [ ] **Step 1: flake check**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -30
```

Expected: error 0건.

- [ ] **Step 2: 모든 머신 빌드**

```bash
export USER=$(whoami)
for h in macbook-pro baleen-macbook kakaostyle-jito; do
  echo "=== $h ==="
  nix build ".#darwinConfigurations.$h.system" --impure --no-link 2>&1 | tail -3
done
for h in vm-aarch64-utm vm-x86_64-utm; do
  echo "=== $h ==="
  nix build ".#nixosConfigurations.$h.config.system.build.toplevel" --impure --no-link 2>&1 | tail -3
done
```

Expected: 5개 모두 성공.

- [ ] **Step 3: make test**

```bash
make test
```

Expected: pass.

- [ ] **Step 4: 안티패턴 0건 최종 grep**

```bash
grep -rn "myHome\." users/ CLAUDE.md tests/
grep -rn 'mkEnableOption "[^"]*" // { default = true' users/
```

Expected: 둘 다 결과 없음.

- [ ] **Step 5: 이 시점에서 PR 생성 준비 — 별도 명령**

```bash
git log --oneline -30
```

Expected: 27~28개의 작은 커밋. PR 생성은 사용자 지시 후 별도로.

---

## Self-Review

**Spec coverage:**

- 모든 programs 10개 옵션화 ✓ (Task 13-23)
- 모든 packages 11개 옵션화 ✓ (Task 1-11)
- mkEnableOption default=true 제거 ✓ (Task 1-11)
- 플랫폼 종속 default ✓ (Task 21, 22)
- home-manager.nix 활성화 블록 ✓ (Task 12, 24)
- unit test 2개 ✓ (Task 25, 26)
- CLAUDE.md 정합 ✓ (Task 27)
- 최종 검증 ✓ (Task 28)

**Placeholder scan:** TBD/TODO 없음. ✓

**Type 일관성:** 모든 task가 `modules.<programs|packages>.<name>.enable`로 통일. ghostty가 plat-cond이 아니라는 결정(Task 23)이 명확히 기록됨. ✓

**알려진 위험:**

1. Task 15(zsh)에서 하위 모듈이 `programs.zsh.enable`과 무관한 home.\* 설정을 한다면 cfg.enable=false일 때도 살아남는다. Task 15 Step 3의 grep으로 사전 검증.
2. Task 21/22의 eval 명령이 home-manager 모듈의 실제 경로에 따라 안 먹을 수 있음 — Task 21 Step 2의 폴백 가이드 참고.
3. Task 25 unit test가 home-manager 의존성 때문에 evalModules에서 실패할 수 있음 — Task 25 노트에서 폴백 언급.
