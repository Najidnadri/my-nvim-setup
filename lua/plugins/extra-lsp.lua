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
        -- Buffer-local LSP keymaps, applied on attach. Defined here (not as
        -- global keymaps in telescope.lua) so they override LazyVim's default
        -- g* mappings instead of being shadowed by them. `has` gates each key
        -- to servers that actually support the method.
        ["*"] = {
          -- stylua: ignore
          keys = {
            -- Peek (Telescope, no auto-jump)
            { "gd", function() require("telescope.builtin").lsp_definitions({ jump_type = "never", trim_text = true }) end, desc = "Peek definitions", has = "definition" },
            { "gr", function() require("telescope.builtin").lsp_references({ jump_type = "never" }) end, desc = "Peek references", nowait = true },
            { "gi", function() require("telescope.builtin").lsp_implementations({ jump_type = "never" }) end, desc = "Peek implementations", has = "implementation" },
            { "gt", function() require("telescope.builtin").lsp_type_definitions({ jump_type = "never" }) end, desc = "Peek type definitions", has = "typeDefinition" },
            -- Direct jump (no Telescope)
            { "gD", vim.lsp.buf.definition, desc = "Go to definition (direct)", has = "definition" },
            { "gR", vim.lsp.buf.references, desc = "Go to references (direct)" },
            { "gI", vim.lsp.buf.implementation, desc = "Go to implementation (direct)", has = "implementation" },
            { "gT", vim.lsp.buf.type_definition, desc = "Go to type definition (direct)", has = "typeDefinition" },
          },
        },
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
