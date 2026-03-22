# nvim.tom — Design Decisions

A record of the choices made building this config, and why.

---

## Goals

- Build incrementally — never add a plugin until there's a concrete reason to
- Start with Lua LSP so the config files themselves have full language intelligence while being written
- Keep each concern in its own file; adding a new language or tool should mean dropping one new file, not editing existing ones
- Full isolation from other Neovim configs on the same machine

---

## Directory name and `NVIM_APPNAME`

The config lives at `~/.config/nvim.tom`, not the default `~/.config/nvim`.

Neovim uses the `NVIM_APPNAME` environment variable to select its config directory. Setting `NVIM_APPNAME=nvim.tom` redirects all path lookups:

| `stdpath` key | Default path | With `NVIM_APPNAME=nvim.tom` |
|---------------|-------------|-------------------------------|
| `config`      | `~/.config/nvim` | `~/.config/nvim.tom` |
| `data`        | `~/.local/share/nvim` | `~/.local/share/nvim.tom` |
| `cache`       | `~/.cache/nvim` | `~/.cache/nvim.tom` |

This means plugins, Mason-installed servers, and all runtime state are completely isolated from `nvim`, `nvim-kickstart`, and `nvim-lazy` configs on the same machine. No risk of version conflicts or cross-contamination.

Shell aliases in `~/.bashrc`:
```bash
alias vimt='NVIM_APPNAME=nvim.tom nvim'
alias vt='vimt'
```

---

## Plugin manager: lazy.nvim

**Why lazy.nvim:** it is the current standard in the Neovim ecosystem, has a clean structured setup API, and supports auto-discovery of plugin specs from a directory.

**Bootstrap pattern:** lazy.nvim bootstraps itself — on first launch it clones itself into `stdpath('data')/lazy/lazy.nvim` if not already present. No manual install step needed.

**`--branch=stable`:** pins the bootstrap clone to the stable branch rather than HEAD, avoiding accidental breakage from in-progress lazy.nvim changes.

**Error handling:** uses `vim.api.nvim_echo` with `ErrorMsg`/`WarningMsg` highlight groups and an interactive `vim.fn.getchar()` pause before `os.exit(1)`, so failures are visible rather than silently swallowed.

**`spec = { { import = 'plugins' } }`:** lazy.nvim auto-discovers every `.lua` file under `lua/plugins/` and merges the returned specs. Adding a new plugin means dropping a new file — no central registry to edit.

**`defaults = { lazy = true }`:** plugins are lazy-loaded by default. Any plugin that must be present at startup sets `lazy = false` explicitly.

**Disabled built-ins:** a small set of built-in Neovim plugins that are unused in this config are disabled at startup (`gzip`, `matchit`, `matchparen`, `netrwPlugin`, `tarPlugin`, `tohtml`, `tutor`, `zipPlugin`). This shaves a small amount off startup time and removes functionality we don't need.

**`checker = { enabled = false }`:** automatic update checks are off. Updates are done manually with `:Lazy update` when wanted.

---

## LSP stack

Three plugins work together:

```
Mason  →  mason-lspconfig  →  nvim-lspconfig  →  vim.lsp (built-in)
```

### mason.nvim

Installs and manages LSP servers, linters, and formatters as local binaries under `stdpath('data')/mason/`. Provides a UI (`:Mason`) for browsing and managing installed tools.

Uses the `mason-org/mason.nvim` repo (the project migrated from `williamboman/mason.nvim` to the `mason-org` GitHub organisation).

`lazy = false`: Mason must be initialised before mason-lspconfig can reference it.

### mason-lspconfig.nvim

Bridges Mason's package names with nvim-lspconfig's server names (they differ: Mason uses `lua-language-server`, lspconfig uses `lua_ls`).

`ensure_installed = { 'lua_ls' }`: Mason auto-installs lua-language-server on first launch if not present.

`automatic_enable = false`: By default, recent versions of mason-lspconfig will call `vim.lsp.enable()` for every server Mason has installed. Disabling this means only servers with an explicit `vim.lsp.enable()` call in the config are active — important for an incremental setup where adding a new server should be a deliberate choice.

### nvim-lspconfig

Provides the default configuration for each server — command to run, filetypes to attach to, root directory detection patterns. This is what allows `vim.lsp.config('lua_ls', { ... })` to only specify *overrides* rather than needing to specify everything.

### Neovim 0.11 LSP API

Neovim 0.11 introduced `vim.lsp.config()` and `vim.lsp.enable()` as a first-class configuration API, replacing the older pattern of calling `require('lspconfig').lua_ls.setup({ ... })` directly.

The new pattern:
```lua
vim.lsp.config('server_name', { overrides })   -- merge config on top of lspconfig defaults
vim.lsp.enable('server_name')                  -- activate for matching filetypes
```

Benefits: clearer separation between server defaults (owned by nvim-lspconfig) and project overrides (owned by your config). Also allows enabling/disabling servers without re-running setup.

---

## lua_ls configuration

lua_ls needs special treatment when used inside a Neovim config. Without it, the `vim` global is unknown, all `vim.*` API calls are flagged as errors, and the workspace library doesn't include Neovim's runtime files.

**`on_init` hook instead of static settings:** the Neovim runtime library (`vim.api.nvim_get_runtime_file('', true)`) returns hundreds of paths. Computing it at server init time (when the first Lua file opens) rather than at Neovim startup avoids paying that cost on every launch.

**`.luarc.json` escape hatch:** `on_init` checks for a `.luarc.json` or `.luarc.jsonc` in the workspace root before injecting Neovim-specific settings. If one exists, the hook returns early and defers to the project's own lua_ls config. This means the config works correctly for both Neovim config files *and* regular Lua projects that manage their own lua_ls setup.

