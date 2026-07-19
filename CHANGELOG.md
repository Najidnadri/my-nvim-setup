# Changelog

All notable changes to this Neovim configuration are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Telescope** as the fuzzy finder, with `fzf-native` (native sorting),
  `ui-select` (routes `vim.ui.select` through Telescope), and `file-browser`
  (netrw replacement). Keymaps under `<leader>f` for files, live grep, buffers,
  recent files, and diagnostics; `<Esc>` closes the picker from insert mode and
  hidden files are shown.
- **LSP peek/jump keymaps** as buffer-local LSP keys in `extra-lsp.lua` so they
  override LazyVim's defaults instead of being shadowed. `gd`/`gr`/`gi`/`gt`
  peek via Telescope without auto-jumping; `gD`/`gR`/`gI`/`gT` jump directly.
- **satellite.nvim** — VSCode-style right-side scrollbar mirroring gitsigns
  hunks, plus search, diagnostic, cursor, and mark markers.
- **persistence.nvim auto-restore** — reopening a bare `nvim` in a directory
  restores the last session's buffers/windows/layout, guarded so `nvim file`,
  `nvim .`, and piped stdin are left untouched.
- **twoslash-queries.nvim** — inline virtual-text type expansion for TS/JS via
  `//   ^?`, attached to the TypeScript LSP. `<leader>ci` inspects, `<leader>cI`
  clears.
- **Custom LuaSnip snippets** loaded from `~/.config/nvim/snippets`, including
  `prettify` and `prettifydeep` for inspecting flattened TypeScript types.
