# Docker program module tests
#
# Verifies that the docker module pins the Docker context to OrbStack and
# wires up Docker CLI zsh completion without touching OrbStack-owned state.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hm = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/docker.nix
      {
        home = {
          username = "testuser";
          homeDirectory = "/home/testuser";
          stateVersion = "24.11";
        };
        modules.programs.docker.enable = true;
      }
    ];
  };

  zshInit = hm.config.programs.zsh.initContent;
  sessionVars = hm.config.home.sessionVariables;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "docker-program" [
    (helpers.assertTest "docker-program-no-deprecation-warnings" (
      hm.config.warnings == [ ]
    ) "Docker configuration should not use deprecated Home Manager options")

    (helpers.assertTest "docker-program-context-pinned" (
      sessionVars.DOCKER_CONTEXT == "orbstack"
    ) "DOCKER_CONTEXT should pin to orbstack so docker always targets OrbStack")

    (helpers.assertTest "docker-program-completion-enabled"
      (lib.hasInfix "docker completion zsh" zshInit)
      "zsh init should source docker CLI completion"
    )
  ];
}
