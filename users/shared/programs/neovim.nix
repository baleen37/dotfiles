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
        pkgs.vimPlugins.neo-tree-nvim
        pkgs.vimPlugins.nui-nvim
        pkgs.vimPlugins.plenary-nvim
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

        vim.g.airline_theme = "minimalist"
        vim.g.airline_powerline_fonts = 0
        vim.o.showmode = false

        require("neo-tree").setup({
          hide_root_node = true,
          window = {
            width = 32,
          },
        })

        vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })

        vim.keymap.set("n", "<leader>ff", function()
          require("fzf-lua").files()
        end, { desc = "Find files" })
      '';
    };
  };
}
