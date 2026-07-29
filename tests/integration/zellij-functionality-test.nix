# tests/integration/zellij-functionality-test.nix
# Zellij configuration integration tests.
#
# The module in users/shared/programs/zellij.nix exists to give Zellij the same
# feel as users/shared/programs/tmux.nix, so these tests do two things:
#   1. Assert the generated zellij/config.kdl carries the tmux-shaped bindings.
#   2. Assert the settings that mirror a tmux option stay in step with tmux.nix
#      (prefix key, scrollback size) instead of drifting apart silently.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  mockConfig = {
    modules.programs.zellij.enable = true;
    modules.programs.tmux.enable = true;
    home = {
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
    };
  };

  # (lib.mkIf true {...}).content unwraps the conditional when enable = true.
  zellijModule = import ../../users/shared/programs/zellij.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  zellijConfig = zellijModule.config.content.programs.zellij;

  tmuxModule = import ../../users/shared/programs/tmux.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  tmuxConfig = tmuxModule.config.content.programs.tmux;

  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/zellij.nix
      {
        modules.programs.zellij.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };
  generatedConfig = homeConfig.config.xdg.configFile."zellij/config.kdl".text;

  assertGenerated =
    name: needle:
    helpers.assertTest "zellij-${name}" (lib.hasInfix needle generatedConfig)
      "Generated zellij/config.kdl should contain: ${needle}";

  countOccurrences = needle: haystack: (builtins.length (lib.splitString needle haystack)) - 1;

  # Kept out of the assertion list so no line runs past the formatter's width.
  prefixBinding = ''bind "Ctrl a" { SwitchToMode "Tmux"; }'';
  sendPrefixBinding = ''bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }'';
  lastTabBinding = ''bind "a" { ToggleTab; SwitchToMode "Normal"; }'';

  tabBindingAssertions = map (
    n:
    let
      i = toString n;
    in
    assertGenerated "tab-${i}" ''bind "${i}" { GoToTab ${i}; SwitchToMode "Normal"; }''
  ) (lib.range 1 9);

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "zellij-functionality" (
    [
      (helpers.assertTest "zellij-enabled" (
        zellijConfig.enable == true
      ) "Zellij should be enabled when modules.programs.zellij.enable is set")

      # Shell auto-start must stay off: home-manager's integration launches
      # Zellij from every interactive shell, including shells inside tmux panes.
      (helpers.assertTest "zellij-no-zsh-autostart" (
        zellijConfig.enableZshIntegration == false
      ) "Zellij zsh integration must stay disabled to avoid auto-starting inside tmux")
      (helpers.assertTest "zellij-no-bash-autostart" (
        zellijConfig.enableBashIntegration == false
      ) "Zellij bash integration must stay disabled to avoid auto-starting inside tmux")
      (helpers.assertTest "zellij-no-fish-autostart" (
        zellijConfig.enableFishIntegration == false
      ) "Zellij fish integration must stay disabled to avoid auto-starting inside tmux")

      # Parity with tmux.nix — these settings mirror a tmux option directly.
      (helpers.assertTest "zellij-prefix-matches-tmux" (
        tmuxConfig.prefix == "C-a" && lib.hasInfix prefixBinding generatedConfig
      ) "Zellij's mode-entry key should match tmux's prefix (C-a)")
      (helpers.assertTest "zellij-scrollback-matches-tmux" (
        zellijConfig.settings.scroll_buffer_size == tmuxConfig.historyLimit
      ) "Zellij scroll_buffer_size should match tmux historyLimit")

      # Settings block
      (assertGenerated "default-shell-zsh" "/bin/zsh")
      (assertGenerated "compact-layout" ''default_layout "compact"'')
      (assertGenerated "scroll-buffer" "scroll_buffer_size 50000")
      (assertGenerated "clipboard-system" ''copy_clipboard "system"'')
      (assertGenerated "copy-on-select" "copy_on_select true")
      (assertGenerated "session-serialization" "session_serialization true")
      (assertGenerated "serialize-viewport" "serialize_pane_viewport true")
      (assertGenerated "detach-on-force-close" ''on_force_close "detach"'')

      # OSC52 clipboard, as in tmux.nix: Zellij only emits OSC52 itself when no
      # copy_command hands the job to an external binary.
      (helpers.assertTest "zellij-no-copy-command" (
        !(lib.hasInfix "copy_command" generatedConfig)
      ) "Zellij must not set copy_command, so it emits OSC52 like tmux does")

      # tmux-shaped keybindings
      (assertGenerated "send-prefix" sendPrefixBinding)
      (assertGenerated "resize-left" ''bind "H" { Resize "Increase Left"; }'')
      (assertGenerated "resize-right" ''bind "L" { Resize "Increase Right"; }'')
      (assertGenerated "last-tab" lastTabBinding)
      (assertGenerated "prev-tab-alt" ''bind "Alt h" { GoToPreviousTab; }'')
      (assertGenerated "next-tab-alt" ''bind "Alt l" { GoToNextTab; }'')
      (assertGenerated "session-picker" "session-manager")
    ]
    ++ tabBindingAssertions
    ++ [
      # Zellij's own defaults must survive: the module only overrides keys.
      (helpers.assertTest "zellij-keeps-defaults" (
        !(lib.hasInfix "clear-defaults" generatedConfig)
      ) "Keybinds should extend Zellij's defaults, not clear them")

      # Splits stay on Zellij's tmux-mode defaults (% and "), so the module
      # must not bind NewPane at all.
      (helpers.assertTest "zellij-default-splits" (
        !(lib.hasInfix "NewPane" generatedConfig)
      ) "Splits should be left at Zellij's defaults, not rebound")

      # A malformed keybinds block stops Zellij from starting at all, so check
      # the generated KDL is at least brace-balanced.
      (helpers.assertTest "zellij-kdl-braces-balanced" (
        (countOccurrences "{" generatedConfig) == (countOccurrences "}" generatedConfig)
      ) "Generated zellij/config.kdl should have balanced braces")
    ]
  );
}
