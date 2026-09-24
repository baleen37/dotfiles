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
      withRuby = true;
      withPython3 = true;
      extraPackages = [ pkgs.nodejs_22 ];

      plugins = [
        pkgs.vimPlugins.vim-airline
        pkgs.vimPlugins.vim-airline-themes
        pkgs.vimPlugins.vim-tmux-navigator
        pkgs.vimPlugins.neo-tree-nvim
        pkgs.vimPlugins.nui-nvim
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.markdown-preview-nvim
        (pkgs.vimPlugins.nvim-treesitter.withPlugins (parsers: [
          parsers.markdown
          parsers.markdown_inline
        ]))
        pkgs.vimPlugins.render-markdown-nvim
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

        require("render-markdown").setup({ enabled = false })

        require("neo-tree").setup({
          hide_root_node = true,
          window = {
            width = 32,
          },
        })

        vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
        vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown buf_toggle<cr>", { desc = "Toggle Markdown rendering" })
        vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Toggle Markdown browser preview" })

        vim.keymap.set("n", "<leader>ff", function()
          require("fzf-lua").files()
        end, { desc = "Find files" })
      '';
    };
  };
}
