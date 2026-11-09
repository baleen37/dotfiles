{
  config,
  lib,
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
