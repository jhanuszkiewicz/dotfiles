-- colorschemes, theme.lua picks which one is used
-- lazy = false + priority = they're loaded first, before everything else
return {
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
}
