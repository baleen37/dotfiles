# tests/default.nix
{
  inputs,
  system,
  self,
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;

  # Import existing NixTest framework
  nixtest = import ./unit/nixtest-template.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../lib/mksystem.nix { inherit inputs self; };

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
      self
      ;
    inherit (nixtest) nixtest;
  };

  # Add Claude configuration test
  unit-claude = import ./unit/claude-test.nix {
    inherit
      inputs
      system
      pkgs
      lib
      ;
    inherit (nixtest) nixtest;
  };

  # Add git configuration test
  unit-git = import ./unit/git-test.nix {
    inherit
      inputs
      system
      pkgs
      lib
      ;
    inherit (nixtest) nixtest;
  };

  # Add Hammerspoon configuration test
  unit-hammerspoon = import ./unit/hammerspoon-test.nix {
    inherit
      inputs
      system
      pkgs
      lib
      ;
    inherit (nixtest) nixtest;
  };

  # TODO: Fix remaining unit tests - they need to be converted from test suites to derivations
  # unit-vim = import ./unit/vim-test.nix { inherit inputs system; };
  # unit-zsh = import ./unit/zsh-test.nix { inherit inputs system; };
  # unit-tmux = import ./unit/tmux-test.nix { inherit inputs system; };
  # unit-darwin = import ./unit/darwin-test.nix { inherit inputs system; };

  # TODO: Fix integration tests - they also need to be converted to derivations
  # integration-home-manager = import ./integration/home-manager-test.nix { inherit inputs system; };
  # integration-build = import ./integration/build-test.nix { inherit inputs system; };
}
