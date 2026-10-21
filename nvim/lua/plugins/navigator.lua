-- alt+hjkl and ctrl+hjkl move between nvim splits AND tmux panes
return {
  "christoomey/vim-tmux-navigator",
  init = function()
    vim.g.tmux_navigator_no_mappings = 1 -- no default ctrl maps, we use alt
    vim.g.tmux_navigator_no_wrap = 1 -- stop at the edge, don't jump to the pane on the other side
  end,
  keys = {
    { "<M-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "go left" },
    { "<M-j>", "<cmd>TmuxNavigateDown<cr>", desc = "go down" },
    { "<M-k>", "<cmd>TmuxNavigateUp<cr>", desc = "go up" },
    { "<M-l>", "<cmd>TmuxNavigateRight<cr>", desc = "go right" },
    -- ctrl does the same as alt
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "go left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "go down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "go up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "go right" },
  },
}
