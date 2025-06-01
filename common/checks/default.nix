{ inputs, ... }:
{
  x86_64-linux = {
    homerow = import ../../hosts/jito/programs/homerow/test.nix inputs.nixpkgs;
  };
}
