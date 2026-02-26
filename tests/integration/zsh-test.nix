# Zsh Configuration Integration Test
#
# Tests the Zsh shell configuration in users/shared/zsh.nix
# Verifies shell enablement, key aliases, fzf integration, history settings,
# prompt configuration, direnv integration, and shell functions.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  ...
} @ args:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Platform detection
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Import zsh configuration
  zshConfig = import ../../users/shared/zsh {
    inherit pkgs lib isDarwin;
    config = {
      home = {
        homeDirectory = "/home/testuser";
      };
    };
  };

  # Extract zsh settings
  zshSettings = zshConfig.programs.zsh;
  shellAliases = zshSettings.shellAliases or { };
  initContent = zshSettings.initContent.content or "";

  # Extract fzf and direnv settings
  fzfSettings = zshConfig.programs.fzf or { };
  direnvSettings = zshConfig.programs.direnv or { };

  # Helper to check if an alias exists
  hasAlias = aliasName: builtins.hasAttr aliasName shellAliases;

  # Helper to check if alias has expected value
  aliasValueMatches = aliasName: expectedValue:
    (builtins.getAttr aliasName shellAliases) == expectedValue;

  # Helper to check if initContent contains a pattern
  initContentHas = pattern: lib.hasInfix pattern initContent;

  # Helper to check if initContent contains multiple patterns
  initContentHasAll = patterns: builtins.all (pattern: initContentHas pattern) patterns;

