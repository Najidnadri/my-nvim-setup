-- Load custom VSCode-style snippets from ~/.config/nvim/snippets into LuaSnip.
-- LuaSnip's default lazy_load() only scans rtp roots, not this subdir, so the
-- path is registered explicitly. See snippets/package.json for the manifest.
return {
  "L3MON4D3/LuaSnip",
  opts = function()
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
    })
  end,
}
