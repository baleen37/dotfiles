# Tmux Session Plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home Manager의 tmux 구성에 세션 저장·자동 복원과 Neovim/tmux 탐색 플러그인을 추가한다.

**Architecture:** Home Manager의 `programs.tmux.plugins`가 Nix 패키지 설치와 로딩을 전담한다. Continuum의 자동 복원 옵션만 기존 `extraConfig`에 추가하며 TPM과 tmux-yank는 도입하지 않는다.

**Tech Stack:** Nix, Home Manager `programs.tmux`, nixpkgs `tmuxPlugins`, Nix flake checks

## Global Constraints

- 플러그인은 `resurrect`, `continuum`, `vim-tmux-navigator`만 이 순서로 추가한다.
- `set -g @continuum-restore 'on'`을 사용한다.
- TPM과 `tmux-yank`는 추가하지 않는다.
- 기존 tmux 설정은 변경하지 않는다.

---

### Task 1: Tmux 세션 플러그인 구성

**Files:**

- Modify: `tests/integration/tmux-functionality-test.nix`
- Modify: `users/shared/programs/tmux.nix`

**Interfaces:**

- Consumes: Home Manager의 `programs.tmux.plugins` 목록과 `extraConfig` 문자열
- Produces: 세 플러그인의 로딩 및 Continuum 자동 복원 설정

- [ ] **Step 1: 실패하는 플러그인 및 자동 복원 테스트 작성**

`tests/integration/tmux-functionality-test.nix`의 `tmux-has-zero-plugins`를 다음 네 테스트로 교체한다.

```nix
  tmux-has-resurrect-plugin = helpers.assertTest "tmux-has-resurrect-plugin" (
    pluginHelpers.hasPluginByName tmuxConfig.plugins "tmuxplugin-resurrect"
  ) "tmux should load tmux-resurrect through Home Manager";

  tmux-has-continuum-plugin = helpers.assertTest "tmux-has-continuum-plugin" (
    pluginHelpers.hasPluginByName tmuxConfig.plugins "tmuxplugin-continuum"
  ) "tmux should load tmux-continuum through Home Manager";

  tmux-has-vim-navigator-plugin = helpers.assertTest "tmux-has-vim-navigator-plugin" (
    pluginHelpers.hasPluginByName tmuxConfig.plugins "tmuxplugin-vim-tmux-navigator"
  ) "tmux should load vim-tmux-navigator through Home Manager";

  tmux-continuum-auto-restore =
    mkConfigTest "tmux-continuum-auto-restore" (hasConfigString "set -g @continuum-restore 'on'")
      "tmux continuum should restore saved sessions automatically";
```

- [ ] **Step 2: 새 테스트가 실패하는지 확인**

Run:

```bash
nix build \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-resurrect-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-continuum-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-vim-navigator-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-continuum-auto-restore \
  --no-link
```

Expected: 네 check가 현재 빈 플러그인 목록 또는 누락된 옵션 때문에 실패한다.

- [ ] **Step 3: 최소 tmux 설정 구현**

`users/shared/programs/tmux.nix`의 빈 플러그인 목록을 교체한다.

```nix
      plugins = with pkgs.tmuxPlugins; [
        resurrect
        continuum
        vim-tmux-navigator
      ];
```

`extraConfig`의 session settings 영역에 자동 복원 옵션을 추가한다.

```tmux
        # Restore the most recently saved session when tmux starts.
        set -g @continuum-restore 'on'
```

- [ ] **Step 4: tmux 통합 테스트 통과 확인**

Run:

```bash
nix build \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-prefix-is-ctrl-a \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-prefix-send-prefix \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-prefix-last-window \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-resurrect-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-continuum-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-has-vim-navigator-plugin \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-continuum-auto-restore \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-split-vertical \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-split-horizontal \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-default-split-bindings-unbound \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-vim-pane-navigation \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-set-titles \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-mosh-truecolor \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-osc52-clipboard \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-osc52-copy-bindings \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-no-pbcopy \
  .#checks.aarch64-darwin.integration-tmux-functionality-tmux-no-xclip \
  --no-link
```

Expected: 모든 `integration-tmux-functionality-*` check가 성공한다.

- [ ] **Step 5: 정적 검증 및 커밋**

Run:

```bash
git diff --check
nix fmt -- --fail-on-change users/shared/programs/tmux.nix tests/integration/tmux-functionality-test.nix
git add users/shared/programs/tmux.nix tests/integration/tmux-functionality-test.nix
git commit -m "feat(tmux): add session persistence plugins"
```

Expected: diff와 포맷 검사가 성공하고 구현 변경이 커밋된다.
