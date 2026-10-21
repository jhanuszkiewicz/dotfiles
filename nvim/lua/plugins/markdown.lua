-- markdown: rendered right in the buffer (headings, lists, checkboxes, tables, code blocks)
-- the line under the cursor shows the raw text, so you can still edit it
-- shortcuts below are read by the `keys` script (key, 3+ spaces, description):
--   <leader>mr   Toggle markdown rendering in the buffer
--   <leader>mp   Open the current file in frogmouth (tmux popup)

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
  opts = {},
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "toggle markdown render" },
    {
      "<leader>mp",
      function()
        -- frogmouth in a big tmux popup, q closes it and you're back in nvim
        vim.system({
          "tmux", "display-popup", "-E", "-w", "90%", "-h", "90%",
          "-d", vim.fn.expand("%:p:h"),
          "frogmouth", vim.fn.expand("%:p"),
        })
      end,
      ft = "markdown",
      desc = "preview in frogmouth",
    },
  },
}
