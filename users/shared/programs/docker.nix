# Docker CLI configuration
#
# Pins the Docker context to OrbStack and enables Docker CLI completion in
# zsh. OrbStack owns ~/.docker/config.json (credsStore, currentContext), so
# this module deliberately does not touch it.
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.docker;
in
{
  options.modules.programs.docker.enable = lib.mkEnableOption "Docker CLI context and completion";

  config = lib.mkIf cfg.enable {
    home.sessionVariables.DOCKER_CONTEXT = "orbstack";

    programs.zsh.initContent = lib.mkAfter ''
      # =============================================================================
      # Section: Docker CLI completion
      # =============================================================================
      if command -v docker >/dev/null 2>&1; then
        docker completion zsh 2>/dev/null | source /dev/stdin
      fi
    '';
  };
}
