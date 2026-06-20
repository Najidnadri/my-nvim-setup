-- Magit-style git UI: stage/unstage hunks, commit, branch, rebase, push/pull
-- from a single buffer. Complements lazygit (<leader>gg) with a tighter,
-- in-editor staging+commit flow that integrates with diffview.nvim.
--   <leader>gn  open Neogit status
return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- you already have this; enables `d` to diff in Neogit
    },
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit (status)" },
      { "<leader>gN", "<cmd>Neogit commit<cr>", desc = "Neogit (commit)" },
    },
    opts = {
      integrations = { diffview = true },
      graph_style = "unicode",
    },
  },
}
