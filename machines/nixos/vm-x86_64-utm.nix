{
  lib,
  options,
  currentSystemUser,
  ...
}:
{
  imports = [
    ./hardware/vm-utm.nix
    ./vm-shared.nix
  ];

  config = {

    networking.interfaces.enp1s0.useDHCP = true;

    services.spice-vdagentd.enable = true;

  }
  // lib.optionalAttrs (options ? home-manager) {
    home-manager.users.${currentSystemUser} = {
      modules.programs.baleen-toolkit.enable = true;
      modules.programs.claude-code.enable = true;
      modules.programs.codex.enable = true;
      modules.programs.docker.enable = true;
      modules.programs.git.enable = true;
      modules.programs.herdr.enable = true;
      modules.programs.neovim.enable = true;
      modules.programs.powerlevel10k.enable = true;
      modules.programs.ssh.enable = true;
      modules.programs.terraform.enable = true;
      modules.programs.tmux.enable = true;
      modules.programs.vim.enable = true;
      modules.programs.yarn.enable = true;
      modules.programs.zsh.enable = true;
      modules.packages.ai.enable = true;
      modules.packages.cloud.enable = true;
      modules.packages.core.enable = true;
      modules.packages.databases.enable = true;
      modules.packages.dev.enable = true;
      modules.packages.fonts.enable = true;
      modules.packages.media.enable = true;
      modules.packages.nix-tools.enable = true;
      modules.packages.security.enable = true;
      modules.packages.ssh.enable = true;
    };
  };
}
