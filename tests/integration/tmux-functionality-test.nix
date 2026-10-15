# tests/integration/tmux-functionality-test.nix
#
# Loads the tmux.conf that Home Manager generates from users/shared/programs/tmux.nix
# into a live, isolated tmux server and asserts what the server reports
# (show-options, list-keys, display-message) rather than the text of the config.
# A line tmux rejects fails the test, and a setting is only seen if tmux applies it.
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
      inputs.direnv-instant.homeModules.direnv-instant
      ../../users/shared/programs/tmux.nix
      {
        modules.programs.tmux.enable = true;
        programs.direnv-instant.enable = true;
        # Home Manager's sesh module asserts this whenever its tmux key is set.
        programs.fzf.tmux.enableShellIntegration = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };
  hm = homeConfig.config;
  tmuxPackage = hm.programs.tmux.package;
  tmuxConf = hm.xdg.configFile."tmux/tmux.conf".source;

  agentStatusSummarySource = ../../users/shared/programs/tmux-agent-status-summary.sh;
  fakeAgentStatusTmux = pkgs.writeShellScriptBin "tmux" ''
    if [ "$1" = "list-panes" ]; then
      printf '%s\n' running ready running needs_input error unknown ""
      exit 0
    fi
    exit 1
  '';
  emptyAgentStatusTmux = pkgs.writeShellScriptBin "tmux" ''
    if [ "$1" = "list-panes" ]; then
      printf '%s\n' "" unknown ""
      exit 0
    fi
    exit 1
  '';
  failingAgentStatusTmux = pkgs.writeShellScriptBin "tmux" ''
    exit 1
  '';
