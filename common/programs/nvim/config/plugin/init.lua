require("zk").setup({
  -- can be "telescope", "fzf" or "select" (`vim.ui.select`)
  -- it's recommended to use "telescope" or "fzf"
  picker = "select",

  lsp = {
    -- `config` is passed to `vim.lsp.start_client(config)`
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      -- on_attach = ...
      -- etc, see `:h vim.lsp.start_client()`
    },

    -- automatically attach buffers in a zk notebook that match the given filetypes
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
    },
  },
})
--lspconfig.zk.setup({ on_attach = function(client, buffer) 
--  -- Add keybindings here, see https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
--
--
--  -- Preview a linked note.
--  vim.api.nvim_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
--
--  -- Open the link under the caret.
--  vim.api.nvim_set_keymap("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
--
--  -- Create a new note after asking for its title.
--  -- This overrides the global `<leader>zn` mapping to create the note in the same directory as the current buffer.
--  vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
--  -- Create a new note in the same directory as the current buffer, using the current selection for title.
--  vim.api.nvim_set_keymap("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)
--  -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
--  vim.api.nvim_set_keymap("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
--
--  -- Open notes linking to the current buffer.
--  vim.api.nvim_set_keymap("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", opts)
--  -- Alternative for backlinks using pure LSP and showing the source context.
--  --map('n', '<leader>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
--  -- Open notes linked by the current buffer.
--  vim.api.nvim_set_keymap("n", "<leader>zl", "<Cmd>ZkLinks<CR>", opts)
--
--  -- Preview a linked note.
--  vim.api.nvim_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
--  -- Open the code actions for a visual selection.
--  vim.api.nvim_set_keymap("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
--end })
---- require("zk").setup({
----   -- can be "telescope", "fzf" or "select" (`vim.ui.select`)
----   -- it's recommended to use "telescope" or "fzf"
----   picker = "fzf",
---- 
----   lsp = {
----     -- `config` is passed to `vim.lsp.start_client(config)`
----     config = {
----       cmd = { "zk", "lsp" },
----       name = "zk",
----       filetypes = {'markdown'},
----       root_dir = function()
----         return vim.loop.cwd()
----       end,
----       -- etc, see `:h vim.lsp.start_client()`
----     },
---- 
----     -- automatically attach buffers in a zk notebook that match the given filetypes
----     auto_attach = {
----       enabled = true,
----       filetypes = { "markdown" },
----     },
----   },
---- })
----
----
