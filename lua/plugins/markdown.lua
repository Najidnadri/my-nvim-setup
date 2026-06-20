-- Disable markdownlint diagnostics (too noisy, mostly cosmetic).
-- Keeps marksman LSP + treesitter highlighting; only removes the linter.
return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
      return opts
    end,
  },
}
