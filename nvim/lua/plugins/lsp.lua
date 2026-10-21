-- LSP = errors while typing, go to definition, rename, etc.
--
-- built in since 0.11/0.12 (no need to map them):
--   K     docs for thing under cursor     grn  rename
--   gra   code action                     grr  references
--   gri   implementation                  grt  type definition
--   gO    symbols in file                 [d ]d  prev/next error
--   C-s   (insert) function signature

return {
  "neovim/nvim-lspconfig", -- ready configs for language servers
  lazy = false,
  dependencies = {
    "mason-org/mason.nvim", -- installs servers / formatters
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- mason installs servers into ~/.local/share/nvim/mason, :Mason to look around
    require("mason").setup()

    -- clangd: the one from Xcode Command Line Tools knows where the macOS headers are,
    -- the mason one often can't find <iostream>, so system first
    local clangd = "clangd"
    local servers = { "lua_ls", "pyright" }
    if vim.fn.executable("/usr/bin/clangd") == 1 then
      clangd = "/usr/bin/clangd"
    else
      table.insert(servers, "clangd")
    end

    require("mason-lspconfig").setup({
      ensure_installed = servers,
      automatic_enable = true, -- everything mason installed gets turned on
    })

    -- formatters, conform uses them
    require("mason-tool-installer").setup({
      ensure_installed = { "clang-format", "stylua", "ruff" },
    })

    -- server settings (merged with the defaults from nvim-lspconfig)
    vim.lsp.config("clangd", {
      cmd = {
        clangd,
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never", -- don't add #includes by itself
        "--completion-style=detailed",
      },
      -- files without compile_commands.json still get C++20
      init_options = { fallbackFlags = { "-std=c++20" } },
    })
    vim.lsp.enable("clangd")

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim", "MiniIcons" } },
          workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
        },
      },
    })

    -- errors: text at the end of the line, worst first
    vim.diagnostic.config({
      severity_sort = true,
      virtual_text = { spacing = 2, source = "if_many" },
      underline = true,
      update_in_insert = false,
      float = { source = true },
    })

    -- extra keys only when a server is attached to the buffer
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        local function map(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
        end
        local fzf = require("fzf-lua")

        map("gd", fzf.lsp_definitions, "go to definition")
        map("gD", vim.lsp.buf.declaration, "go to declaration")
        map("grr", fzf.lsp_references, "references")
        map("<leader>cr", vim.lsp.buf.rename, "rename")
        map("<leader>ca", vim.lsp.buf.code_action, "code action")
        map("<leader>th", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
        end, "inlay hints")

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "clangd" then
          map("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", "switch .cpp / .h")
        end
      end,
    })
  end,
}
