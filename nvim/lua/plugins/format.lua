-- formatting with conform
-- off on save by default, so your code stays the way you wrote it
-- shortcuts below are read by the `keys` script (key, 3+ spaces, description):
--   <leader>cf   Format the current file now, without saving
--   <leader>tf   Toggle format on save, e.g. to save once without formatting

local format_on_save = false

return {
  "stevearc/conform.nvim",
  lazy = false,
  config = function()
    local conform = require("conform")
    conform.setup({
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
        python = { "ruff_format" },
      },
      formatters = {
        -- no .clang-format in the project -> LLVM style but with 4 spaces
        -- and pointers/references stuck to the type: int* p, std::string& s
        ["clang-format"] = {
          prepend_args = function(_, ctx)
            local found = vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = ctx.dirname })
            if #found == 0 then
              return { "--style={BasedOnStyle: LLVM, IndentWidth: 4, PointerAlignment: Left, DerivePointerAlignment: false}" }
            end
            return {}
          end,
        },
      },
      format_on_save = function()
        if format_on_save then
          return { timeout_ms = 1000, lsp_format = "fallback" }
        end
      end,
    })

    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      conform.format({ lsp_format = "fallback" })
    end, { desc = "format" })

    vim.keymap.set("n", "<leader>tf", function()
      format_on_save = not format_on_save
      print("format on save: " .. (format_on_save and "on" or "off"))
    end, { desc = "format on save" })
  end,
}
