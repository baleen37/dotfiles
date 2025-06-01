{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # Install plugins
    plugins = with pkgs.vimPlugins; [
      # UI improvements
      nvim-tree-lua
      lualine-nvim

      # Color scheme
      tokyonight-nvim

      # LSP and completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp

      # Syntax highlighting
      (nvim-treesitter.withPlugins (p: [
        p.tree-sitter-nix
        p.tree-sitter-lua
        p.tree-sitter-python
        p.tree-sitter-javascript
      ]))

      # Fuzzy finder
      telescope-nvim
    ];

    # Extra packages to make available to neovim
    extraPackages = with pkgs; [
      ripgrep
      fd
      nodejs # Required for some LSP servers
    ];

    # Your neovim configuration can be written here or imported from a separate file
    extraConfig = builtins.readFile ./config/init.vim;
  };
}
