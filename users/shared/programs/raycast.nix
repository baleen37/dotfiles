# Raycast Script Command and Extension configuration

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.raycast;
  firefoxProfileActivator = pkgs.stdenv.mkDerivation {
    pname = "raycast-firefox-profile-activate";
    version = "0.1.0";
    src = ./.config/raycast/firefox-profile-activate.swift;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.swiftPackages.swift ];

    buildPhase = ''
      runHook preBuild
      swiftc -O -o firefox-profile-activate "$src"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 firefox-profile-activate "$out/bin/firefox-profile-activate"
      runHook postInstall
    '';
  };
in
{
  options.modules.programs.raycast.enable = lib.mkEnableOption "Raycast Script Commands" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/raycast/script-commands" = {
      source = ./.config/raycast/script-commands;
      recursive = true;
      force = true;
    };

    home.file.".config/raycast/firefox-profile-launcher.zsh" = {
      source = ./.config/raycast/firefox-profile-launcher.zsh;
      executable = true;
      force = true;
    };

    home.file.".config/raycast/firefox-profile-activate" = {
      source = "${firefoxProfileActivator}/bin/firefox-profile-activate";
      executable = true;
      force = true;
    };
  };
}
