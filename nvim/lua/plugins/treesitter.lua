-- treesitter = better syntax colors and indent
-- parsers get compiled locally, needs `tree-sitter` (brew install tree-sitter-cli) and a C compiler
-- (the repo got archived in 2026 but still works fine on 0.12)

local langs = {
  "c", "cpp", "cmake", "make",
  "python", "java", "lua", "bash",
  "json", "yaml", "toml",
  "markdown", "markdown_inline",
  "vim", "vimdoc", "query", "regex", "diff", "gitcommit",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- the main branch doesn't support lazy loading
  build = ":TSUpdate", -- after install / update, update the parsers too
  config = function()
    -- only installs what's missing, runs in the background
    require("nvim-treesitter").install(langs)

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        -- pcall because not every filetype has a parser
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
