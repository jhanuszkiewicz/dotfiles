-- nvim-tree options, kept here so <leader>tg can change them and set the tree up again
local tree_opts

-- git status signs in the tree (off by default, <leader>tg turns them on/off)
local function toggle_tree_git()
  tree_opts.git.enable = not tree_opts.git.enable
  local api = require("nvim-tree.api")
  local was_open = api.tree.is_visible()
  local in_tree = vim.bo.filetype == "NvimTree"
  local win = vim.api.nvim_get_current_win()
  require("nvim-tree").setup(tree_opts) -- calling setup again rebuilds the tree
  if was_open then
    api.tree.open()
    -- open() jumps into the tree, go back if you were in the code
    if not in_tree and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end
  print("git signs in tree: " .. (tree_opts.git.enable and "on" or "off"))
end

return {
  -- mini.nvim = a bunch of small modules in one plugin
  {
    "nvim-mini/mini.nvim",
    lazy = false,
    priority = 900, -- right after the colors, other plugins want the icons
    config = function()
      -- icons (ghostty has nerd font symbols built in, so they work even with Tamzen)
      require("mini.icons").setup()
      MiniIcons.mock_nvim_web_devicons() -- plugins asking for nvim-web-devicons get mini.icons

      -- statusline, takes colors from the colorscheme
      require("mini.statusline").setup()
      -- mode in caps: NORMAL, INSERT, VISUAL, V-LINE, V-BLOCK...
      local mode_section = MiniStatusline.section_mode
      MiniStatusline.section_mode = function(args)
        local mode, mode_hl = mode_section(args)
        return mode:upper(), mode_hl
      end

      -- file name above every split (winbar) instead of one tab line for the whole nvim
      -- the window you're in gets the accent color, like the active tmux window
      -- (colors: FileBar* groups in theme.lua, so every preset has its own)
      function _G.file_bar()
        local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        name = name:gsub("%%", "%%%%") -- a % in the name would break the bar
        local group = "FileBarOther"
        if win == vim.api.nvim_get_current_win() then
          group = "FileBarCurrent"
        end
        if vim.bo[buf].modified then
          group = group:gsub("FileBar", "FileBarModified")
        end
        return "%#" .. group .. "# " .. name .. " %*"
      end
      -- only for real files: no bar above the tree, terminal, help, oil...
      local function set_file_bar()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
          vim.wo.winbar = "%!v:lua.file_bar()" -- %! = g:statusline_winid tells which window is drawn
        else
          vim.wo.winbar = ""
        end
      end
      vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost", "FileType" }, {
        group = vim.api.nvim_create_augroup("file_bar", { clear = true }),
        callback = set_file_bar,
      })
      vim.o.showtabline = 0

      -- auto close brackets and quotes
      require("mini.pairs").setup()

      -- surround: sa = add, sd = delete, sr = replace  (e.g. saiw" wraps a word in quotes)
      require("mini.surround").setup()

      -- better text objects: va( vi" vaf (function) vac (class) ...
      require("mini.ai").setup()
    end,
  },

  -- popup with available keys after you press leader (or g, z, [ ...)
  {
    "folke/which-key.nvim",
    lazy = false,
    config = function()
      local wk = require("which-key")
      wk.setup({
        preset = "helix",
        delay = 300,
      })
      wk.add({
        { "<leader>b", group = "buffers" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>s", group = "splits" },
        { "<leader>t", group = "toggles" },
        { "gr", group = "lsp" },
      })
    end,
  },

  -- git changes next to line numbers
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      local gs = require("gitsigns")
      gs.setup({
        on_attach = function(buf)
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = buf, desc = desc })
          end
          map("]h", function() gs.nav_hunk("next") end, "next git change")
          map("[h", function() gs.nav_hunk("prev") end, "prev git change")
          map("<leader>gp", gs.preview_hunk, "preview change")
          map("<leader>gr", gs.reset_hunk, "undo change")
          map("<leader>gb", gs.blame_line, "blame line")
          map("<leader>gd", gs.diffthis, "diff file")
        end,
      })
    end,
  },

  -- "clangd indexing..." in the corner
  { "j-hui/fidget.nvim", lazy = false, opts = {} },

  -- TODO: / FIXME: / NOTE: get colored
  { "folke/todo-comments.nvim", lazy = false, opts = { signs = false } },

  -- file tree on the side, <leader>n opens / closes it
  -- loads only when you first use it (keys / cmd)
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    keys = {
      { "<leader>n", "<cmd>NvimTreeToggle<cr>", desc = "file tree" },
      { "<leader>N", "<cmd>NvimTreeFindFile<cr>", desc = "show current file in tree" },
      { "<leader>tg", toggle_tree_git, desc = "git signs in tree" },
    },
    opts = {
      -- my keys inside the tree (all the default ones still work, g? lists them)
      on_attach = function(buf)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(buf)

        local function map(key, fn, desc)
          vim.keymap.set("n", key, fn, { buffer = buf, desc = "tree: " .. desc, nowait = true })
        end
        map("l", api.node.open.edit, "open folder / file (in place)")

        -- enter: a file opens in a vsplit next to the code, a folder expands
        -- the cursor stays in the tree, so you can open a few files in a row
        local function open_in_vsplit()
          local node = api.tree.get_node_under_cursor()
          if node == nil or node.type ~= "file" then
            api.node.open.edit()
            return
          end
          local tree_win = vim.api.nvim_get_current_win()
          -- if the file is already open in a window, don't open it again
          -- and if there is only an empty window (fresh nvim), open it there without a split
          local empty_win = nil
          local code_wins = 0
          for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local b = vim.api.nvim_win_get_buf(w)
            if vim.bo[b].filetype ~= "NvimTree" and vim.api.nvim_win_get_config(w).relative == "" then
              code_wins = code_wins + 1
              if vim.api.nvim_buf_get_name(b) == node.absolute_path then
                return
              end
              if vim.api.nvim_buf_get_name(b) == "" and not vim.bo[b].modified then
                empty_win = w
              end
            end
          end
          if code_wins == 0 or (code_wins == 1 and empty_win ~= nil) then
            api.node.open.edit()
          else
            api.node.open.vertical()
          end
          -- back to the tree
          if vim.api.nvim_win_is_valid(tree_win) then
            vim.api.nvim_set_current_win(tree_win)
          end
        end
        map("<CR>", open_in_vsplit, "open file in vsplit")
        map("o", open_in_vsplit, "open file in vsplit")
        -- new root -> jump to the top of the list, otherwise the cursor can stay at the bottom
        local function root_here()
          api.tree.change_root_to_node()
          vim.schedule(function()
            if vim.bo.filetype == "NvimTree" then
              local last = vim.api.nvim_buf_line_count(0)
              if last >= 2 then
                vim.api.nvim_win_set_cursor(0, { 2, 0 })
              else
                vim.api.nvim_win_set_cursor(0, { 1, 0 })
              end
            end
          end)
        end
        map(".", root_here, "make this folder the root")
        map("<BS>", api.tree.change_root_to_parent, "root one folder up")
      end,

      -- `nvim .` and `-` still open oil, the tree is only for looking around
      disable_netrw = false,
      hijack_netrw = false,
      hijack_directories = { enable = false },
      -- signcolumn off: no empty 2-column gutter on the left of the tree
      view = { width = 30, cursorline = true, signcolumn = "no" }, -- whole line highlighted
      hijack_cursor = true, -- cursor sticks to the start of the name
      renderer = {
        group_empty = true, -- src/main/java in one line instead of 3
        icons = {
          glyphs = {
            -- empty folders get the same icon as in eza
            folder = { empty = "\u{f115}", empty_open = "\u{f115}" },
          },
        },
      },
      filters = { dotfiles = false }, -- show hidden files
      update_focused_file = { enable = true }, -- highlight the file you're in
      git = { enable = false }, -- no git signs, <leader>tg shows them
    },
    config = function(_, opts)
      tree_opts = opts
      require("nvim-tree").setup(opts)

      -- highlighted bar on the current line in the tree
      -- the cursor stays visible so the ghostty cursor trail has somewhere to go
      -- (re-applied after a colorscheme reload, e.g. hswi)
      local function tree_cursorline()
        vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { link = "Visual" })
      end
      tree_cursorline()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("tree_cursor", { clear = true }),
        callback = tree_cursorline,
      })
    end,
  },
}
