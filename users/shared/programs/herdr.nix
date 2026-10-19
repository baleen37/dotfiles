{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.herdr;
  worktreePackage = inputs.worktree.packages.${pkgs.system}.default;

  # Herdr's built-in New worktree action puts checkouts under
  # ~/.herdr/worktrees/<repo>/<slug>, which wt does not use, so the key runs wt
  # instead and every worktree lands in <repo>/.worktrees/<slug>.
  #
  # Custom commands receive HERDR_ACTIVE_* rather than the HERDR_ENV /
  # HERDR_WORKSPACE_ID pair panes get, and wt gates its Herdr integration on the
  # latter. Without the bridge below wt still creates the checkout in the right
  # place, but falls back to plain git and the worktree never joins its parent
  # workspace group.
  #
  # config.toml cannot reference a store path, so the script is deployed to a
  # fixed path under the Herdr config directory instead of pkgs.writeShellScript.
  newWorktreePath = "${config.xdg.configHome}/herdr/new-worktree.sh";

  # herdr-sim sets $pr_open / $pr_merged / $pr_closed on each Claude or Codex
  # pane from the PRs its session touched; the sidebar rows below render them
  # as coloured icons. Its package output is the plugin root.
  herdrSimPackage = inputs.herdr-sim.packages.${pkgs.system}.default;
in
{
  options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr terminal workspace manager" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/new-worktree.sh" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        # Invoked by Herdr's prefix+shift+g popup. See herdr.nix.
        cd "''${HERDR_ACTIVE_PANE_CWD:-$PWD}" || exit 1

        export HERDR_ENV=1
        export HERDR_WORKSPACE_ID="''${HERDR_ACTIVE_WORKSPACE_ID:-}"

        # A failed read means EOF or Ctrl+C: cancel instead of creating a
        # randomly named branch nobody asked for.
        printf 'branch (empty = random): '
        read -r name || exit 0

        # The binary, not the zsh wrapper: in Herdr, wt opens the new workspace
        # itself, so there is no calling shell to cd. An empty name lets wt pick
        # a random one.
        exec ${worktreePackage}/bin/wt switch -c ''${name:+"$name"}
      '';
    };

    # Herdr records a linked plugin by its resolved path, so a new store path
    # after an update needs relinking; an unchanged one is left alone.
    home.activation.herdrLinkHerdrSim = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if ! ${pkgs.herdr}/bin/herdr plugin list 2>/dev/null | grep -qF 'local:${herdrSimPackage}]'; then
        run ${pkgs.herdr}/bin/herdr plugin unlink baleen37.herdr-sim >/dev/null 2>&1 || true
        run ${pkgs.herdr}/bin/herdr plugin link ${herdrSimPackage} >/dev/null || true
      fi
    '';

    xdg.configFile."herdr/config.toml".text = ''
      onboarding = false

      [update]
      channel = "stable"
      version_check = false

      [experimental]
      allow_nested = true

      # Agents that need you first: blocked, then done (kept until viewed),
      # then working. Each agent is its logo and session title, then its
      # project (the repository, not the herdr workspace name), machine
      # (remote only) and PR icon.
      [ui]
      agent_panel_sort = "priority"
      sidebar_width = 38

      [ui.sidebar.agents]
      row_gap = 0
      rows = [
        # Like a line in Claude Code's session list: logo and title in one
        # herdr-sim token, since herdr puts " · " between tokens.
        ["state_icon", "$heading"],
        [{ token = "$project", dim = true }, { token = "machine", fg = "#89b4fa", rules = [{ equals = "Local", hide = true }] }, { token = "$pr", rules = [{ starts_with = "\uF407", fg = "#a6e3a1" }, { starts_with = "\uF419", fg = "#cba6f7" }, { starts_with = "\uF4DC", dim = true }] }],
      ]

      # A Space is its project and the logos of the agents running there, then
      # a branch row: its branch and the PR herdr-sim found for it. $pr is one
      # icon for the state that most needs attention plus the total count when
      # there are several, like Claude Code; colour it by that icon.
      [ui.sidebar.spaces]
      rows = [
        ["state_icon", { token = "$project", bold = true }, { token = "$agent_claude", fg = "#d97757" }, { token = "$agent_codex", fg = "#cdd6f4" }],
        ["branch", "git_status", { token = "$pr", rules = [{ starts_with = "\uF407", fg = "#a6e3a1" }, { starts_with = "\uF419", fg = "#cba6f7" }, { starts_with = "\uF4DC", dim = true }] }],
      ]

      [keys]
      prefix = "ctrl+a"
      detach = "prefix+d"
      split_vertical = "prefix+|"
      split_horizontal = "prefix+minus"
      new_worktree = ""

      [[keys.command]]
      key = "prefix+shift+g"
      type = "popup"
      command = "${newWorktreePath}"
      description = "new worktree (wt)"
      width = "80%"
      height = "60%"

      [[keys.command]]
      key = "cmd+r"
      type = "plugin_action"
      command = "persiyanov.reviewr.toggle"
    '';
  };
}
