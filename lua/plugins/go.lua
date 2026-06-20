-- ray-x/go.nvim — adds codegen/refactor commands on top of LazyVim's go extra
-- (which already owns gopls, neotest-golang, nvim-dap-go, gomodifytags).
-- Useful for the Ent + gqlgen Go backends:
--   :GoGenerate   run `go generate` (gqlgen / ent codegen)
--   :GoIfErr      insert `if err != nil { ... }`
--   :GoFillStruct / :GoFillSwitch
--   :GoImpl       generate interface method stubs
--   :GoAddTag / :GoRmTag   struct field tags
--   :GoTests      generate table-driven tests
-- lsp_cfg=false so we don't fight the go extra's gopls setup.
return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,
      lsp_keymaps = false,
      dap_debug = false, -- nvim-dap-go from the go extra handles this
      trouble = true,
    },
    config = function(_, opts)
      require("go").setup(opts)
    end,
  },
}
