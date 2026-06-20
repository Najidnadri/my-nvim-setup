-- Vitest adapter for the SvelteKit frontends + gridstack_wrapper.
-- (Go is already covered by neotest-golang from the LazyVim go extra.)
-- Use :Neotest summary / run-nearest from any *.test.ts / *.spec.ts file.
return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "marilari88/neotest-vitest" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, require("neotest-vitest"))
    end,
  },
}
