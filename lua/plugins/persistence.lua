-- LazyVim already saves a session per-directory via persistence.nvim.
-- This override adds AUTO-RESTORE: reopening bare `nvim` in a directory
-- brings back the buffers/windows/layout from last time.
--
-- Guarded so it only fires for a plain `nvim` with no file args and no stdin
-- pipe -- `nvim file.txt`, `nvim .`, and `cmd | nvim -` are left untouched.
return {
  "folke/persistence.nvim",
  opts = {},
  init = function()
    local group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true })

    -- Detect `... | nvim -` so we don't clobber piped input with a session.
    vim.api.nvim_create_autocmd("StdinReadPre", {
      group = group,
      callback = function()
        vim.g.started_with_stdin = true
      end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true,
      callback = function()
        if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
          require("persistence").load()
        end
      end,
    })
  end,
}
