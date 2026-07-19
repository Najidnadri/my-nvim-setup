return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",

    dependencies = {
      "nvim-lua/plenary.nvim",

      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },

      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },

    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
            -- Lines the previewer scrolls per <C-d>/<C-u> (default is a half page)
            scroll_speed = 5,
          },
          mappings = {
            i = {
              ["<Esc>"] = actions.close,
            },
          },
        },

        pickers = {
          find_files = {
            hidden = true,
          },
        },

        extensions = {
          ["ui-select"] = require("telescope.themes").get_dropdown({}),

          file_browser = {
            theme = "dropdown",
            hijack_netrw = true,
            grouped = true,
            hidden = true,
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
      pcall(telescope.load_extension, "file_browser")
    end,

    keys = {
      -- FILES
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Recent files",
      },

      -- NOTE: LSP peek/jump keymaps (gd/gr/gi/gt and gD/gR/gI/gT) live in
      -- plugins/extra-lsp.lua as buffer-local LSP keys, so they properly
      -- override LazyVim's defaults instead of being shadowed by them.

      -- DIAGNOSTICS
      {
        "<leader>fd",
        function()
          require("telescope.builtin").diagnostics()
        end,
        desc = "Diagnostics",
      },
    },
  },
}
