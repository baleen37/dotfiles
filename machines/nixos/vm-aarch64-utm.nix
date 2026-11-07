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

    # Interface is this on my M1
    networking.interfaces.enp0s10.useDHCP = true;

    # Qemu
    services.spice-vdagentd.enable = true;

    # Force software rendering for OpenGL applications.
    # Hardware acceleration for graphics is not fully supported in UTM VMs on Apple Silicon,
    # so this environment variable forces Mesa to use software rendering instead of
    # attempting to use virtualized GPU hardware that may not be available or stable.
    environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

    # Allow packages that may not officially support aarch64-linux.
    # Many packages in nixpkgs don't officially mark aarch64-linux as supported,
    # even though they work perfectly fine. This setting allows us to use these
    # packages in the VM despite their unsupported status in the package metadata.
    nixpkgs.config.allowUnsupportedSystem = true;
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
