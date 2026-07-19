# Sesh Tmux Session Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home Manager의 표준 sesh 모듈과 zoxide/fzf Zsh 통합을 활성화해 `prefix+T`에서 프로젝트별 tmux 세션을 검색·생성·전환한다.

**Architecture:** Zsh 모듈은 zoxide 방문 기록과 fzf tmux shell integration을 제공한다. Tmux 모듈은 Home Manager의 `programs.sesh`를 활성화하고 공식 예제와 같은 대문자 `T`만 지정하며, picker 구현과 패키지 설치는 Home Manager에 위임한다.

**Tech Stack:** Nix, Home Manager `programs.sesh`/`programs.zoxide`/`programs.fzf`, tmux, sesh 2.27.0, zoxide 0.10.0, fzf 0.74.0

## Global Constraints

- 현재 pinned Home Manager의 `programs.sesh` 모듈을 사용하고 수동 sesh 바인딩을 작성하지 않는다.
- sesh 키는 대문자 `T`로 지정해 `prefix+t` clock mode와 `prefix+s` choose-tree를 보존한다.
- Home Manager가 zoxide를 `compinit` 뒤에 초기화하도록 `programs.zoxide.enableZshIntegration = true`를 사용한다.
- sesh 모듈의 기본 아이콘, `s` 셸 별칭, tmux picker 동작을 유지한다.
- 별도 `sesh.toml`, Homebrew 설치, PATH 수정, picker 스크립트를 추가하지 않는다.
- 기존 tmux 플러그인, 키 바인딩, OSC52, 터미널 기능과 기존 fzf 옵션은 변경하지 않는다.

---

### Task 1: Zoxide와 fzf tmux 통합

**Files:**
- Modify: `tests/integration/zsh-test.nix:36-38,118-123`
- Modify: `users/shared/programs/zsh/default.nix:37-73`

**Interfaces:**
- Consumes: 기존 `programs.fzf`와 Home Manager의 `programs.zoxide` 옵션
- Produces: `programs.fzf.tmux.enableShellIntegration = true`, `programs.zoxide.enable = true`, `programs.zoxide.enableZshIntegration = true`

- [ ] **Step 1: 실패하는 Zsh 통합 테스트 작성**

`tests/integration/zsh-test.nix`의 설정 추출부에 zoxide를 추가한다.

```nix
  # Extract fzf, zoxide, and direnv settings
  fzfSettings = zshConfigBody.programs.fzf or { };
  zoxideSettings = zshConfigBody.programs.zoxide or { };
  direnvSettings = zshConfigBody.programs.direnv or { };
```

기존 `fzf-zsh-integration` 테스트 바로 뒤에 다음 세 테스트를 추가한다.

```nix
    (helpers.assertTest "fzf-tmux-integration" (
      fzfSettings.tmux.enableShellIntegration or false
    ) "fzf tmux shell integration should be enabled for sesh")
    (helpers.assertTest "zoxide-enabled" (zoxideSettings.enable or false)
      "zoxide should be enabled"
    )
    (helpers.assertTest "zoxide-zsh-integration" (
      zoxideSettings.enableZshIntegration or false
    ) "zoxide zsh integration should be enabled")
```

- [ ] **Step 2: 테스트가 기능 누락으로 실패하는지 확인**

Run:

```bash
nix build '.#checks.aarch64-darwin.integration-zsh' --no-link
```

Expected: FAIL하며 출력에 `fzf tmux shell integration should be enabled for sesh`, `zoxide should be enabled`, `zoxide zsh integration should be enabled` 중 하나 이상이 나타난다.

- [ ] **Step 3: 최소 Zsh 설정 구현**

`users/shared/programs/zsh/default.nix`의 `programs.fzf` 블록에서 Zsh integration 바로 아래에 tmux integration을 추가한다.

```nix
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
```

`programs.fzf` 블록 다음에 zoxide 설정을 추가한다.

```nix
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
```

- [ ] **Step 4: Zsh 통합 테스트 통과 확인**

Run:

```bash
nix build '.#checks.aarch64-darwin.integration-zsh' --no-link
```

Expected: PASS.

- [ ] **Step 5: 포맷과 diff 검증**

Run:

```bash
nix fmt -- --fail-on-change users/shared/programs/zsh/default.nix tests/integration/zsh-test.nix
git diff --check
```

Expected: 두 명령 모두 exit code 0이며 포맷 변경과 whitespace 오류가 없다.

- [ ] **Step 6: Zoxide/fzf 변경 커밋**

```bash
git add users/shared/programs/zsh/default.nix tests/integration/zsh-test.nix
git commit -m "feat(zsh): enable zoxide and fzf tmux integration"
```

Expected: 테스트와 설정 네 파일 중 이 task의 두 파일만 포함한 커밋이 생성된다.

---

### Task 2: Home Manager sesh tmux 피커

**Files:**
- Modify: `tests/integration/tmux-functionality-test.nix:27-41,79-82`
- Modify: `users/shared/programs/tmux.nix:45-46`

**Interfaces:**
- Consumes: Task 1의 fzf tmux integration, Home Manager `programs.sesh` 모듈
- Produces: `programs.sesh.enable = true`, `programs.sesh.tmuxKey = "T"`, Home Manager가 생성하는 `prefix+T` picker

