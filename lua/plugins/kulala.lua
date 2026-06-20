-- HTTP / GraphQL / gRPC / WebSocket client (.http files, JetBrains spec).
-- Replaces Postman/Insomnia for testing the gqlgen GraphQL APIs, graphql-ws
-- subscriptions, and REST endpoints across the backends. Supports AWS SigV4.
-- Open any .http file and use the keymaps below.
return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>R", "", desc = "+Rest/HTTP", ft = { "http", "rest" } },
      { "<leader>Rs", function() require("kulala").run() end, desc = "Send request", ft = { "http", "rest" } },
      { "<leader>Ra", function() require("kulala").run_all() end, desc = "Send all requests", ft = { "http", "rest" } },
      { "<leader>Rr", function() require("kulala").replay() end, desc = "Replay last request", ft = { "http", "rest" } },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "Toggle body/headers", ft = { "http", "rest" } },
      { "<leader>Rc", function() require("kulala").copy() end, desc = "Copy as cURL", ft = { "http", "rest" } },
      { "<leader>Rq", function() require("kulala").close() end, desc = "Close window", ft = { "http", "rest" } },
    },
    opts = {
      default_view = "body",
      default_env = "dev",
    },
  },
}
