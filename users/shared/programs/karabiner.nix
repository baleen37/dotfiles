# Karabiner-Elements configuration
# Manages keyboard customization via Home Manager, generated from Nix.
#
# Design: Hyper key implemented entirely in Karabiner (Secure Input immune).
#   right_command (held) → set hyper=1, emit F19 (Hammerspoon modal trigger)
#   right_command (released) → set hyper=0
#   While hyper=1:
#     - App launchers: toggle pattern. If app is frontmost → osascript hide.
#       Otherwise → software_function.open_application (launch/focus).
#     - Local bindings: forward as mega-chord (cmd+ctrl+opt+shift+key) so
#       target app's own shortcut handler picks it up.
#   Unintercepted keys pass through to Hammerspoon as F19+key (HyperModal,
#   Pomodoro, etc.).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.karabiner;

  # App definitions: key → { bundle = bundleId; proc = processName; }
  # `proc` is the AppleScript process name (sometimes different from bundle).
  # Discover via: osascript -e 'tell application "System Events" to get name of every application process'
  hyperApps = {
    i = {
      bundle = "com.mitchellh.ghostty";
      proc = "ghostty";
    };
    e = {
      bundle = "com.apple.mail";
      proc = "Mail";
    };
    h = {
      bundle = "com.kapeli.dashdoc";
      proc = "Dash";
    };
    k = {
      bundle = "com.kakao.KakaoTalkMac";
      proc = "KakaoTalk";
    };
    n = {
      bundle = "notion.id";
      proc = "Notion";
    };
    o = {
      bundle = "md.obsidian";
      proc = "Obsidian";
    };
    m = {
      bundle = "com.tinyspeck.slackmacgap";
      proc = "Slack";
    };
    t = {
      bundle = "com.culturedcode.ThingsMac";
      proc = "Things3";
    };
  };

  # key_code → bundle_identifier. Forward as mega-chord (cmd+ctrl+opt+shift+key)
  # so the app's own global shortcut handler triggers. Replaces Hammerspoon's
  # bindPassThrough — moved here for Secure Input immunity.
  # Note: comma is intentionally NOT bound here. It passes through to
  # Hammerspoon (F19+comma) as the Neru leader — see hammerspoon/init.lua.
  hyperLocal = {
    b = "com.surteesstudios.Bartender";
    l = "com.dexterleng.Homerow";
    u = "com.flexibits.cardhop.mac";
    return_or_enter = "com.superultra.Homerow";
    tab = "com.superultra.Homerow";
  };

  hyperVar = "hyper";
  megaMods = [
    "left_command"
    "left_control"
    "left_option"
    "left_shift"
  ];

  # right_command itself: set variable + emit F19 (for Hammerspoon modal).
  hyperTrigger = {
    type = "basic";
    from = {
      key_code = "right_command";
      modifiers.optional = [ "any" ];
    };
    to = [
      {
        set_variable = {
          name = hyperVar;
          value = 1;
        };
      }
      { key_code = "f19"; }
    ];
    to_after_key_up = [
      {
        set_variable = {
          name = hyperVar;
          value = 0;
        };
      }
    ];
  };

  # Toggle pattern: if app is frontmost → hide via osascript. Otherwise → open.
  # `^` and `$` anchor the bundle id regex (frontmost_application_if uses regex).
  mkHideManipulator = key: app: {
    type = "basic";
    from.key_code = key;
    conditions = [
      {
        type = "variable_if";
        name = hyperVar;
        value = 1;
      }
      {
        type = "frontmost_application_if";
        bundle_identifiers = [ "^${lib.escapeRegex app.bundle}$" ];
      }
    ];
    to = [
      {
        shell_command = ''osascript -e 'tell application "System Events" to set visible of process "${app.proc}" to false' '';
      }
    ];
  };

  mkOpenManipulator = key: app: {
    type = "basic";
    from.key_code = key;
    conditions = [
      {
        type = "variable_if";
        name = hyperVar;
        value = 1;
      }
      {
        type = "frontmost_application_unless";
        bundle_identifiers = [ "^${lib.escapeRegex app.bundle}$" ];
      }
    ];
    to = [
      {
        software_function.open_application.bundle_identifier = app.bundle;
      }
    ];
  };

  mkAppToggle = key: app: [
    (mkHideManipulator key app)
    (mkOpenManipulator key app)
  ];

  mkLocalBinding = key: _bundleId: {
    type = "basic";
    from.key_code = key;
    conditions = [
      {
        type = "variable_if";
        name = hyperVar;
        value = 1;
      }
    ];
    to = [
      {
        key_code = key;
        modifiers = megaMods;
      }
    ];
  };

  appManipulators = lib.concatLists (lib.mapAttrsToList mkAppToggle hyperApps);
  localManipulators = lib.mapAttrsToList mkLocalBinding hyperLocal;

  hyperRule = {
    description = "Hyper key: right_command → F19 + hyper var, Secure Input-immune app toggles and local bindings";
    manipulators = [ hyperTrigger ] ++ appManipulators ++ localManipulators;
  };

  karabinerConfig = {
    profiles = [
      {
        name = "Default profile";
        selected = true;
        complex_modifications.rules = [ hyperRule ];
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";
      }
    ];
  };

in
{
  options.modules.programs.karabiner.enable = lib.mkEnableOption "Karabiner-Elements (macOS)" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/karabiner/karabiner.json" = {
      text = builtins.toJSON karabinerConfig;
      force = true;
    };
  };
}
