local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("my_stuff", { clear = true })

-- flash what you just yanked
au("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- reopen a file where you left off
au("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- hswi swaps theme.lua - when you come back to nvim, load it again if it changed
local theme_file = vim.fn.stdpath("config") .. "/theme.lua"
local theme_time = vim.fn.getftime(theme_file)
au("FocusGained", {
  group = group,
  callback = function()
    local t = vim.fn.getftime(theme_file)
    if t ~= theme_time then
      theme_time = t
      dofile(theme_file)
    end
  end,
})

-- <leader>r = compile and run the current file in a split below
-- (for single file exercises, bigger projects need cmake/make)
local run_cmds = {
  cpp = "clang++ -std=c++20 -Wall -Wextra -g %s -o /tmp/nvim_run && /tmp/nvim_run",
  c = "clang -std=c17 -Wall -Wextra -g %s -o /tmp/nvim_run && /tmp/nvim_run",
  python = "python3 %s",
  lua = "lua %s",
  java = "java %s",
}

au("FileType", {
  group = group,
  pattern = vim.tbl_keys(run_cmds),
  callback = function(ev)
    vim.keymap.set("n", "<leader>r", function()
      vim.cmd("write")
      local file = vim.fn.shellescape(vim.fn.expand("%:p"))
      local cmd = string.format(run_cmds[vim.bo.filetype], file)
      vim.cmd("botright 15split | terminal " .. cmd)
      vim.cmd("startinsert")
    end, { buffer = ev.buf, desc = "compile & run" })
  end,
})

-- tmux bar: hidden while nvim is open in this tmux window (also with a shell pane next to it),
-- back when nvim quits; switching tmux windows is handled by a hook in tmux.conf
if vim.env.TMUX then
  local function tmux_bar(state)
    vim.system({ "tmux", "set", "status", state })
  end
  -- on startup hide it right away and wait for tmux, before nvim draws anything:
  -- hiding the bar resizes the pane, and doing it after the first draw made
  -- nvim redraw everything again (cursor jumping around on startup)
  if not vim.tbl_contains(vim.v.argv, "--headless") then
    vim.system({ "tmux", "set", "status", "off" }):wait()
  end
  au("VimResume", {
    group = group,
    callback = function() tmux_bar("off") end,
  })
  au({ "VimLeavePre", "VimSuspend" }, {
    group = group,
    callback = function() tmux_bar("on") end,
  })
end

-- cursorline --
au({ "WinEnter", "FocusGained" }, { callback = function() vim.wo.cursorline = true end })
au({ "WinLeave", "FocusLost" }, { callback = function() vim.wo.cursorline = false end })
