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
  options.modules.programs.docker.enable = lib.mkEnableOption "Docker CLI context and completion" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.DOCKER_CONTEXT = "orbstack";

    programs.zsh.initContent = lib.mkAfter ''
      # =============================================================================
      # Section: Docker CLI completion
      # =============================================================================
      # docker comes from OrbStack, outside Nix, so the completion script is
      # cached on first use and regenerated when the docker binary changes.
      if (( $+commands[docker] )); then
        _docker_completion="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_docker"
        if [[ ! -s $_docker_completion || $commands[docker] -nt $_docker_completion ]]; then
          mkdir -p "''${_docker_completion:h}"
          docker completion zsh >| "$_docker_completion" 2>/dev/null
        fi
        source "$_docker_completion"
        unset _docker_completion
      fi
    '';
  };
}
