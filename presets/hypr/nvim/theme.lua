-- nvim colors - hypr preset (hswi swaps this file, see presets/files.txt)

-- rounded corners on floating windows, like the rest of this preset
vim.o.winborder = "rounded"

-- transparent background, so the ghostty blur shows through nvim too
require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = true,
  float = { transparent = false },
})
vim.cmd.colorscheme("catppuccin-mocha")

-- file name bar above every split (FileBar* groups, see plugins/ui.lua)
-- same colors as the tmux bar: accent for the window you're in, a dimmer block for the rest
local bar_colors = {
  WinBar = { bg = "NONE" },
  WinBarNC = { bg = "NONE" },
  FileBarCurrent = { fg = "#1e1e2e", bg = "#cba6f7", bold = true },
  FileBarOther = { fg = "#7f849c", bg = "#313244" },
  FileBarModifiedCurrent = { fg = "#1e1e2e", bg = "#f9e2af", bold = true },
  FileBarModifiedOther = { fg = "#f9e2af", bg = "#313244" },
}
for name, val in pairs(bar_colors) do
  vim.api.nvim_set_hl(0, name, val)
end
