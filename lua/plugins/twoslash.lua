-- Inline type expansion for TS/JS: put `//   ^?` under an expression and the
-- resolved type is rendered as virtual text. Complements `K` (hover) — useful
-- for watching a type as you edit. Attaches to vtsls (LazyVim's TS server).
return {
  "marilari88/twoslash-queries.nvim",
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  opts = {
    multi_line = true,
    is_enabled = true,
    highlight = "Comment",
  },
  keys = {
    { "<leader>ci", "<cmd>TwoslashQueriesInspect<cr>", desc = "Inspect type (twoslash)", ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" } },
    { "<leader>cI", "<cmd>TwoslashQueriesRemove<cr>", desc = "Remove twoslash queries", ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" } },
  },
  config = function(_, opts)
    require("twoslash-queries").setup(opts)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and vim.tbl_contains({ "vtsls", "ts_ls", "tsserver" }, client.name) then
          require("twoslash-queries").attach(client, args.buf)
        end
      end,
    })
  end,
}
