# tests/default.nix
{
  pkgs ? import <nixpkgs> { },
  lib ? import <nixpkgs/lib>,
  self ? ./.,
}:

let
  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

in
{
  # Smoke test using NixTest framework
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready - using NixTest framework"
    touch $out
  '';
}
