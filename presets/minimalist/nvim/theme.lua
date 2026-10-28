-- nvim colors - minimalist preset (hswi swaps this file, see presets/files.txt)
-- gruvbox dark, same #282828 background as the terminal

-- square corners like the rest of this preset
vim.o.winborder = "single"
vim.o.background = "dark"

require("gruvbox").setup({
  contrast = "", -- "" = #282828, "hard" = darker
  italic = { strings = false, comments = true, operators = false, folds = false, emphasis = true },
  bold = false,
})
vim.cmd.colorscheme("gruvbox")

-- file name bar above every split (FileBar* groups, see plugins/ui.lua)
-- same colors as the tmux bar: accent for the window you're in, a dimmer block for the rest
local bar_colors = {
  WinBar = { bg = "#282828" },
  WinBarNC = { bg = "#282828" },
  FileBarCurrent = { fg = "#ebdbb2", bg = "#8ec07c", bold = true },
  FileBarOther = { fg = "#a89984", bg = "#3c3836" },
  FileBarModifiedCurrent = { fg = "#ebdbb2", bg = "#fabd2f", bold = true },
  FileBarModifiedOther = { fg = "#fabd2f", bg = "#3c3836" },
}
for name, val in pairs(bar_colors) do
  vim.api.nvim_set_hl(0, name, val)
end
