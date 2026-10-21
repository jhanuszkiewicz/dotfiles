-- general keymaps (plugin ones live next to the plugin setup)
-- leader = space, press it and wait - which-key shows what's available

local map = vim.keymap.set

-- esc clears search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- save / quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "quit window" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "quit all" })

-- moving between splits: ctrl+h/j/k/l and alt+h/j/k/l, both also go into tmux panes
-- (set in plugins/navigator.lua)

-- splits
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "split horizontal" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "close buffer" })
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "new empty buffer" })
map("n", "<leader>bv", "<cmd>vnew<cr>", { desc = "new empty buffer in vsplit" })

-- move selected lines up/down
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "move lines down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "move lines up" })

-- keep selection after indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- half page jumps keep the cursor in the middle
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- paste over a selection without losing what you yanked
map("x", "<leader>p", '"_dP', { desc = "paste keep register" })

-- diagnostics
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "show error" })

-- terminal: esc esc gets you out of insert mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "leave terminal mode" })

-- toggles
map("n", "<leader>ts", "<cmd>setlocal spell!<cr>", { desc = "spellcheck" })
map("n", "<leader>tw", "<cmd>setlocal wrap!<cr>", { desc = "line wrap" })
