# tests/default.nix
{ system, inputs }:

let
  pkgs = import inputs.nixpkgs { inherit system; };

in
{
  # Placeholder - will add tests as we build
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready"
    touch $out
  '';
}
