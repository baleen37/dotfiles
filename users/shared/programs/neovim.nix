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

        vim.g.airline_theme = "term"
        vim.g.airline_powerline_fonts = 0
        vim.o.showmode = false

        local markdownWindowOptionNames = { "wrap", "linebreak", "breakindent" }
        local markdownWindowOptions = {}
        local markdownRenderedBuffers = {}

        require("render-markdown").setup({
          enabled = false,
          win_options = {
            wrap = { default = vim.wo.wrap, rendered = true },
            linebreak = { default = vim.wo.linebreak, rendered = true },
            breakindent = { default = vim.wo.breakindent, rendered = true },
          },
          on = {
            clear = function(context)
              if markdownRenderedBuffers[context.buf] then return end
              local windowOptions = markdownWindowOptions[context.buf]
              if not windowOptions then return end
              for win, options in pairs(windowOptions) do
                if vim.api.nvim_win_is_valid(win) then
                  for name, value in pairs(options) do
                    vim.wo[win][name] = value
                  end
                end
              end
              markdownWindowOptions[context.buf] = nil
              markdownRenderedBuffers[context.buf] = nil
            end,
          },
        })

        require("neo-tree").setup({
          hide_root_node = true,
          window = {
            width = 32,
          },
        })

        vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
        vim.keymap.set("n", "<leader>mr", function()
          local buffer = vim.api.nvim_get_current_buf()
          if markdownRenderedBuffers[buffer] then
            markdownRenderedBuffers[buffer] = false
          else
            local windowOptions = {}
            for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
              windowOptions[win] = {}
              for _, name in ipairs(markdownWindowOptionNames) do
                windowOptions[win][name] = vim.wo[win][name]
              end
            end
            markdownWindowOptions[buffer] = windowOptions
            markdownRenderedBuffers[buffer] = true
          end
          require("render-markdown").buf_toggle()
        end, { desc = "Toggle Markdown rendering" })
        vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Toggle Markdown browser preview" })

        vim.keymap.set("n", "<leader>ff", function()
          require("fzf-lua").files()
        end, { desc = "Find files" })
      '';
    };
  };
}
