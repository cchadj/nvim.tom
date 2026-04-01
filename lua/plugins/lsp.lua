return {
  -- Mason: installs and manages LSP servers, linters, formatters.
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = {
      -- Non-LSP tools managed by Mason (formatters, linters, DAP adapters).
      ensure_installed = { 'shfmt', 'sql-formatter' },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      -- Auto-install any tools listed in ensure_installed that aren't present.
      local mr = require('mason-registry')
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed or {}) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },

  -- mason-lspconfig: bridges Mason's install registry with nvim-lspconfig server names.
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'lua_ls', 'clangd', 'ts_ls', 'eslint', 'gopls', 'jsonls' },
      -- Only enable servers we explicitly call vim.lsp.enable() on below.
      automatic_enable = false,
    },
  },

  -- nvim-lspconfig: provides server definitions (cmd, filetypes, root detection).
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
    },
    config = function()
      -- ---------------------------------------------------------------
      -- Advertise nvim-cmp's extended completion capabilities to all servers.
      -- vim.lsp.config('*', ...) is the Neovim 0.11 way to set a base config
      -- that every server inherits. cmp_nvim_lsp.default_capabilities() adds
      -- snippet support, labelDetails, and other flags clangd uses for richer
      -- completion items. Must be called before any vim.lsp.enable() call.
      -- ---------------------------------------------------------------
      local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok then
        vim.lsp.config('*', { capabilities = cmp_lsp.default_capabilities() })
      end

      -- ---------------------------------------------------------------
      -- LspAttach: keymaps active only when an LSP is running for the buffer.
      -- ---------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('nvimtom-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Navigation
          map('gd', vim.lsp.buf.definition,      'Goto Definition')
          map('gD', vim.lsp.buf.declaration,     'Goto Declaration')
          map('gr', vim.lsp.buf.references,      'Goto References')
          map('gi', vim.lsp.buf.implementation,  'Goto Implementation')
          map('gy', vim.lsp.buf.type_definition, 'Goto Type Definition')

          -- Information
          map('K',     vim.lsp.buf.hover,          'Hover Documentation')
          map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help')

          -- Actions
          map('<leader>rn', vim.lsp.buf.rename,      'Rename Symbol')
          map('<F18>',      vim.lsp.buf.rename,      'Rename Symbol') -- Shift+F6
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')

          -- Inlay hints (variable types, parameter names inlined in code).
          -- Enabled by default; toggle with <leader>ih.
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          map('<leader>ih', function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
              { bufnr = event.buf }
            )
          end, 'Toggle Inlay Hints')

          -- Diagnostics
          map('<leader>d', vim.diagnostic.open_float, 'Show Diagnostic')
          map('[d',        vim.diagnostic.goto_prev,  'Previous Diagnostic')
          map(']d',        vim.diagnostic.goto_next,  'Next Diagnostic')
          map('<leader>q', vim.diagnostic.setloclist, 'Diagnostics to Quickfix')

          -- Document highlight: highlight all refs to symbol under cursor on hold.
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local group = vim.api.nvim_create_augroup('nvimtom-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- ---------------------------------------------------------------
      -- Diagnostic display
      -- ---------------------------------------------------------------
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
          source = true,
        },
      })

      -- ---------------------------------------------------------------
      -- lua_ls: Neovim-aware configuration.
      -- on_init injects runtime settings after the server starts,
      -- skipped if the workspace has its own .luarc.json.
      -- ---------------------------------------------------------------
      vim.lsp.config('lua_ls', {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if (vim.uv or vim.loop).fs_stat(path .. '/.luarc.json')
              or (vim.uv or vim.loop).fs_stat(path .. '/.luarc.jsonc') then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua or {}, {
            runtime = {
              version = 'LuaJIT',
            },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file('', true),
            },
            diagnostics = {
              globals = { 'vim' },
            },
            hint = {
              enable = true,
            },
          })
        end,

        settings = {
          Lua = {},
        },
      })

      vim.lsp.enable('lua_ls')

      -- ---------------------------------------------------------------
      -- clangd: C / C++ language server.
      --
      -- Flag rationale:
      --   --background-index          index project in background; go-to-def
      --                               works immediately while index builds.
      --   --clang-tidy                surface clang-tidy checks as LSP diagnostics.
      --   --header-insertion=iwyu     autoimport: insert the canonical header for
      --                               a symbol (Include What You Use).
      --   --completion-style=detailed  full return/param types per completion item.
      --   --function-arg-placeholders=1 snippet placeholders for function args;
      --                               requires LuaSnip to expand them.
      --   --fallback-style=llvm       formatting fallback when no .clang-format.
      --
      -- C++23 default: set via ~/.config/clangd/config.yaml (CompileFlags.Add),
      -- since clangd 22 removed --extra-arg. Overridden per-project by
      -- compile_commands.json or a local .clangd file.
      -- ---------------------------------------------------------------
      vim.lsp.config('clangd', {
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=iwyu',
          '--completion-style=detailed',
          '--function-arg-placeholders=1',
          '--fallback-style=llvm',
        },
      })

      vim.lsp.enable('clangd')

      -- ── TypeScript / JavaScript ─────────────────────────────────────
      -- ts_ls handles JS, TS, JSX, TSX, and Node.js projects.
      -- Inlay hints show inferred types inline (e.g. useState return type).
      local ts_hints = {
        includeInlayParameterNameHints            = 'literals',
        includeInlayVariableTypeHints             = true,
        includeInlayFunctionLikeReturnTypeHints   = true,
        includeInlayPropertyDeclarationTypeHints  = true,
        includeInlayFunctionParameterTypeHints    = true,
        includeInlayEnumMemberValueHints          = true,
      }
      vim.lsp.config('ts_ls', {
        settings = {
          typescript  = { inlayHints = ts_hints },
          javascript  = { inlayHints = ts_hints },
        },
      })
      vim.lsp.enable('ts_ls')

      -- eslint LSP surfaces ESLint diagnostics inline and provides
      -- an :EslintFixAll code action.
      vim.lsp.enable('eslint')

      -- ── Go ──────────────────────────────────────────────────────────
      -- gopls: official Go LSP. Handles completions, diagnostics,
      -- autoimports, and rich inlay hints.
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            hints = {
              assignVariableTypes    = true,
              compositeLiteralFields = true,
              compositeLiteralTypes  = true,
              constantValues         = true,
              functionTypeParameters = true,
              parameterNames         = true,
              rangeVariableTypes     = true,
            },
          },
        },
      })
      vim.lsp.enable('gopls')

      -- ── JSON ────────────────────────────────────────────────────────
      -- jsonls: schema validation, hover docs, and completions for JSON
      -- files. Schemas are sourced from SchemaStore (package.json,
      -- tsconfig.json, .eslintrc, etc. are auto-detected).
      vim.lsp.config('jsonls', {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      })
      vim.lsp.enable('jsonls')

      -- SQL completions are handled by vim-dadbod-completion (dadbod.lua),
      -- not an LSP server — no sqls needed.

      -- ---------------------------------------------------------------
      -- To add more servers:
      --   1. Add Mason package name to ensure_installed above.
      --   2. Optionally: vim.lsp.config('server_name', { ... })
      --   3. vim.lsp.enable('server_name')
      -- ---------------------------------------------------------------
    end,
  },
}