- [ ] **Step 1: 실패하는 sesh 구성 테스트 작성**

`tests/integration/tmux-functionality-test.nix`에서 tmux 설정과 함께 sesh 설정을 추출한다.

```nix
  tmuxConfig = tmuxModule.config.content.programs.tmux;
  seshConfig = tmuxModule.config.content.programs.sesh or { };
```

`# Key bindings` 섹션의 첫 테스트로 다음 두 테스트를 추가한다.

```nix
  tmux-sesh-enabled = helpers.assertTest "tmux-sesh-enabled" (
    seshConfig.enable or false
  ) "tmux should enable sesh through Home Manager";

  tmux-sesh-key-is-uppercase-t = helpers.assertTest "tmux-sesh-key-is-uppercase-t" (
    (seshConfig.tmuxKey or null) == "T"
  ) "sesh should use prefix+T and preserve tmux prefix+t clock mode";
```

- [ ] **Step 2: 새 sesh 테스트가 실패하는지 확인**

Run:

```bash
nix build \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-enabled' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-key-is-uppercase-t' \
  --no-link
```

Expected: 두 check가 sesh 설정 누락 메시지로 FAIL한다.

- [ ] **Step 3: 최소 sesh 설정 구현**

`users/shared/programs/tmux.nix`에서 기존 `programs.tmux` 바로 앞에 다음 블록을 추가한다.

```nix
    programs.sesh = {
      enable = true;
      tmuxKey = "T";
    };

    programs.tmux = {
```

- [ ] **Step 4: sesh 집중 테스트 통과 확인**

Run:

```bash
nix build \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-enabled' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-key-is-uppercase-t' \
  --no-link
```

Expected: 두 check가 PASS한다.

- [ ] **Step 5: 관련 회귀 테스트와 전체 Darwin 구성 빌드**

Run:

```bash
nix build \
  '.#checks.aarch64-darwin.integration-zsh' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-prefix-is-ctrl-a' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-enabled' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-sesh-key-is-uppercase-t' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-split-vertical' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-split-horizontal' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-vim-pane-navigation' \
  --no-link
nix build '.#darwinConfigurations.kakaostyle-jito.system' --no-link
```

Expected: 모든 check와 Darwin system build가 PASS하며 `programs.sesh`의 fzf tmux assertion 오류가 없다.

- [ ] **Step 6: 포맷과 diff 검증**

Run:

```bash
nix fmt -- --fail-on-change users/shared/programs/tmux.nix tests/integration/tmux-functionality-test.nix
git diff --check
```

Expected: 두 명령 모두 exit code 0이며 포맷 변경과 whitespace 오류가 없다.

- [ ] **Step 7: sesh tmux 변경 커밋**

```bash
git add users/shared/programs/tmux.nix tests/integration/tmux-functionality-test.nix
git commit -m "feat(tmux): add sesh session picker"
```

Expected: 이 task의 설정과 테스트 두 파일만 포함한 커밋이 생성된다.

---

### Task 3: Home Manager 적용과 실제 키 검증

**Files:**
- Verify: generated Home Manager profile and `~/.config/tmux/tmux.conf`

**Interfaces:**
- Consumes: Task 1과 Task 2에서 커밋한 선언형 설정
- Produces: 현재 머신에 설치된 sesh/zoxide/fzf와 실제 tmux prefix key table 증거

- [ ] **Step 1: 현재 머신에 구성 적용**

Run:

```bash
make switch
```

Expected: `darwin-rebuild switch --flake ".#kakaostyle-jito"`가 exit code 0으로 완료된다.

- [ ] **Step 2: 설치된 CLI 버전 확인**

Run:

```bash
command -v sesh zoxide fzf
sesh --version
zoxide --version
fzf --version
```

Expected: 세 executable이 Home Manager/Nix profile에서 발견되고 각각 sesh `2.27.0`, zoxide `0.10.0`, fzf `0.74.0`을 출력한다.

- [ ] **Step 3: 생성된 설정에 sesh 바인딩이 있는지 확인**

Run:

```bash
rg -n 'bind-key "T" run-shell "sesh connect' ~/.config/tmux/tmux.conf
rg -n 'fzf --tmux 80%,70%' ~/.config/tmux/tmux.conf
```

Expected: 두 패턴 모두 Home Manager가 생성한 tmux 설정에서 발견된다.

- [ ] **Step 4: 격리된 tmux 서버에서 세 키를 검증**

Run:

```bash
verify_socket="sesh-picker-verify-$$"
tmux -L "$verify_socket" -f ~/.config/tmux/tmux.conf new-session -d -s verify
tmux -L "$verify_socket" list-keys -T prefix T
tmux -L "$verify_socket" list-keys -T prefix t
tmux -L "$verify_socket" list-keys -T prefix s
tmux -L "$verify_socket" kill-server
```

Expected:

```text
T -> run-shell ... sesh connect ... fzf --tmux 80%,70%
t -> clock-mode
s -> choose-tree
```

- [ ] **Step 5: 최종 저장소 상태 확인**

Run:

```bash
git status --short --branch
git log -3 --oneline
```

Expected: 구현 파일이 모두 커밋되어 worktree가 clean하고, 최신 커밋에 zoxide/fzf와 sesh picker 커밋이 보인다.
