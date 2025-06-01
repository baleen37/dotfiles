{ inputs, ... }:
{
  x86_64-linux = {
    homerow = import ../modules/user-env/gui/homerow/test.nix inputs.nixpkgs;
  };
}