**`checkThirdParty = false`:** suppresses lua_ls prompts asking "Detected unknown third-party library, do you want to configure?" — since we are providing the configuration explicitly, the prompt is redundant.

**`diagnostics.globals = { 'vim' }`:** belt-and-suspenders alongside the library path. Explicitly marks `vim` as a known global so diagnostics don't flag it as undefined even if library indexing is slow to complete.

**`hint.enable = true`:** enables inlay hints (Neovim 0.10+ supports rendering them). Shows type annotations inline, useful when reading unfamiliar API signatures.

---

## LSP keymaps

All LSP keymaps are defined inside an `LspAttach` autocmd, not at the top level of `init.lua`.

**Why `LspAttach`:** keymaps registered here are buffer-local (`buffer = event.buf`) and only exist while an LSP client is attached to that buffer. This means:
- `gd`, `K`, etc. are not accidentally bound in non-LSP buffers (e.g. plain text files)
- If an LSP client detaches and reattaches, the keymaps are re-registered cleanly
- The augroup `nvimtom-lsp-attach` uses `clear = true` so it doesn't accumulate duplicate handlers across config reloads

The document highlight feature (highlight all references to the symbol under the cursor on `CursorHold`) uses a separate augroup `nvimtom-lsp-highlight` with `clear = false`. This is intentional: the same augroup accumulates per-buffer autocmds, and `clear = true` would wipe all buffers' highlight handlers each time a new buffer attaches.

---

## Options rationale

| Option | Value | Why |
|--------|-------|-----|
| `signcolumn` | `'yes'` | Always reserve gutter space; prevents layout shifting when LSP adds/removes diagnostic signs |
| `updatetime` | `250` | Controls how quickly `CursorHold` fires; faster = more responsive document highlights and diagnostic floats |
| `timeoutlen` | `300` | How long to wait for a key sequence (e.g. `<leader>rn`); 300ms is fast without being frustrating |
| `scrolloff` | `8` | Keep 8 lines of context visible when the cursor is near the top/bottom of the window |
| `hlsearch` | `false` | Disable persistent search highlighting; use `incsearch` for live feedback while typing instead |
| `smartcase` | `true` | Case-insensitive search unless the pattern contains an uppercase letter |
| `termguicolors` | `true` | Enable 24-bit colour; required by most modern colorscheme and UI plugins |
| `clipboard` | `'unnamedplus'` | Sync the unnamed register with the system clipboard |

---

## What is deliberately absent

**No completion engine.** `nvim-cmp`, `blink.cmp`, etc. are not installed. LSP hover (`K`), signature help (`<C-k>`), and diagnostics work without one. A completion plugin will be added when actively wanted, not pre-emptively.

**No colorscheme.** `install = { colorscheme = { 'default' } }` in the lazy config prevents errors on first launch when no theme plugin is loaded yet. The built-in `default` theme is used until a theme plugin is explicitly added.

**No fuzzy finder.** telescope.nvim, fzf-lua, etc. are not installed. The built-in `gd` → definition, `gr` → references, and `:vim.diagnostic.setloclist` cover most navigation needs for now.

---

## vim-tmux-navigator

Seamless `<C-h/j/k/l>` navigation across both Neovim splits and tmux panes — the same keys work regardless of whether the adjacent pane is a Neovim split or a tmux pane.

**Lazy loading via `cmd` + `keys`:** the plugin uses lazy.nvim's `cmd` and `keys` triggers. It loads on first use of any navigation key or command rather than at startup. This is the pattern recommended in the plugin's own lazy.nvim installation docs.

**tmux side:** the tmux config is kept in `tmux/vim-tmux-navigator.conf` in this repo as a reusable template. It can be sourced from `~/.tmux.conf`:
```tmux
source-file ~/.config/nvim.tom/tmux/vim-tmux-navigator.conf
```
The snippet uses `ps -o state= -o comm=` to detect whether the current pane is running Neovim, then either forwards the keypress to Neovim or switches the tmux pane directly.

**`bind C-l send-keys 'C-l'`:** since `<C-l>` (clear screen) is taken over by the navigator, this binding restores it under `<prefix> C-l`.

**Copy-mode bindings:** the same `C-h/j/k/l` keys are also bound in tmux copy-mode so pane switching works consistently while scrolling through history.

---

**No treesitter.** Syntax highlighting uses Neovim's built-in regex engine for now. Treesitter will be added when it's needed for something specific (e.g. better indent or text objects), not as a default.

---

## oil.nvim — file explorer

oil.nvim replaces the default directory browser (netrw). It renders directory contents as an editable buffer — rename a file by editing its line, delete by deleting the line, move by cutting and pasting across oil buffers. Changes are staged and confirmed before being applied.

**`lazy = false`:** the oil.nvim docs explicitly state lazy loading is not recommended because it is difficult to intercept directory buffers reliably when lazy-loaded. It loads at startup.

**`default_file_explorer = true`:** oil takes over when Neovim opens a directory (e.g. `nvim .` or `:e src/`), replacing netrw.

**`show_hidden = true`:** hidden files (dotfiles) are shown by default. Toggle with `g.` inside an oil buffer.

**`columns = { 'icon' }`:** shows only the file icon column. Permissions, size, and mtime are available but kept off by default to reduce visual noise.

**No icon plugin dependency:** oil works without icons; file type icons are a progressive enhancement. An icon plugin can be added later.

**`-` keymap:** opens oil in the parent directory of the current file, matching the vim-vinegar convention. Registered via the lazy `keys` spec so it is only set up when oil loads.
