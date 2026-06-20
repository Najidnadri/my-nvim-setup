-- Highlights merge conflict markers and gives quick keymaps to resolve them.
-- Inside a conflict:
--   co  choose ours      ct  choose theirs
--   cb  choose both      c0  choose none
--   ]x / [x  jump to next / prev conflict
--   <leader>gx  list all conflicts in the quickfix
return {
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>gx", "<cmd>GitConflictListQf<cr>", desc = "List git conflicts (quickfix)" },
    },
    opts = {
      default_mappings = true,
      disable_diagnostics = false,
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
  },
}
