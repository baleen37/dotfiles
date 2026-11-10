{
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}:
{
  options.dotfiles.setup = {
    homebrewRequired = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected host needs Homebrew before activation.";
    };
    appManagementRequired = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected host installs apps requiring macOS App Management consent.";
    };
    tailscaleEnroll = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writeTextFile {
        name = "no-tailscale-enroll";
        destination = "/bin/dotfiles-tailscale-enroll";
        executable = true;
        text = "#!/bin/sh\n";
      };
      description = "Joins this host to the tailnet once; bootstrap.sh runs it, switch never does.";
    };
  };

  config.dotfiles.setup = {
    homebrewRequired = isDarwin && config.homebrew.enable;
    appManagementRequired =
      isDarwin
      && (
        config.programs._1password-gui.enable
        || (config.homebrew.enable && (config.homebrew.casks != [ ] || config.homebrew.masApps != { }))
      );
  };
}
