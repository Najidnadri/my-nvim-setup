-- Right-side scrollbar with overview markers (VSCode-style "overview ruler").
-- gitsigns already shows +/~/_ in the LEFT gutter; satellite mirrors those
-- hunks (and search/diagnostics/marks) down a scrollbar on the RIGHT edge.
return {
  {
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {
      current_only = false,
      winblend = 50,
      handlers = {
        gitsigns = {
          enable = true,
          signs = { add = "│", change = "│", delete = "-" },
        },
        search = { enable = true },
        diagnostic = { enable = true },
        cursor = { enable = true },
        marks = { enable = true },
      },
    },
  },
}
