-- Sidebar of every live Claude Code session with its status; <CR> opens a detail tab
-- where a pending question can be answered.
--   <leader>as  toggle the sessions sidebar
return {
  {
    name = "claude-board",
    dir = vim.fn.stdpath("config") .. "/lua/claude_board",
    lazy = true,
    keys = {
      {
        "<leader>as",
        function()
          require("claude_board").toggle()
        end,
        desc = "Claude sessions board",
      },
    },
  },
}
