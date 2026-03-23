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
    keymaps.lua             -- global keymaps (comment toggle, terminal escape)
    lazy.lua                -- lazy.nvim bootstrap + plugin discovery
  plugins/
    lsp.lua                 -- mason, mason-lspconfig, nvim-lspconfig
    oil.lua                 -- file explorer as editable buffer
    vim-tmux-navigator.lua  -- seamless vim/tmux split navigation
    telescope.lua           -- fuzzy finder (files, grep, buffers, LSP symbols)
    nvim-tree.lua           -- sidebar file tree
    clangd-extensions.lua   -- C++ extras: inlay hints, AST, header/source switch
    completion.lua          -- nvim-cmp + LuaSnip autocomplete
    treesitter.lua          -- syntax highlighting via nvim-treesitter
    formatting.lua          -- conform.nvim, autoformat on save
    linting.lua             -- nvim-lint framework
    toggleterm.lua          -- terminal + C++ compile/run keymaps
    colorscheme.lua         -- catppuccin (mocha)
templates/
  cp.cpp                    -- competitive programming boilerplate
docs/
  design.md                 -- design decisions and rationale
```

## Setup

### 1. Prerequisites

- **Neovim 0.11+**
- **Node.js / npm** — required by ts_ls, tree-sitter-cli, prettier
- **Git**

### 2. Clone

```bash
git clone https://github.com/cchadj/nvim.tom ~/.config/nvim.tom
```

### 3. Shell aliases

Add to `~/.bashrc`:

```bash
alias vimt='NVIM_APPNAME=nvim.tom nvim'
alias vt='vimt'
```

### 4. System dependencies

```bash
# C++ compiler (C++23 + std::print support)
sudo apt install g++-14

# C++ formatting and linting
sudo apt install clang-format

# Telescope live grep
sudo apt install ripgrep

# tree-sitter CLI (required by nvim-treesitter v1.x to compile parsers)
npm install -g tree-sitter-cli

# Prettier (web formatting; also works per-project via node_modules)
npm install -g prettier
```

### 5. clangd C++23 default

Create `~/.config/clangd/config.yaml` so clangd defaults to C++23 for
files without a `compile_commands.json`:

```yaml
CompileFlags:
  Add: [-std=c++23]
```

### 6. First launch

```bash
vimt
```

On first launch lazy.nvim bootstraps itself and installs all plugins.
Mason then installs the LSP servers (`lua_ls`, `clangd`, `ts_ls`, `eslint`)
automatically. Run `:TSUpdate` to compile treesitter parsers.

---

## Plugins

| Plugin | Purpose |
|--------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [catppuccin](https://github.com/catppuccin/nvim) | Colorscheme (mocha) |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | LSP/tool installer |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Bridges Mason and nvim-lspconfig |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server configurations |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | File explorer as an editable buffer |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless navigation between vim splits and tmux panes |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, buffers, LSP symbols |
| [telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | Native fzf sorter for telescope |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | Sidebar file tree explorer |
| [clangd_extensions.nvim](https://github.com/p00f/clangd_extensions.nvim) | C++ extras: inlay hints, AST viewer, header/source switching |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Completion engine |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Treesitter syntax highlighting |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Autoformat on save |
| [nvim-lint](https://github.com/mfussenegger/nvim-lint) | Linting framework |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Embedded terminal + C++ compile/run keymaps |

## LSP servers

Uses Neovim 0.11's native `vim.lsp.config()` / `vim.lsp.enable()` API.

| Server | Languages |
|--------|-----------|
| `lua_ls` | Lua (Neovim runtime-aware) |
| `clangd` | C / C++ — background indexing, clang-tidy, autoimport, inlay hints |
| `ts_ls` | TypeScript / JavaScript / JSX / TSX / Node.js — inlay hints enabled |
| `eslint` | TypeScript / JavaScript linting |

To add a server: add its Mason package to `ensure_installed` in `lua/plugins/lsp.lua`, then call `vim.lsp.enable('server_name')`.

## Formatting

Handled by conform.nvim, runs on save.

| Formatter | Filetypes |
|-----------|-----------|
| `clang-format` | C, C++ — uses `~/.clang-format` (Allman braces, Google base style) |
| `prettier` | JS, TS, JSX, TSX, HTML, CSS, JSON, YAML |

## Key bindings

Leader is `<Space>`.

### LSP (active when a server is attached)

| Key | Action |
|-----|--------|
| `K` | Hover documentation (press twice to enter float and scroll) |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | References |
| `gi` | Implementation |
| `gy` | Type definition |
| `<C-k>` | Signature help |
| `<leader>rn` / `<S-F6>` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>ih` | Toggle inlay hints |
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
| `<C-h/j/k/l>` | Move across Neovim splits and tmux panes |
| `<C-\>` | Jump to previous split/pane |

### Terminal

| Key | Action |
|-----|--------|
| `<leader>tt` | Toggle terminal (horizontal split, 15 rows) |
| `<leader>ts` | Send current line / selection to terminal |
| `<Esc>` | Exit terminal mode back to normal mode |

### Competitive C++ (active in C/C++ buffers)

| Key | Action |
|-----|--------|
| `<F5>` | Write, compile, run — focus stays in editor |
| `<F6>` | Write, compile, run with `< input.txt` |
| `<F7>` | Write, compile, run with `< <exec-name>.txt` |
| `<F9>` | Write, compile only — errors go to quickfix (`[q` / `]q`) |
| `<leader>cp` | Create new problem file from `templates/cp.cpp` |

Compiler: `g++-14 -std=c++23 -O2 -Wall -Wextra -Wconversion -g`

### Completion

| Key | Action |
|-----|--------|
| `<C-Space>` | Trigger completion |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<CR>` | Confirm selection |
| `<Tab>` / `<S-Tab>` | Next/previous item, or jump snippet placeholder |
| `<C-d>` / `<C-f>` | Scroll docs up / down |

### C++ / clangd (active in C and C++ buffers)

| Key | Action |
|-----|--------|
| `<A-o>` | Switch between header and source file |
| `<leader>cA` | Clang AST viewer |
| `<leader>ci` | Symbol info |
| `<leader>cm` | clangd memory usage |
| `<leader>ch` | Toggle inlay hints |

### File explorer (oil.nvim)

| Key | Action |
|-----|--------|
| `-` | Open parent directory |
| `<CR>` | Open file or directory |
| `g.` | Toggle hidden files |
| `g?` | Show all keymaps |

### Editing

| Key | Action |
|-----|--------|
| `<C-/>` | Toggle comment (current line or selection) |
