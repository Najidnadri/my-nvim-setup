-- LSP servers + treesitter parsers for languages that have no dedicated
-- LazyVim extra. Mirrors these Cursor extensions:
--   ecmel.vscode-html-css      -> html, cssls, emmet
--   graphql.vscode-graphql(+syntax) -> graphql LSP + treesitter
--   antfu.unocss               -> unocss language server
--   zxh404.vscode-proto3       -> proto treesitter + buf LSP
-- mason-lspconfig auto-installs any of these servers it can resolve; ones it
-- can't will simply stay inactive (no error), see :Mason / :checkhealth lsp.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "html",
        "css",
        "graphql",
        "proto",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
        emmet_language_server = {},
        graphql = {
          filetypes = { "graphql", "typescriptreact", "javascriptreact", "typescript", "javascript" },
        },
        unocss = {},
        buf_ls = {}, -- protobuf (buf); falls back gracefully if `buf` is absent
      },
    },
  },
}
