# NixOS inside WSL2 on Windows. Boot, networking, and the login user come from
# NixOS-WSL, so this does not import vm-shared.nix (bootloader and DHCP there
# are VM-only).
{
  inputs,
  currentSystemUser,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl.enable = true;
  wsl.defaultUser = currentSystemUser;
  # Keep Windows dirs (/mnt/c/Program Files/...) out of PATH: nothing here calls
  # Windows binaries, and their spaces break scripts that pass PATH around.
  wsl.interop.includePath = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
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
}
