# Zellij Terminal Multiplexer Configuration
#
# tmux.nix parity: same prefix key, same split keys.
#
# Key Bindings:
#   - Prefix: Ctrl+a (zellij's built-in "tmux" mode, rebound from Ctrl+b)
#   - Split panes: Prefix+| (left/right), Prefix+- (top/bottom)
#   - Navigate panes: Prefix+h/j/k/l
#   - New tab (~window): Prefix+c
#   - Next/Prev tab: Prefix+n/p
#   - Rename tab: Prefix+,
#   - Detach: Prefix+d

{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.zellij;
in
{
  options.modules.programs.zellij.enable = lib.mkEnableOption "Zellij multiplexer configuration";

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = false;

      extraConfig = ''
        keybinds {
          normal {
            bind "Ctrl a" { SwitchToMode "Tmux"; }
          }
          tmux {
            unbind "Ctrl b"
            bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
            unbind "%"
            unbind "\""
            bind "|" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
          }
        }
      '';
    };
  };
}
