-- basic options, :h 'option' explains each one

-- leader has to be set before any mapping that uses it
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

-- line numbers
o.number = true
o.relativenumber = true

-- indent: 4 spaces
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true
o.smartindent = true

-- search
o.ignorecase = true
o.smartcase = true -- case sensitive only when there's a capital letter
o.hlsearch = true
o.incsearch = true
o.inccommand = "split" -- live preview of :s/../../

-- look
o.termguicolors = true
o.signcolumn = "yes" -- always there so text doesn't jump when lsp/git signs show up
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.showmode = false -- the statusline shows the mode already
o.laststatus = 3 -- one statusline at the bottom, not one per split
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " } -- no ~ after the end of file
o.pumheight = 12

-- splits open right / below
o.splitright = true
o.splitbelow = true

-- yank / paste go through the macOS clipboard
o.clipboard = "unnamedplus"

-- files
o.undofile = true -- undo history survives closing the file
o.swapfile = false
o.confirm = true -- ask instead of failing on :q with unsaved changes

-- misc
o.mouse = "a"
o.updatetime = 250
o.timeoutlen = 400
o.ttimeoutlen = 10 -- esc leaves insert mode right away (the escape-code wait is 50 ms by default)
o.completeopt = { "menuone", "noselect", "popup" }
o.spelllang = { "en", "pl" }

-- plugins in perl/ruby/node/python - not using any, skip loading them
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- code folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
