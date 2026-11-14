# Shared selection used by development hosts and standalone Home Manager.
# Import this explicitly; minimal hosts keep optional tools disabled.
_: {
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
}
