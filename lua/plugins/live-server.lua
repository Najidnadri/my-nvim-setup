-- Replacement for ritwickdey.liveserver (VSCode "Live Server").
-- Requires the `live-server` npm CLI: npm install -g live-server
-- Usage: :LiveServerStart  /  :LiveServerStop
return {
  {
    "barrettruth/live-server.nvim",
    cmd = { "LiveServerStart", "LiveServerStop" },
    build = "npm install -g live-server",
    config = true,
  },
}
