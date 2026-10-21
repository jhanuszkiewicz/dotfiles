-- nvim colors - tokyo preset (hswi swaps this file, see presets/files.txt)

-- rounded corners on floating windows, like the rest of this preset
vim.o.winborder = "rounded"

require("tokyonight").setup({
  style = "night",
})
vim.cmd.colorscheme("tokyonight-night")

-- file name bar above every split (FileBar* groups, see plugins/ui.lua)
-- same colors as the tmux bar: accent for the window you're in, a dimmer block for the rest
local bar_colors = {
  WinBar = { bg = "#1a1b26" },
  WinBarNC = { bg = "#1a1b26" },
  FileBarCurrent = { fg = "#1a1b26", bg = "#7aa2f7", bold = true },
  FileBarOther = { fg = "#737aa2", bg = "#292e42" },
  FileBarModifiedCurrent = { fg = "#1a1b26", bg = "#e0af68", bold = true },
  FileBarModifiedOther = { fg = "#e0af68", bg = "#292e42" },
}
for name, val in pairs(bar_colors) do
  vim.api.nvim_set_hl(0, name, val)
end
