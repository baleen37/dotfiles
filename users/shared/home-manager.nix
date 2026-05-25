{
  pkgs,
  currentSystemUser,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

{
  imports = [
    # Tool configurations (programs)
    ./programs/git.nix
    ./programs/vim.nix
    ./programs/zsh
    ./programs/starship.nix
    ./programs/tmux.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/ghostty.nix
    ./programs/hammerspoon.nix
    ./programs/karabiner.nix

    # Package categories (enable-flag pattern; all default to true)
    ./packages/core.nix
    ./packages/dev.nix
    ./packages/lsp.nix
    ./packages/nix-tools.nix
    ./packages/cloud.nix
    ./packages/security.nix
    ./packages/ssh.nix
    ./packages/media.nix
    ./packages/fonts.nix
    ./packages/databases.nix
    ./packages/ai.nix
  ];

  # Enable all package categories (default=false in module, explicitly enabled here)
  modules.packages = {
    core.enable = true;
    dev.enable = true;
    lsp.enable = true;
    nix-tools.enable = true;
    cloud.enable = true;
    security.enable = true;
    ssh.enable = true;
    media.enable = true;
    fonts.enable = true;
    databases.enable = true;
    ai.enable = true;
  };

  home = {
    username = currentSystemUser;
    homeDirectory = if isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
    stateVersion = "24.11";
  };

  xdg.enable = true;
}
