-- Extra Tailwind v4 polish on top of the lang.tailwind extra (which provides
-- tailwindcss-language-server). Adds inline color hints, class sorting, and
-- conceal. Works across Svelte/HTML/TS.
return {
  {
    "luckasRanarison/tailwind-tools.nvim",
    name = "tailwind-tools",
    build = ":UpdateRemotePlugins",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "svelte", "html", "css", "javascript", "typescript", "vue" },
    opts = {
      document_color = { enabled = true, kind = "inline" },
      conceal = { enabled = false },
    },
  },
}
