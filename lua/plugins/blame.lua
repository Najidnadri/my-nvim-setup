-- Full-window git blame (GitLens / `git blame` style) in a side panel.
-- gitsigns gives you single-line inline blame (<leader>gb); this shows the
-- whole file's blame at once, with commit details on demand.
--   <leader>gv  toggle blame window  (then <CR> on a line for the commit)
return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    keys = {
      { "<leader>gv", "<cmd>BlameToggle<cr>", desc = "Git blame (view)" },
    },
    opts = {
      date_format = "%Y-%m-%d",
      merge_consecutive = false,
      max_summary_width = 30,
    },
  },
}
