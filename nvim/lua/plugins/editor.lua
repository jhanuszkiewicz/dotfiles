return {
  -- fuzzy finder (uses fzf, rg and fd from brew)
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy", -- right after startup, so theme.lua already set vim.o.winborder
    config = function()
      local map = vim.keymap.set
      local fzf = require("fzf-lua")
      fzf.setup({
        "default-title",
        fzf_colors = true, -- colors from the nvim colorscheme
        winopts = {
          border = vim.o.winborder,
          preview = { border = vim.o.winborder },
        },
      })
      fzf.register_ui_select() -- code actions etc. pick through fzf too

      map("n", "<leader><space>", fzf.files, { desc = "find file" })
      map("n", "<leader>ff", fzf.files, { desc = "files" })
      map("n", "<leader>fg", fzf.live_grep, { desc = "grep in project" })
      map("n", "<leader>fw", fzf.grep_cword, { desc = "grep word under cursor" })
      map("n", "<leader>fb", fzf.buffers, { desc = "open buffers" })
      map("n", "<leader>fo", fzf.oldfiles, { desc = "recent files" })
      map("n", "<leader>fh", fzf.helptags, { desc = "help" })
      map("n", "<leader>fk", fzf.keymaps, { desc = "keymaps" })
      map("n", "<leader>fd", fzf.diagnostics_document, { desc = "errors in file" })
      map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "symbols in file" })
      map("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "todos" })
      map("n", "<leader>fr", fzf.resume, { desc = "resume last search" })
      map("n", "<leader>/", fzf.blines, { desc = "search in file" })
      map("n", "<leader>fc", function()
        fzf.files({ cwd = vim.fn.stdpath("config") })
      end, { desc = "nvim config" })
    end,
  },

  -- oil: a folder is a buffer, rename/delete/create files by editing text and :w
  {
    "stevearc/oil.nvim",
    lazy = false, -- has to be loaded at start so `nvim .` opens oil
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ["<C-h>"] = false, -- keep C-h/C-l for moving between splits
        ["<C-l>"] = false,
        ["q"] = "actions.close",
      },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "open folder" },
    },
  },

  -- mini.pairs / mini.surround / mini.ai are set up in ui.lua with the rest of mini
}
