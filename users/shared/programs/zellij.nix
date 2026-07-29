# Zellij Terminal Multiplexer Configuration
#
# Tmux-shaped Zellij setup: mirrors users/shared/programs/tmux.nix so muscle
# memory carries over between the two multiplexers.
#
# Zellij is modal rather than prefix-based, but it ships a "tmux" mode whose
# bindings already follow tmux. This module makes Ctrl-a the key that enters
# that mode, so `Ctrl-a <key>` behaves like a tmux prefix chord, and fills in
# the bindings this repo's tmux config adds on top of tmux's defaults.
#
# Terminology: a Zellij *tab* is the equivalent of a tmux *window*.
#
# Key Bindings (prefix = Ctrl+a):
#   - Prefix:             Ctrl+a (Ctrl+b also works, Zellij's own default)
#   - Send literal C-a:   Prefix+Ctrl+a
#   - Split panes:        Prefix+% (left/right), Prefix+" (top/bottom)
#   - Navigate panes:     Prefix+h/j/k/l or Alt+arrows
#   - Resize panes:       Prefix+H/J/K/L
#   - New tab:            Prefix+c
#   - Next/Prev tab:      Prefix+n/p, or Alt+l/Alt+h without prefix
#   - Select tab:         Prefix+1-9
#   - Last tab:           Prefix+a
#   - Rename tab:         Prefix+,
#   - Close pane:         Prefix+x
#   - Fullscreen:         Prefix+z
#   - Detach:             Prefix+d
#   - Session picker:     Prefix+T (the sesh key from tmux.nix)
#   - Scroll/copy mode:   Prefix+[
#
# Deliberate gaps vs tmux.nix, with no Zellij equivalent:
#   - Prefix+] (paste-buffer): Zellij has no paste action. Use the terminal's
#     own paste, or middle-click, which mouse_mode forwards.
#   - Prefix+r (source-file): Zellij reloads config.kdl on new sessions only.
#   - Copy mode v/y: Zellij has no keyboard text selection. Selection is by
#     mouse, and copy_on_select puts it on the clipboard immediately.
#
# Clipboard: copy_clipboard = "system" with no copy_command makes Zellij emit
# OSC52 itself, the same terminal-native path tmux.nix uses, so copying works
# over SSH without pbcopy/xclip.
#
# Shell integration stays off on purpose: home-manager's zellij shell
# integration auto-starts Zellij from every interactive shell, which would
# hijack shells started inside tmux. Start Zellij explicitly with `zellij`.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.zellij;

  # tmux.nix binds 0-9 to select-window; base-index 1 means 1-9 are the useful
  # ones and Zellij tabs are 1-indexed too. The separator carries the KDL
  # indentation for every line after the first, which the interpolation site
  # below supplies.
  tabBindings = lib.concatMapStringsSep "\n        " (
    n: ''bind "${toString n}" { GoToTab ${toString n}; SwitchToMode "Normal"; }''
  ) (lib.range 1 9);
in
{
  options.modules.programs.zellij.enable = lib.mkEnableOption "Zellij multiplexer configuration";

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;

      # See the note in the header: auto-start would fire inside tmux panes too.
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;

      settings = {
        # tmux.nix: set -g default-shell ${pkgs.zsh}/bin/zsh
        default_shell = "${pkgs.zsh}/bin/zsh";

        # The built-in "compact" layout is a single status line at the bottom of
        # the window, which is the closest thing to tmux's status bar. Zellij's
        # "default" layout instead stacks a tab bar on top and a status bar below.
        default_layout = "compact";

        # tmux.nix: set -g mouse on, plus middle-click paste.
        mouse_mode = true;

        # No keyboard selection in Zellij, so copy the mouse selection eagerly.
        copy_on_select = true;

        # No copy_command: Zellij then emits OSC52 to the outer terminal, the
        # same mechanism as tmux.nix's `set -s set-clipboard on`.
        copy_clipboard = "system";

        # tmux.nix: historyLimit = 50000
        scroll_buffer_size = 50000;

        # tmux.nix runs resurrect + continuum with @continuum-restore 'on'.
        # Zellij's built-in serialization is the equivalent; keeping the pane
        # viewport makes a resumed session show its scrollback like resurrect.
        session_serialization = true;
        serialize_pane_viewport = true;

        # tmux.nix: destroy-unattached off / remain-on-exit off — closing the
        # terminal leaves the session alive to reattach.
        on_force_close = "detach";

        # Pane frames stand in for tmux's pane borders.
        pane_frames = true;
        simplified_ui = false;

        # This config is version-controlled; the interactive nags add nothing.
        show_startup_tips = false;
        show_release_notes = false;
      };

      # Keybinds are written as raw KDL rather than through `settings`, whose
      # toKDL generator needs _props/_children/_args scaffolding that buries the
      # bindings. Omitting `clear-defaults=true` keeps Zellij's defaults, so the
      # blocks below only add to or override individual keys.
      extraConfig = ''
        keybinds {
            // Ctrl-a enters Zellij's tmux mode, making `Ctrl-a <key>` a tmux
            // prefix chord. Zellij's own Ctrl-b entry is left bound as an alias.
            shared_except "tmux" "locked" {
                bind "Ctrl a" { SwitchToMode "Tmux"; }
            }

            // tmux.nix binds Alt-h/Alt-l to previous-window/next-window without
            // a prefix. Zellij defaults these to MoveFocusOrTab; override to
            // match tmux. Alt-Left/Alt-Right keep the default pane-aware
            // behaviour, and Alt-j/Alt-k still move pane focus.
            shared_except "locked" {
                bind "Alt h" { GoToPreviousTab; }
                bind "Alt l" { GoToNextTab; }
            }

            tmux {
                // tmux.nix: bind C-a send-prefix. 1 is the byte Ctrl-a sends.
                bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }

                // Splits are left alone: Zellij's tmux mode already binds % to a
                // left/right split and the double-quote key to a top/bottom one,
                // matching tmux's own defaults.

                // tmux.nix: bind -r H/J/K/L resize-pane. Staying in tmux mode
                // instead of returning to Normal gives the repeatable -r feel.
                bind "H" { Resize "Increase Left"; }
                bind "J" { Resize "Increase Down"; }
                bind "K" { Resize "Increase Up"; }
                bind "L" { Resize "Increase Right"; }

                // tmux.nix: bind a last-window
                bind "a" { ToggleTab; SwitchToMode "Normal"; }

                // tmux.nix: prefix + 0-9 selects a window (base-index 1)
                ${tabBindings}

                // tmux.nix drives sesh from prefix+T; Zellij's session manager
                // is the equivalent picker.
                bind "T" {
                    LaunchOrFocusPlugin "session-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
            }
        }
      '';
    };
  };
}
