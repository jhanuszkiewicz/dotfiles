-- plugin manager: lazy.nvim
--
-- install = add a spec to some file in lua/plugins/ and restart nvim
-- :Lazy   = panel with all plugins (U update, X clean, S sync)
--
-- exact versions are saved in lazy-lock.json - commit that file

-- first start: download lazy.nvim itself
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("couldn't clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } }, -- every file in lua/plugins/ returns a list of plugins
  install = { colorscheme = { "gruvbox" } },
  checker = { enabled = false }, -- don't check for updates on every start
  change_detection = { notify = false },
})
