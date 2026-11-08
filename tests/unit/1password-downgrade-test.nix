{ pkgs, lib, ... }:
let
  common = import ../../machines/darwin/common.nix {
    inherit pkgs lib;
    config.programs._1password-gui = {
      enable = true;
      package.version = "8.12.44";
    };
  };
  guard = pkgs.writeText "1password-version-guard" common.system.activationScripts.preActivation.text.content;
  plistBuddy = pkgs.writeShellScript "fixture-plistbuddy" ''
    printf '%s\n' "$INSTALLED_VERSION"
  '';
in
{
  platforms = [ "any" ];
  value = pkgs.runCommand "1password-downgrade-guard" { } ''
    cp ${guard} guard.sh
    substituteInPlace guard.sh \
      --replace-fail /usr/libexec/PlistBuddy ${plistBuddy} \
      --replace-fail /Applications/1Password.app/Contents/Info.plist "$TMPDIR/Info.plist"
    touch "$TMPDIR/Info.plist"
    INSTALLED_VERSION=8.12.40 ${pkgs.bash}/bin/bash guard.sh
    INSTALLED_VERSION=8.12.44 ${pkgs.bash}/bin/bash guard.sh
    if INSTALLED_VERSION=8.12.46 ${pkgs.bash}/bin/bash guard.sh 2>error; then
      echo 'A newer vault-writing app must never be downgraded' >&2
      exit 1
    fi
    grep -q 'Refusing to downgrade 1Password' error
    rm "$TMPDIR/Info.plist"
    ${pkgs.bash}/bin/bash guard.sh
    touch "$out"
  '';
}
