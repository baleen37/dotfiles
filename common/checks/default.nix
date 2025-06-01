{ inputs, ... }:
{
  x86_64-darwin = {
    homerow = import ../modules/user-env/gui/homerow/test.nix inputs.nixpkgs;
  };
}
