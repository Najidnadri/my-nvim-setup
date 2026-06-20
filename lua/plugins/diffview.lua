-- Side-by-side diff + branch/PR review across your many repos.
-- Complements gh.nvim (you already have it) for reviewing changes locally.
--   :DiffviewOpen [rev]   :DiffviewFileHistory [file]
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview (open)" },
      { "<leader>gD", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview (file history)" },
    },
    opts = {},
  },
}
