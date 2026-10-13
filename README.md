# 💤 my-nvim-setup

A personal Neovim configuration built on [LazyVim](https://github.com/LazyVim/LazyVim),
tuned for TypeScript/Svelte, Go, Python, Rust and CloudFormation work. See
[CHANGELOG.md](CHANGELOG.md) for what it adds on top of stock LazyVim.

## Requirements

Required:

- **Neovim ≥ 0.11** (built with LuaJIT)
- **git**
- A **[Nerd Font](https://www.nerdfonts.com/)** set as your terminal font
- A **C compiler** and **make** — for treesitter parsers and `telescope-fzf-native`
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** and **[fd](https://github.com/sharkdp/fd)** — for live grep and file finding
- **Node.js + npm** — many language servers are installed through it

Optional, per feature:

| Tool | Used by |
|------|---------|
| `lazygit`, `gitui` | `<leader>gg` git UIs |
| `gh` | GitHub PR/issue integration |
| `go` | Go extra and `go.nvim` (`:GoGenerate`, `:GoIfErr`, …) |
| `python3` + `pip` | `cfn-lint` and `cfn-lsp-extra` for CloudFormation templates |
| `live-server` (npm) | `:LiveServerStart` — installed automatically on first build |
| kitty terminal | Inline image rendering (snacks.nvim image module) |
| `OPENAI_API_KEY` env var | CodeCompanion AI chat (`:CodeCompanionChat`) |

On Debian/Ubuntu/Pop!_OS the core tools are:

```bash
sudo apt install git build-essential ripgrep fd-find nodejs npm
```

## Install

Clone the repo anywhere and run the install script:

```bash
git clone git@github.com:Najidnadri/my-nvim-setup.git ~/code/my-nvim-setup
cd ~/code/my-nvim-setup
./install.sh
```

`install.sh` symlinks the repo to `~/.config/nvim` (respecting
`$XDG_CONFIG_HOME`), so edits you make stay under version control. If a config
already exists there, it is moved to a timestamped backup
(`~/.config/nvim.bak.YYYYMMDDHHMMSS`) rather than deleted. Re-running it is
safe — it does nothing if the link is already in place.

Alternatively, clone straight into place and skip the script:

```bash
git clone git@github.com:Najidnadri/my-nvim-setup.git ~/.config/nvim
```

## First launch

```bash
nvim
```

On the first start lazy.nvim bootstraps itself and installs every plugin at the
versions pinned in `lazy-lock.json`. Then:

1. Wait for the install to finish, then restart Neovim.
2. Run `:Mason` to watch language servers, formatters and linters install
   (they install on demand as you open files of each language).
3. Run `:checkhealth` to spot missing external tools.

Optional CloudFormation support needs the Python tools:

```bash
pip install cfn-lint cfn-lsp-extra
```

## Updating

```bash
git pull           # pull config changes
nvim               # then inside Neovim:
:Lazy restore      # sync plugins to the versions in lazy-lock.json
```

Use `:Lazy update` instead to move plugins to their latest versions (this
rewrites `lazy-lock.json`; commit it if you want to keep the new pins).

## Uninstall

```bash
./install.sh uninstall
```

This removes the `~/.config/nvim` symlink (only if it points at this repo) and
moves Neovim's generated data, state and cache directories
(`~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`) to timestamped
backups. The repo itself is left untouched. Delete the `*.bak.*` directories
once you no longer need them.

## Layout

```
init.lua              entry point — loads config.lazy
lazyvim.json          enabled LazyVim extras
lazy-lock.json        pinned plugin versions
lua/config/           options, keymaps, autocmds, lazy.nvim bootstrap
lua/plugins/          one file per added or overridden plugin
snippets/             custom VSCode-style LuaSnip snippets
install.sh            install / uninstall script
```

Run `./install.sh --help` for the script's usage.
