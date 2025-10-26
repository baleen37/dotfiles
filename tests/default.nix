# tests/default.nix
{ inputs, system }:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;

  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../lib/mksystem.nix { inherit inputs; };

in
{
  # Smoke test using NixTest framework
  smoke = pkgs.runCommand "smoke-test" { } ''
    echo "✅ Test infrastructure ready - using NixTest framework"
    touch $out
  '';

  # Add unit test (will fail initially)
  unit-mksystem = import ./unit/mksystem-test.nix {
    inherit
      inputs
      system
      pkgs
      lib
      ;
    inherit (nixtest) nixtest;
  };

  # Add Claude configuration test
  unit-claude = import ./unit/claude-test.nix { inherit inputs system; };

  # Add git configuration test
  unit-git = import ./unit/git-test.nix { inherit inputs system; };

  # Add vim configuration test (will fail initially)
  unit-vim = import ./unit/vim-test.nix { inherit inputs system; };

  # Add zsh configuration test (will fail initially)
  unit-zsh = import ./unit/zsh-test.nix { inherit inputs system; };

  # Add tmux configuration test (will fail initially)
  unit-tmux = import ./unit/tmux-test.nix { inherit inputs system; };

  # Add Darwin configuration test
  unit-darwin = import ./unit/darwin-test.nix { inherit inputs system; };

  # Add home-manager integration test
  integration-home-manager = import ./integration/home-manager-test.nix { inherit inputs system; };
}
