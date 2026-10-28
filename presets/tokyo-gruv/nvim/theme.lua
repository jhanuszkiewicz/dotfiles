-- nvim colors - tokyo-gruv preset (hswi swaps this file, see presets/files.txt)
-- gruvbox dark, warm graphite #2a2522 background - same as the terminal

-- rounded corners on floating windows, like the rest of this preset
vim.o.winborder = "rounded"
vim.o.background = "dark"

require("gruvbox").setup({
  contrast = "",
  -- warm graphite bg instead of gruvbox's #282828 (matches kitty, tmux, sketchybar)
  palette_overrides = {
    dark0 = "#2a2522",
  },
})
vim.cmd.colorscheme("gruvbox")

-- file name bar above every split (FileBar* groups, see plugins/ui.lua)
-- same colors as the tmux bar: accent for the window you're in, a dimmer block for the rest
local bar_colors = {
  WinBar = { bg = "#2a2522" },
  WinBarNC = { bg = "#2a2522" },
  FileBarCurrent = { fg = "#ebdbb2", bg = "#8f5e3b", bold = true },
  FileBarOther = { fg = "#a89984", bg = "#3c3836" },
  FileBarModifiedCurrent = { fg = "#ebdbb2", bg = "#fabd2f", bold = true },
  FileBarModifiedOther = { fg = "#fabd2f", bg = "#3c3836" },
}
for name, val in pairs(bar_colors) do
  vim.api.nvim_set_hl(0, name, val)
end
