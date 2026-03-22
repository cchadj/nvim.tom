# nvim.tom — Claude Code Context

## What this is

A personal Neovim configuration built incrementally from scratch. Started with Lua LSP support so the config itself can be written with full language intelligence. New capabilities are added one plugin file at a time.

Launched with `NVIM_APPNAME=nvim.tom` (alias: `vimt` / `vt`).

## File structure

```
init.lua                    -- entry point: sets leader keys, loads config modules
lua/
  config/
    options.lua             -- vim.opt settings
    lazy.lua                -- lazy.nvim bootstrap + plugin discovery
  plugins/
    lsp.lua                 -- mason, mason-lspconfig, nvim-lspconfig, lua_ls
    oil.lua                 -- file explorer (stevearc/oil.nvim)
    vim-tmux-navigator.lua  -- seamless vim/tmux split navigation
    telescope.lua           -- fuzzy finder (files, grep, buffers, LSP symbols)
    nvim-tree.lua           -- sidebar file tree (nvim-tree/nvim-tree.lua)
    clangd-extensions.lua   -- C++ extras: inlay hints, AST, header/source switch
    completion.lua          -- nvim-cmp + LuaSnip autocomplete
    treesitter.lua          -- nvim-treesitter syntax highlighting + indent
    formatting.lua          -- conform.nvim, autoformat on save (clang-format)
    linting.lua             -- nvim-lint framework (C++ linting via clangd)
    toggleterm.lua          -- terminal + C++ compile/run keymaps (F5/F6/F9)
templates/
  cp.cpp                    -- competitive programming boilerplate
docs/
  design.md                 -- human-readable design decisions log
```

## Extending the config

**Adding a plugin:** drop a new `.lua` file in `lua/plugins/` returning a lazy spec table. It is auto-discovered.

**Adding an LSP server:**
1. Add Mason package name to `ensure_installed` in `lua/plugins/lsp.lua`
2. Optionally add `vim.lsp.config('server_name', { ... })` for custom settings
3. Add `vim.lsp.enable('server_name')`

## Key conventions

- **Neovim 0.11 LSP API** — use `vim.lsp.config()` / `vim.lsp.enable()`, not the older per-server `require('lspconfig').server.setup()` pattern
- **`lazy = false`** on LSP infrastructure plugins (mason, mason-lspconfig, nvim-lspconfig) — they must be ready before the first buffer opens
- **`automatic_enable = false`** in mason-lspconfig — only servers with an explicit `vim.lsp.enable()` call are active
- **LSP keymaps in `LspAttach`** — keymaps are buffer-local and only registered when an LSP client attaches, so they never leak into non-LSP buffers
- **`(vim.uv or vim.loop)`** — use this pattern for fs operations, not bare `vim.uv`, to keep compatibility across Neovim versions

## Shell aliases

```bash
alias vimt='NVIM_APPNAME=nvim.tom nvim'
alias vt='vimt'
```

Defined in `~/.bashrc` alongside `vimk`/`vk` (nvim-kickstart) and `viml`/`vl` (nvim-lazy).
All configs are fully isolated — plugins and Mason data go to `~/.local/share/nvim.tom/`.
