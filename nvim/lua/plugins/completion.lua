-- completion popup while typing (blink.cmp)
--   C-space  open menu / docs       C-n C-p  or up/down  move
--   C-y      accept                 C-e      close
--   Tab      jump to next spot in a snippet
return {
  "saghen/blink.cmp",
  version = "1.*", -- release with a prebuilt binary
  dependencies = { "rafamadriz/friendly-snippets" },
  lazy = false, -- has to be there before lsp servers start, it tells them what completion can do
  -- a function, so vim.o.winborder is read after theme.lua has set it
  opts = function()
    return {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        menu = { border = vim.o.winborder },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
          window = { border = vim.o.winborder },
        },
      },
      signature = { enabled = true, window = { border = vim.o.winborder } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      -- rust matcher downloaded with the release, lua one if that fails
      fuzzy = { implementation = "prefer_rust_with_warning" },
    }
  end,
}
