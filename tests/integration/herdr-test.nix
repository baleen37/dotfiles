{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/herdr.nix
      {
        modules.programs.herdr.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  inherit (homeConfig) config;
  herdrConfig = config.xdg.configFile."herdr/config.toml".text;
  parsedConfig = builtins.fromTOML herdrConfig;
  herdrConfigFile = pkgs.writeText "herdr-config.toml" herdrConfig;

  worktreeCommand = builtins.head parsedConfig.keys.command;
  newWorktreeScript = config.xdg.configFile."herdr/new-worktree.sh".text;
in
{
  herdr-package-installed =
    helpers.assertTest "herdr-package-installed" (builtins.elem pkgs.herdr config.home.packages)
      "Herdr should be installed through Home Manager";

  herdr-config-contains-tmux-bindings = helpers.assertTest "herdr-config-contains-tmux-bindings" (
    parsedConfig.keys.prefix == "ctrl+a"
    && parsedConfig.keys.detach == "prefix+d"
    && parsedConfig.keys.split_vertical == "prefix+|"
    && parsedConfig.keys.split_horizontal == "prefix+minus"
  ) "Herdr should use the selected tmux-compatible bindings";

  herdr-unbinds-builtin-new-worktree = helpers.assertTest "herdr-unbinds-builtin-new-worktree" (
    parsedConfig.keys.new_worktree == ""
  ) "Herdr's built-in New worktree writes to ~/.herdr/worktrees, so the key belongs to wt";

  herdr-binds-worktree-key-to-wt = helpers.assertTest "herdr-binds-worktree-key-to-wt" (
    worktreeCommand.key == "prefix+shift+g"
    # shell type runs detached and could not prompt for a branch name.
    && worktreeCommand.type == "popup"
  ) "prefix+shift+g should open a popup instead of Herdr's built-in worktree dialog";

  # The bridge is the part that breaks quietly. Custom commands receive
  # HERDR_ACTIVE_*, but wt gates its Herdr integration on HERDR_ENV plus
  # HERDR_WORKSPACE_ID. Drop the bridge and wt still creates the checkout in the
  # right place, only it falls back to plain git and the worktree never joins
  # its parent workspace group -- invisible unless you look at the sidebar.
  herdr-worktree-command-bridges-workspace-env =
    helpers.assertTest "herdr-worktree-command-bridges-workspace-env"
      (
        lib.hasInfix "HERDR_ENV=1" newWorktreeScript
        && lib.hasInfix "HERDR_WORKSPACE_ID=\"\${HERDR_ACTIVE_WORKSPACE_ID" newWorktreeScript
        # wt is a zsh function; Herdr runs commands through /bin/sh.
        && lib.hasInfix "zsh -ic" newWorktreeScript
      )
      "the popup script must bridge HERDR_ACTIVE_WORKSPACE_ID before calling wt";

  # The branch name is attacker-adjacent only in the sense that a stray ';' or
  # '$(...)' in a typed name would be re-parsed by zsh. Passing it positionally
  # is what keeps 'a;echo x' one branch name instead of two commands.
  herdr-worktree-command-passes-branch-positionally =
    helpers.assertTest "herdr-worktree-command-passes-branch-positionally"
      (
        lib.hasInfix "zsh -ic 'wt \"$1\"' wt" newWorktreeScript
        && !(lib.hasInfix "\"wt \${name" newWorktreeScript)
      )
      "the branch name must reach wt as a positional argument, not interpolated into the command string";

  # A dangling command path would fail only at keypress time, in a popup that
  # closes immediately.
  herdr-worktree-command-points-at-deployed-script =
    helpers.assertTest "herdr-worktree-command-points-at-deployed-script"
      (worktreeCommand.command == "${config.xdg.configHome}/herdr/new-worktree.sh")
      "prefix+shift+g must point at the script this module deploys";

  herdr-config-does-not-set-worktree-root =
    helpers.assertTest "herdr-config-does-not-set-worktree-root" (!(parsedConfig ? worktrees))
      "Herdr config should not maintain a global worktree root";

  herdr-config-valid = pkgs.runCommand "herdr-config-valid" { } ''
    export HOME="$TMPDIR"
    export HERDR_CONFIG_PATH=${herdrConfigFile}
    ${pkgs.herdr}/bin/herdr config check
    touch "$out"
  '';
}
