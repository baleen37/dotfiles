{ lib, pkgs, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  pluginHelpers = import ../lib/plugin-test-helpers.nix { inherit lib; };

  neovimModuleResult = builtins.tryEval (
    import ../../users/shared/programs/neovim.nix {
      inherit pkgs lib;
      config.modules.programs.neovim.enable = true;
    }
  );
  neovimConfig = if neovimModuleResult.success then neovimModuleResult.value.config.content else { };
  neovim = neovimConfig.programs.neovim or { };
  plugins = neovim.plugins or [ ];
  extraPackages = neovim.extraPackages or [ ];
  initLua = neovim.initLua or "";

  treesitterWithMarkdownParsers = pkgs.vimPlugins.nvim-treesitter.withPlugins (parsers: [
    parsers.markdown
    parsers.markdown_inline
  ]);

  fontsModuleResult = builtins.tryEval (
    import ../../users/shared/packages/fonts.nix {
      inherit pkgs lib;
      config.modules.packages.fonts.enable = true;
    }
  );
  fontsConfig = if fontsModuleResult.success then fontsModuleResult.value.config.content else { };
  fontPackages = fontsConfig.home.packages or [ ];

in
helpers.testSuite "neovim-markdown-preview" [
  (helpers.assertTest "neovim-module-imports" neovimModuleResult.success
    "Neovim configuration should be importable"
  )

  (helpers.assertTest "render-markdown-plugin"
    (pluginHelpers.hasPluginByName plugins "render-markdown.nvim")
    "render-markdown.nvim should be installed"
  )

  (helpers.assertTest "markdown-preview-plugin"
    (pluginHelpers.hasPluginByName plugins "markdown-preview.nvim")
    "markdown-preview.nvim should be installed"
  )

  (helpers.assertTest "markdown-preview-node-runtime" (builtins.elem pkgs.nodejs_22 extraPackages)
    "Node.js should be available in the Neovim runtime for markdown-preview.nvim"
  )

  (helpers.assertTest "neovim-provider-defaults-preserved" (
    neovim.withRuby == true && neovim.withPython3 == true
  ) "Neovim Ruby and Python providers should keep their previous enabled defaults")

  (helpers.assertTest "markdown-treesitter-parsers"
    (builtins.elem treesitterWithMarkdownParsers plugins)
    "nvim-treesitter should include markdown and markdown_inline parsers"
  )

  (helpers.assertTest "render-markdown-disabled-by-default" (
    pluginHelpers.hasConfigString initLua "require(\"render-markdown\").setup({"
    && pluginHelpers.hasConfigString initLua "enabled = false,"
  ) "in-buffer Markdown rendering should start disabled")

  (helpers.assertTest "render-markdown-wrap-options" (
    pluginHelpers.hasConfigString initLua "win_options = {"
    && pluginHelpers.hasConfigString initLua "wrap = { default = vim.wo.wrap, rendered = true }"
    && pluginHelpers.hasConfigString initLua "linebreak = { default = vim.wo.linebreak, rendered = true }"
    && pluginHelpers.hasConfigString initLua "breakindent = { default = vim.wo.breakindent, rendered = true }"
  ) "rendered Markdown should enable soft wrapping and restore existing window options")

  (helpers.assertTest "render-markdown-window-options-restored" (
    pluginHelpers.hasConfigString initLua "clear = function(context)"
    && pluginHelpers.hasConfigString initLua "vim.fn.win_findbuf(buffer)"
    && pluginHelpers.hasConfigString initLua "vim.wo[win][name] = value"
  ) "render-markdown should restore each window's original soft-wrap options")

  (helpers.assertTest "render-markdown-toggle-binding" (
    pluginHelpers.hasConfigString initLua "<leader>mr"
    && pluginHelpers.hasConfigString initLua "require(\"render-markdown\").buf_toggle()"
  ) "<leader>mr should toggle Markdown rendering for the current buffer")

  (helpers.assertTest "markdown-preview-toggle-binding" (
    pluginHelpers.hasConfigString initLua "<leader>mp"
    && pluginHelpers.hasConfigString initLua "MarkdownPreviewToggle"
  ) "<leader>mp should toggle the browser Markdown preview")

  (helpers.assertTest "nerd-font-symbols-installed"
    (builtins.elem pkgs.nerd-fonts.symbols-only fontPackages)
    "Nerd Font symbols should be available for render-markdown icons"
  )
]