in
{
  platforms = ["any"];
  value = helpers.testSuite "zsh-configuration" [
    # Basic zsh configuration
  (helpers.assertTest "zsh-enabled" zshSettings.enable "zsh should be enabled")
  (helpers.assertTest "zsh-autocd-disabled" (!zshSettings.autocd) "zsh autocd should be disabled")
  (helpers.assertTest "zsh-dotDir-home-directory" (
    (zshSettings.dotDir or null) == "/home/testuser"
  ) "zsh dotDir should be set to home directory")
  (helpers.assertTest "zsh-completion-enabled" zshSettings.enableCompletion "zsh completion should be enabled")
  (helpers.assertTest "zsh-fast-completion" (zshSettings.completionInit == "autoload -Uz compinit && compinit -C")
    "zsh should use fast completion (compinit -C)")

  # Claude CLI functions (cc, cco, ccz, cck)
  (helpers.assertTest "function-cc-exists" (initContentHas "cc()")
    "cc() function should exist")
  (helpers.assertTest "function-cco-exists" (initContentHas "cco()")
    "cco() function should exist")
  (helpers.assertTest "function-ccz-exists" (initContentHas "ccz()")
    "ccz() function should exist")
  (helpers.assertTest "function-cck-exists" (initContentHas "cck()")
    "cck() function should exist")
  (helpers.assertTest "function-cc-parse-model-flags" (initContentHas "_cc_parse_model_flags()")
    "_cc_parse_model_flags() helper function should exist")
  (helpers.assertTest "function-ccz-zai-api" (initContentHas "api.z.ai/api/anthropic")
    "ccz() function should use Z.ai API")

  (helpers.assertTest "alias-oc-exists" (hasAlias "oc") "alias 'oc' should exist")
  (helpers.assertTest "alias-oc-value" (
    aliasValueMatches "oc" "opencode"
  ) "alias 'oc' should point to opencode")

  # Git aliases
  (helpers.assertTest "alias-ga-exists" (hasAlias "ga") "alias 'ga' (git add) should exist")
  (helpers.assertTest "alias-gc-exists" (hasAlias "gc") "alias 'gc' (git commit) should exist")
  (helpers.assertTest "alias-gco-exists" (hasAlias "gco") "alias 'gco' (git checkout) should exist")
  (helpers.assertTest "alias-gcp-exists" (hasAlias "gcp") "alias 'gcp' (git cherry-pick) should exist")
  (helpers.assertTest "alias-gdiff-exists" (hasAlias "gdiff") "alias 'gdiff' (git diff) should exist")
  (helpers.assertTest "alias-gp-exists" (hasAlias "gp") "alias 'gp' (git push) should exist")
  (helpers.assertTest "alias-gs-exists" (hasAlias "gs") "alias 'gs' (git status) should exist")
  (helpers.assertTest "alias-gt-exists" (hasAlias "gt") "alias 'gt' (git tag) should exist")
  (helpers.assertTest "alias-gl-exists" (hasAlias "gl") "alias 'gl' (git prettylog) should exist")

  # Multi-level directory navigation aliases
  (helpers.assertTest "alias-dot-dot-dot-exists" (hasAlias "...") "alias '...' (cd ../..) should exist")
  (helpers.assertTest "alias-four-dots-exists" (hasAlias "....") "alias '....' (cd ../../..) should exist")
  (helpers.assertTest "alias-five-dots-exists" (hasAlias ".....") "alias '.....' (cd ../../../..) should exist")
  (helpers.assertTest "alias-six-dots-exists" (hasAlias "......") "alias '......' (cd ../../../../..) should exist")

  # ls color alias
  (helpers.assertTest "alias-ls-color" (hasAlias "ls")
    "alias 'ls' should exist with --color=auto")

  # Utility aliases
  (helpers.assertTest "alias-la-exists" (hasAlias "la") "alias 'la' (ls -la) should exist")
  (helpers.assertTest "alias-diff-difftastic" (
    aliasValueMatches "diff" "difft"
  ) "alias 'diff' should use difftastic")

  # Fzf integration
  (helpers.assertTest "fzf-enabled" fzfSettings.enable "fzf should be enabled")
  (helpers.assertTest "fzf-zsh-integration" fzfSettings.enableZshIntegration
    "fzf zsh integration should be enabled")

  # Fzf default options
  (helpers.assertTest "fzf-height-option" (
    lib.any (opt: lib.hasInfix "--height 40%" opt) (fzfSettings.defaultOptions or [])
  ) "fzf should have height option set to 40%")

  (helpers.assertTest "fzf-layout-reverse" (
    lib.any (opt: lib.hasInfix "--layout=reverse" opt) (fzfSettings.defaultOptions or [])
  ) "fzf should use reverse layout")

  (helpers.assertTest "fzf-preview-bat" (
    lib.any (opt: lib.hasInfix "bat" opt) (fzfSettings.defaultOptions or [])
  ) "fzf should use bat for preview")

  # Fzf file widget
  (helpers.assertTest "fzf-file-widget-fd" (
    lib.hasInfix "fd --type f" (fzfSettings.fileWidgetCommand or "")
  ) "fzf file widget should use fd")

  # Fzf directory widget
  (helpers.assertTest "fzf-cd-widget-fd" (
    lib.hasInfix "fd --type d" (fzfSettings.changeDirWidgetCommand or "")
  ) "fzf cd widget should use fd for directories")

  # Direnv integration
  (helpers.assertTest "direnv-enabled" direnvSettings.enable "direnv should be enabled")
  (helpers.assertTest "direnv-zsh-integration" direnvSettings.enableZshIntegration
    "direnv zsh integration should be enabled")
  (helpers.assertTest "direnv-nix-integration" direnvSettings.nix-direnv.enable
    "direnv nix-direnv should be enabled")

  # Direnv auto-allow configuration
  (helpers.assertTest "direnv-config-exists" (
    builtins.hasAttr "direnv/direnv.toml" (zshConfig.xdg.configFile or {})
  ) "direnv config file should be configured")
  (helpers.assertTest "direnv-whitelist-home" (
    lib.hasInfix "whitelist" (zshConfig.xdg.configFile."direnv/direnv.toml".text or "")
  ) "direnv should whitelist home directory")

  # History configuration in initContent
  (helpers.assertTest "history-ignore-set" (initContentHas "HISTIGNORE")
    "HISTIGNORE should be set in initContent")

  (helpers.assertTest "history-ignore-pwd-ls-cd" (
    initContentHas "pwd:ls:cd"
  ) "HISTIGNORE should include pwd, ls, cd")

  # Locale settings
  (helpers.assertTest "locale-utf8" (initContentHasAll [
    "LANG=\"en_US.UTF-8\""
    "LC_ALL=\"en_US.UTF-8\""
  ]) "Locale should be set to en_US.UTF-8")

  # Editor configuration
  (helpers.assertTest "editor-vim" (initContentHasAll [
    "EDITOR=\"vim\""
    "VISUAL=\"vim\""
  ]) "Editor should be set to vim")

  # PATH configuration
  (helpers.assertTest "path-npm-global" (initContentHas "npm-global")
    "PATH should include npm-global directory")
  (helpers.assertTest "path-pnpm-packages" (initContentHas "pnpm-packages")
    "PATH should include pnpm-packages directory")
  (helpers.assertTest "path-cargo-bin" (initContentHas "cargo/bin")
    "PATH should include cargo/bin directory")
  (helpers.assertTest "path-go-bin" (initContentHas "go/bin")
    "PATH should include go/bin directory")

  # GEM_HOME PATH handling (conditional)
  (helpers.assertTest "path-gem-home-conditional" (initContentHas "GEM_HOME")
    "PATH should include GEM_HOME/bin when GEM_HOME is set")

  # Nix daemon initialization
  (helpers.assertTest "nix-daemon-init" (initContentHas "nix-daemon.sh")
    "Nix daemon should be initialized in initContent")

  # 1Password SSH agent setup
  (helpers.assertTest "onepassword-agent-function" (initContentHas "_setup_1password_agent")
    "_setup_1password_agent function should be defined")
  (helpers.assertTest "onepassword-ssh-auth-sock" (initContentHas "SSH_AUTH_SOCK")
    "SSH_AUTH_SOCK should be configured for 1Password")

  # Shell functions
  (helpers.assertTest "function-shell-exists" (initContentHas "shell()")
    "shell() function for nix-shell should exist")
  (helpers.assertTest "function-ssh-wrapper" (initContentHas "ssh()")
    "ssh() wrapper function should exist")
  (helpers.assertTest "function-idea-exists" (initContentHas "idea()")
    "idea() function for IntelliJ launcher should exist")

  # Git Worktree function (gw)
  (helpers.assertTest "function-gw-exists" (initContentHas "gw()")
    "gw() function should exist")
  (helpers.assertTest "function-gw-usage" (initContentHas "Usage: gw <branch-name>")
    "gw() should have usage message")
  (helpers.assertTest "function-gw-git-check" (initContentHas "git rev-parse --git-dir")
    "gw() should check for git repository")
  (helpers.assertTest "function-gw-cd" (initContentHas "cd \"$worktree_dir\"")
    "gw() should change to worktree dir")
  (helpers.assertTest "function-gw-repo-root" (initContentHas "git worktree list | head -1")
    "gw() should resolve worktree path from main repo root")

  # SSH wrapper with autossh
  (helpers.assertTest "ssh-wrapper-autossh" (initContentHas "autossh")
    "ssh wrapper should use autossh if available")
  (helpers.assertTest "ssh-wrapper-keepalive" (initContentHas "ServerAliveInterval")
    "ssh wrapper should set keepalive options")

  # macOS-specific Homebrew PATH (only test on Darwin)
  (helpers.assertTest "homebrew-path-macos" (
    !pkgs.stdenv.hostPlatform.isDarwin ||  # Skip on Linux, or check on Darwin
    lib.any (line: lib.hasInfix "/opt/homebrew" line) (lib.splitString "\n" initContent)
  ) "Homebrew PATH should be configured for macOS")

  # Zsh plugins (should be empty list)
  (helpers.assertTest "zsh-plugins-empty" (
    builtins.length (zshSettings.plugins or []) == 0
  ) "zsh plugins list should be empty (custom functions used instead)")

  # npm configuration
  (helpers.assertTest "npm-config-prefix" (initContentHas "NPM_CONFIG_PREFIX")
    "NPM_CONFIG_PREFIX should be set for global npm packages")

  # GitHub token configuration
  (helpers.assertTest "github-token-export" (initContentHas "GITHUB_TOKEN")
    "GITHUB_TOKEN should be exported via gh auth token")

  # 1Password SSH agent platform-specific detection tests (Darwin-only)
  (helpers.assertTest "onepassword-group-containers" (
    if isDarwin then
      (initContentHas "Group Containers")
    else
      true # Skip on non-Darwin platforms
  ) "_setup_1password_agent should check Group Containers on macOS")

  (helpers.assertTest "onepassword-fallback-locations" (
    if isDarwin then
      (initContentHas ".1password/agent.sock")
    else
      true # Skip on non-Darwin platforms
  ) "_setup_1password_agent should check fallback socket locations")

  # ssh wrapper edge cases
  (helpers.assertTest "ssh-wrapper-autossh-poll" (initContentHas "AUTOSSH_POLL")
    "ssh wrapper should set AUTOSSH_POLL for autossh")

  (helpers.assertTest "ssh-wrapper-first-poll" (initContentHas "AUTOSSH_FIRST_POLL")
    "ssh wrapper should set AUTOSSH_FIRST_POLL for autossh")

  (helpers.assertTest "ssh-wrapper-tcp-keepalive" (initContentHas "TCPKeepAlive")
    "ssh wrapper should enable TCP keepalive")

  # IntelliJ IDEA launcher environment preservation
  (helpers.assertTest "idea-nohup-background" (initContentHas "nohup env")
    "idea() should use nohup for background execution")

  (helpers.assertTest "idea-disown" (initContentHas "disown")
    "idea() should disown the background process")

  # SSH agent setup for GUI applications (macOS)
  (helpers.assertTest "ssh-agent-gui-function" (
    !pkgs.stdenv.hostPlatform.isDarwin ||  # Skip on Linux, or check on Darwin
    initContentHas "setup_ssh_agent_for_gui"
  ) "setup_ssh_agent_for_gui() function should exist")
  (helpers.assertTest "ssh-agent-launchctl" (
    !pkgs.stdenv.hostPlatform.isDarwin ||  # Skip on Linux, or check on Darwin
    initContentHas "launchctl setenv"
  ) "SSH agent should be configured for GUI apps via launchctl")

  # IntelliJ IDEA launcher environment
  (helpers.assertTest "idea-env-ssh-agent" (initContentHas "SSH_AUTH_SOCK=\"$SSH_AUTH_SOCK\"")
    "idea() should preserve SSH_AUTH_SOCK environment variable")
  (helpers.assertTest "idea-env-git-ssh" (initContentHas "GIT_SSH_COMMAND")
    "idea() should preserve GIT_SSH_COMMAND environment variable")
  ];
}
