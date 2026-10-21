{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.herdr;
  worktreePackage = pkgs.worktree;

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
      herdrSimLink=$(${pkgs.herdr}/bin/herdr plugin list 2>/dev/null | grep -F 'baleen37.herdr-sim' || true)
      case "$herdrSimLink" in
        *"local:${herdrSimPackage}]"*) ;;
        *local:/nix/store/*) herdrSimRelink=1 ;;
        # A link outside the store is a dev checkout
        # (`herdr plugin link ~/dev/herdr-sim`): leave it to its developer.
        *local:*) ;;
        *) herdrSimRelink=1 ;;
      esac
      if [ -n "''${herdrSimRelink:-}" ]; then
        run ${pkgs.herdr}/bin/herdr plugin unlink baleen37.herdr-sim >/dev/null 2>&1 || true
        run ${pkgs.herdr}/bin/herdr plugin link ${herdrSimPackage} >/dev/null || true
        # Linking runs no startup hook; without this pass panes keep the old
        # version's tokens until their next turn ends.
        # Outside a pane there is no git or gh on PATH (needed for projects,
        # branches and PR states) and no HERDR_SOCKET_PATH (activity order).
        run env PATH="${pkgs.git}/bin:${pkgs.gh}/bin:$PATH" \
          HERDR_PLUGIN_EVENT=startup HERDR_BIN_PATH=${pkgs.herdr}/bin/herdr \
          HERDR_SOCKET_PATH="${config.xdg.configHome}/herdr/herdr.sock" \
          HERDR_PLUGIN_STATE_DIR="$HOME/.local/state/herdr/plugins/baleen37.herdr-sim" \
          ${herdrSimPackage}/bin/herdr-sim || true
      fi
    '';

    xdg.configFile."herdr/config.toml".text = ''
      onboarding = false

      [update]
      channel = "stable"
      version_check = false

      [experimental]
      allow_nested = true

      [ui]
      # Space order, so herdr-sim's tree headers sit over their sessions
      # when its activity order is off.
      agent_panel_sort = "spaces"
      sidebar_width = 38
      # A distinct symbol per agent state instead of coloured dots.
      status_indicators = "symbols"
      # prefix+c opens a tab at once, with a generated name.
      prompt_new_tab_name = false

      # Finished / needs-input popups through the macOS notification service.
      [ui.toast]
      delivery = "system"

      # Agents as herdr-radar draws them: a group per workspace (its
      # worktrees under it, the repo on a row of its own when its checkout
      # has no session), one row per session — the state mark and title in
      # the state's colour, no logo — and a blank row
      # after each group. A group whose sessions all went stale fades, a
      # stale session dims whole, idle titles cool with time (herdr-radar's
      # dark tiers); a working title spins, a question pulses.
      [ui.sidebar.agents]
      row_gap = 0
      rows = [
        [{ token = "$tree_group_parent", fg = "#8b8e9c", bold = true }],
        [{ token = "$tree_group", fg = "#a8abbd", bold = true }, { token = "$tree_group_stale", fg = "#8b8e9c", bold = true }],
        [{ token = "$label_working", fg = "#fab387", bold = true }, { token = "$label_blocked", fg = "#f38ba8", bold = true }, { token = "$label_done", fg = "#a6e3a1" }, { token = "$label_idle_fresh", fg = "#95bba2" }, { token = "$label_idle", fg = "#a99e92" }, { token = "$label_idle_stale", fg = "#8b8e9c" }, { token = "$label_unknown", fg = "#cba6f7" }, { token = "machine", fg = "#89b4fa", rules = [{ equals = "Local", hide = true }] }],
        [{ token = "$tree_gap" }],
      ]

      # The same rows for Claude, its working title in Claude's coral as
      # herdr-radar wears a vendor's colour; anything else stays peach.
      [ui.sidebar.agents.rows_by_agent]
      claude = [
        [{ token = "$tree_group_parent", fg = "#8b8e9c", bold = true }],
        [{ token = "$tree_group", fg = "#a8abbd", bold = true }, { token = "$tree_group_stale", fg = "#8b8e9c", bold = true }],
        [{ token = "$label_working", fg = "#d97757", bold = true }, { token = "$label_blocked", fg = "#f38ba8", bold = true }, { token = "$label_done", fg = "#a6e3a1" }, { token = "$label_idle_fresh", fg = "#95bba2" }, { token = "$label_idle", fg = "#a99e92" }, { token = "$label_idle_stale", fg = "#8b8e9c" }, { token = "$label_unknown", fg = "#cba6f7" }, { token = "machine", fg = "#89b4fa", rules = [{ equals = "Local", hide = true }] }],
        [{ token = "$tree_gap" }],
      ]

      # Spaces as herdr-radar draws them: the state's mark and the
      # workspace's name, coloured as in the Agents list (dimmed with no
      # agent), then the title and age of the session behind that state,
      # its CI and its PR.
      [ui.sidebar.spaces]
      row_gap = 0
      rows = [
        [{ token = "$header_working", fg = "#fab387", bold = true }, { token = "$header_blocked", fg = "#f38ba8", bold = true }, { token = "$header_done", fg = "#a6e3a1", bold = true }, { token = "$header_idle", fg = "#cdd6f4", bold = true }, { token = "$header_unknown", fg = "#cba6f7", bold = true }, { token = "$header_none", fg = "#6c7086" }],
        [{ token = "$space_title", fg = "#a8abbd" }, { token = "$space_age", dim = true }, { token = "$ci", rules = [{ starts_with = "\uF42E", fg = "#a6e3a1" }, { starts_with = "\uF467", fg = "#f38ba8" }, { starts_with = "\uF444", fg = "#f9e2af" }] }, { token = "$pr", rules = [{ starts_with = "\uF407", fg = "#a6e3a1" }, { starts_with = "\uF419", fg = "#cba6f7" }, { starts_with = "\uF4DC", hide = true }] }],
      ]

      [keys]
      # prefix+a moves focus to the next agent in the Agents list.
      next_agent = "prefix+a"
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

      # herdr-sim's Changes panel: the focused session's PRs, on the right.
      [[keys.command]]
      key = "cmd+shift+c"
      type = "plugin_action"
      command = "baleen37.herdr-sim.toggle-changes"
      description = "changes panel on/off"
    '';
  };
}
