require("config.options")
require("config.keymaps")
require("config.autocmds")

-- plugins: lazy.nvim loads every file in lua/plugins/
require("config.lazy")

-- colors come from theme.lua, which hswi swaps together with the rest of the preset
dofile(vim.fn.stdpath("config") .. "/theme.lua")
