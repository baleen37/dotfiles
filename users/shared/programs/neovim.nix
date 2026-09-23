{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.neovim;
in
{
  options.modules.programs.neovim.enable = lib.mkEnableOption "Neovim editor configuration";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;

      plugins = [
        pkgs.vimPlugins.vim-airline
        pkgs.vimPlugins.vim-airline-themes
        pkgs.vimPlugins.vim-tmux-navigator
        {
          plugin = pkgs.vimPlugins.fzf-lua;
          type = "lua";
          config = "require('fzf-lua').setup({})";
        }
      ];

      initLua = ''
        vim.g.mapleader = " "
        vim.g.maplocalleader = ","
        vim.o.ignorecase = true
        vim.cmd([==[${builtins.readFile ./vim-common.vim}]==])

        vim.keymap.set("n", "<leader>ff", function()
          require("fzf-lua").files()
        end, { desc = "Find files" })
      '';
    };
  };
}
