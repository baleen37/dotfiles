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
    extraSpecialArgs = { inherit inputs; };
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
      )
      "the popup script must bridge HERDR_ACTIVE_WORKSPACE_ID before calling wt";

  # The popup used to run `wt <name>` through zsh -ic. After wt became a Rust
  # binary that form was rejected as an unknown subcommand, and the popup just
  # flashed an error. wt-hook-consistency-test runs `wt switch -c` itself, so a
  # wt CLI change fails there.
  herdr-worktree-command-calls-wt-switch-create =
    helpers.assertTest "herdr-worktree-command-calls-wt-switch-create"
      (lib.hasInfix "/bin/wt switch -c" newWorktreeScript)
      "the popup must create the worktree with the wt binary's `switch -c`";

  # A dangling command path would fail only at keypress time, in a popup that
  # closes immediately.
  herdr-worktree-command-points-at-deployed-script =
    helpers.assertTest "herdr-worktree-command-points-at-deployed-script"
      (worktreeCommand.command == "${config.xdg.configHome}/herdr/new-worktree.sh")
      "prefix+shift+g must point at the script this module deploys";

  herdr-config-does-not-set-worktree-root =
    helpers.assertTest "herdr-config-does-not-set-worktree-root" (!(parsedConfig ? worktrees))
      "Herdr config should not maintain a global worktree root";

  # The sidebar rows read tokens herdr-sim writes. If the plugin renames one,
  # its row silently renders nothing.
  herdr-sidebar-uses-herdr-sim-tokens =
    let
      rowTokens = map (t: if builtins.isAttrs t then t.token else t) (
        lib.flatten (parsedConfig.ui.sidebar.agents.rows ++ parsedConfig.ui.sidebar.spaces.rows)
      );
      pluginSource = builtins.readFile "${inputs.herdr-sim}/src/lib.rs";
    in
    helpers.assertTest "herdr-sidebar-uses-herdr-sim-tokens" (lib.all
      (name: builtins.elem ("$" + name) rowTokens && lib.hasInfix "\"${name}\"" pluginSource)
      [
        "pr_open"
        "pr_merged"
        "pr_closed"
      ]
    ) "sidebar rows must reference the pr_* tokens herdr-sim reports";

  herdr-config-valid = pkgs.runCommand "herdr-config-valid" { } ''
    export HOME="$TMPDIR"
    export HERDR_CONFIG_PATH=${herdrConfigFile}
    ${pkgs.herdr}/bin/herdr config check
    touch "$out"
  '';
}