in
{
  # ============================================================================
  # Package wiring — not visible to a running server
  # ============================================================================
  tmux-darwin-configure-flag = helpers.assertTest "tmux-darwin-configure-flag" (
    !pkgs.stdenv.hostPlatform.isDarwin || lib.elem "--disable-jemalloc" tmuxPackage.configureFlags
  ) "Darwin tmux should explicitly choose the non-jemalloc build";

  direnv-instant-tmux-package =
    helpers.assertTest "direnv-instant-tmux-package"
      (lib.elem tmuxPackage hm.programs.direnv-instant.package.nativeBuildInputs)
      "direnv-instant should check against tmux.nix's tmux package, not build a second tmux";

  # ============================================================================
  # Status-bar helper script, against fake tmux binaries for the failure modes
  # ============================================================================
  tmux-agent-status-summary = pkgs.runCommand "tmux-agent-status-summary" { } ''
    output="$(PATH=${fakeAgentStatusTmux}/bin ${pkgs.bash}/bin/bash ${agentStatusSummarySource})"
    test "$output" = '●2 ▲1 ○1 ✕1'

    output="$(PATH=${emptyAgentStatusTmux}/bin ${pkgs.bash}/bin/bash ${agentStatusSummarySource})"
    test -z "$output"

    output="$(PATH=${failingAgentStatusTmux}/bin ${pkgs.bash}/bin/bash ${agentStatusSummarySource})"
    test -z "$output"

    output="$(PATH=${pkgs.coreutils}/bin ${pkgs.bash}/bin/bash ${agentStatusSummarySource})"
    test -z "$output"

    touch "$out"
  '';

  # ============================================================================
  # The generated tmux.conf, loaded into a live server
  # ============================================================================
  tmux-live-config =
    pkgs.runCommand "tmux-live-config"
      {
        nativeBuildInputs = [
          tmuxPackage
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
        ];
      }
      ''
        export HOME="$TMPDIR"
        export LC_ALL=${if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8"}
        export TMUX_TMPDIR="$TMPDIR"
        unset TMUX

        t() { tmux -u -L tmux-live-config "$@"; }
        fail() { echo "FAIL: $*" >&2; exit 1; }
        expect_eq() { # name actual expected
          [ "$2" = "$3" ] || fail "$1: expected [$3], got [$2]"
        }
        expect_has() { # name haystack needle
          case "$2" in *"$3"*) ;; *) fail "$1: [$2] does not contain [$3]" ;; esac
        }
        # table key -> the command bound to it, or "" when unbound. The key is
        # spelled as list-keys prints it (e.g. '\"'). `list-keys -T table key`
        # prints nothing on tmux 3.7, hence filtering the whole table.
        key() {
          t list-keys -T "$1" | K="$2" awk '
            { i = ($2 == "-r") ? 5 : 4 }
            $i == ENVIRON["K"] {
              sub(/^bind-key +(-r +)?-T +[^ ]+ +[^ ]+ +/, ""); print; exit
            }'
        }
        trap 't kill-server 2>/dev/null || true' EXIT

        # The plugin scripts start with `#!/usr/bin/env bash`, which the Linux
        # build sandbox does not have, so they run from shebang-patched copies.
        # Only the plugin paths in the config change.
        conf="$TMPDIR/tmux.conf"
        cp ${tmuxConf} "$conf"
        chmod u+w "$conf"
        mkdir "$TMPDIR/plugins"
        for plugin in $(grep -oE '${builtins.storeDir}/[^/ ]+-tmuxplugin-[^/ ]+' "$conf" | sort -u); do
          copy="$TMPDIR/plugins/$(basename "$plugin")"
          cp -r "$plugin" "$copy"
          chmod -R u+w "$copy"
          patchShebangs "$copy" > /dev/null
          sed -i "s|$plugin|$copy|g" "$conf"
        done

        # `tmux -f` defers config errors to the first attached client and still
        # exits 0, so start bare and source the config: source-file exits
        # non-zero and prints the offending line when tmux rejects anything.
        t -f /dev/null new-session -d -s live '${pkgs.coreutils}/bin/sleep 300'
        if ! errors="$(t source-file "$conf" 2>&1)" || [ -n "$errors" ]; then
          fail "tmux rejected the generated config: $errors"
        fi

        opt() { t show-options -gv "$1"; }
        expect_eq prefix "$(opt prefix)" C-a
        expect_eq set-titles "$(opt set-titles)" on
        expect_eq allow-passthrough "$(opt allow-passthrough)" off
        expect_eq set-clipboard "$(t show-options -sv set-clipboard)" on
        expect_eq mode-keys "$(t show-window-options -gv mode-keys)" vi

        features="$(t show-options -sv terminal-features)"
        expect_has ghostty-truecolor "$features" 'xterm-ghostty:RGB'
        expect_has mosh-truecolor "$features" 'xterm-256color:RGB'

        # Prefix table: our bindings, plus the defaults tmux.nix keeps.
        expect_eq send-prefix "$(key prefix C-a)" send-prefix
        expect_eq last-window "$(key prefix a)" last-window
        expect_eq split-left-right "$(key prefix '\%')" 'split-window -h -c "#{pane_current_path}"'
        expect_eq split-top-bottom "$(key prefix '\"')" 'split-window -v -c "#{pane_current_path}"'
        expect_eq pane-left "$(key prefix h)" 'select-pane -L'
        expect_eq pane-down "$(key prefix j)" 'select-pane -D'
        expect_eq pane-up "$(key prefix k)" 'select-pane -U'
        expect_eq pane-right "$(key prefix l)" 'select-pane -R'
        expect_has sesh-on-T "$(key prefix T)" sesh
        expect_eq clock-mode-kept "$(key prefix t)" clock-mode

        # Copy mode yanks through tmux's own OSC52, never an external clipboard tool.
        expect_eq copy-y "$(key copy-mode-vi y)" 'send-keys -X copy-pipe-and-cancel'
        expect_eq copy-enter "$(key copy-mode-vi Enter)" 'send-keys -X copy-pipe-and-cancel'
        expect_eq copy-command "$(opt copy-command)" ""
        all_keys="$(t list-keys)"
        for tool in pbcopy xclip xsel wl-copy; do
          case "$all_keys" in *"$tool"*) fail "a binding shells out to $tool instead of OSC52" ;; esac
        done

        # Plugins actually loaded: each one leaves something only it would set.
        expect_has resurrect-save "$(key prefix C-s)" resurrect
        expect_has vim-tmux-navigator "$(key root C-h)" 'select-pane -L'
        expect_eq continuum-restore "$(opt @continuum-restore)" on
        # continuum appends its autosave hook to status-right when it loads, so
        # this only holds if status-right was set before continuum ran.
        status_right="$(opt status-right)"
        expect_has continuum-autosave "$status_right" continuum_save
        expect_has agent-summary "$status_right" tmux-agent-status-summary

        # The status-right helper, run as configured, against this server.
        # A session created after the config, so base-index 1 applies to it.
        t new-session -d -s agents '${pkgs.coreutils}/bin/sleep 300'
        pane="$(t display-message -p -t agents '#{pane_id}')"
        export TMUX="$(t display-message -p '#{socket_path}'),$(t display-message -p '#{pid}'),0"
        summary_cmd="$(printf '%s\n' "$status_right" | grep -oE '#\([^)]*tmux-agent-status-summary\)' | sed -E 's/^#\(//; s/\)$//')"
        [ -n "$summary_cmd" ] || fail "status-right has no #(…tmux-agent-status-summary) job"
        expect_eq summary-empty "$($summary_cmd)" ""
        t set-option -p -t "$pane" @agent_status needs_input
        expect_eq summary-needs-input "$($summary_cmd)" '▲1'

        # Window list: the agent glyph sits right after the index, and the pane
        # title replaces the window name once a program sets one.
        win() { t display-message -p -t "$pane" "#{E:$1}"; }
        for fmt in window-status-format window-status-current-format; do
          for mapping in running:● needs_input:▲ ready:○ error:✕ unknown:; do
            t set-option -p -t "$pane" @agent_status "''${mapping%%:*}"
            expect_has "$fmt-''${mapping%%:*}" "$(win "$fmt")" " 1''${mapping#*:}#["
          done
          t set-option -pu -t "$pane" @agent_status
          expect_has "$fmt-unset" "$(win "$fmt")" ' 1#['

          t select-pane -t "$pane" -T agent-title
          expect_has "$fmt-pane-title" "$(win "$fmt")" ']agent-title#['
          t select-pane -t "$pane" -T "$(t display-message -p '#{host}')"
          expect_has "$fmt-window-name-fallback" "$(win "$fmt")" "]$(t display-message -p -t "$pane" '#W')#["
        done

        touch "$out"
      '';
}
