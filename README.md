# nvim.tom

A personal Neovim configuration built incrementally from scratch.

## Philosophy

Add plugins only when there is a concrete reason to. Start minimal, stay minimal. Each addition should solve a specific problem — not pre-empt a hypothetical future one.

The config is organised so that adding a new capability means dropping one new file into `lua/plugins/`. Nothing else needs to change.

## Structure

```
init.lua                    -- sets leader keys, loads config modules
lua/
  config/
    options.lua             -- vim options
    lazy.lua                -- lazy.nvim bootstrap + plugin discovery
  plugins/
    lsp.lua                 -- LSP stack (mason, nvim-lspconfig, lua_ls)
    oil.lua                 -- file explorer
docs/
  design.md                 -- design decisions and rationale
```

## Plugins

| Plugin | Purpose |
|--------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | LSP server installer |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Bridges Mason and nvim-lspconfig |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server configurations |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | File explorer as an editable buffer |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless navigation between vim splits and tmux panes |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, buffers, LSP symbols |
| [telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | Native fzf sorter for telescope (faster matching) |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Lua utility library (telescope dependency) |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | Sidebar file tree explorer |

## LSP

Uses Neovim 0.11's native `vim.lsp.config()` / `vim.lsp.enable()` API. Currently configured servers:

- `lua_ls` — Lua, with full Neovim runtime awareness

To add a server: add its Mason package to `ensure_installed` in `lua/plugins/lsp.lua`, then call `vim.lsp.enable('server_name')`.

## Usage

Launched via `NVIM_APPNAME=nvim.tom` to keep all data isolated from other configs:

```bash
alias vimt='NVIM_APPNAME=nvim.tom nvim'
alias vt='vimt'
```

Plugin and Mason data lives in `~/.local/share/nvim.tom/`.

## Key bindings

Leader is `<Space>`.

### LSP (active when a server is attached)

| Key | Action |
|-----|--------|
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | References |
| `gi` | Implementation |
| `gy` | Type definition |
| `<C-k>` | Signature help |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>d` | Show diagnostic float |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>q` | Diagnostics to quickfix |

### Telescope

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (requires ripgrep) |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | LSP document symbols |
| `<leader>/` | Fuzzy find in current buffer |

### File tree (nvim-tree)

| Key | Action |
|-----|--------|
| `<C-n>` | Toggle file tree |
| `<leader>E` | Reveal current file in tree |
| `g?` | Show all tree keymaps (inside tree) |

### Navigation

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Move left/down/up/right across Neovim splits and tmux panes |
| `<C-\>` | Jump to previous split/pane |

### File explorer (oil.nvim)

| Key | Action |
|-----|--------|
| `-` | Open parent directory |
| `<CR>` | Open file or directory |
| `-` | Go up to parent (inside oil) |
| `g.` | Toggle hidden files |
| `g?` | Show all keymaps |
