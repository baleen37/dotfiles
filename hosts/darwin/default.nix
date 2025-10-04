{ config
, pkgs
, lib
, ...
}:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/app-links.nix
    ../../modules/darwin/nix-gc.nix # macOS 전용 갈비지 컬렉션 설정
    ../../modules/shared
  ];

  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Minimal Nix configuration compatible with Determinate Nix
  # Advanced settings managed by Determinate Nix in /etc/nix/nix.conf
  nix = {
    # Disabled to prevent conflicts with Determinate Nix
  };

  # zsh program activation
  programs.zsh.enable = true;

  # Disable automatic app links (requires root privileges)
  system.nixAppLinks.enable = false;

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;
  };
}
