{ config, lib, pkgs, ... }:

with lib;

let
  # Removed cfg = config.homebrew;
in {
  config = mkIf pkgs.stdenv.isDarwin {
    home.activation = {
      copyApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
        baseDir="$HOME/Applications/Home Manager Apps"

        # 디렉토리 백업 후 새로 생성
        if [ -d "$baseDir" ]; then
          $DRY_RUN_CMD echo "Backing up $baseDir to $baseDir.backup"
          $DRY_RUN_CMD mv "$baseDir" "$baseDir.backup"
        fi

        # 새 디렉토리 생성
        $DRY_RUN_CMD mkdir -p "$baseDir"

        # 애플리케이션 복사
        if [ -d "${config.home.homeDirectory}/.nix-profile/Applications" ]; then
          for appFile in $(find ${config.home.homeDirectory}/.nix-profile/Applications -type l -maxdepth 1); do
            target="$baseDir/$(basename "$appFile")"
            $DRY_RUN_CMD cp -fR "$appFile" "$target"
            $DRY_RUN_CMD chmod -R +w "$target"
          done
        else
          $DRY_RUN_CMD echo "No applications found in ${config.home.homeDirectory}/.nix-profile/Applications"
        fi
      '';
    };
  };
}
