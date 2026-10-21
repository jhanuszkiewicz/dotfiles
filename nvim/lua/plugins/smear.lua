-- smear cursor: the cursor leaves a short trail when it jumps (gg, G, ctrl+d, switching splits...)
return {
  "sphamba/smear-cursor.nvim",
  -- off: ghostty draws the trail now (ghostty/shaders/cursor_warp.glsl), smoother and also between tmux panes
  enabled = false,
  event = "VeryLazy",
  opts = {
    -- false = trail made of regular block characters (with true the font has to support
    -- the "legacy computing" symbols, cascadia doesn't, so the trail was drawn as boxes)
    legacy_computing_symbols_support = false,
    -- no trail in the tree, the cursor is hidden there anyway
    filetypes_disabled = { "NvimTree" },
  },
}
