-- Replacement for openai.chatgpt (multi-provider AI chat/inline assist).
-- CodeCompanion uses the OpenAI adapter by default; set OPENAI_API_KEY in your
-- environment. (Claude work continues to go through claudecode.nvim.)
-- Usage: :CodeCompanionChat  /  :CodeCompanionActions  /  :CodeCompanion
return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = { adapter = "openai" },
        inline = { adapter = "openai" },
      },
    },
  },
}
