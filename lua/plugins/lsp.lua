return {
  -- Mason: installs and manages LSP servers, linters, formatters.
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = {},
  },

  -- mason-lspconfig: bridges Mason's install registry with nvim-lspconfig server names.
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'lua_ls' },
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
      -- LspAttach: keymaps active only when an LSP is running for the buffer.
      -- ---------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('nvimtom-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

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
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')

          -- Diagnostics
          map('<leader>d', vim.diagnostic.open_float, 'Show Diagnostic')
          map('[d',        vim.diagnostic.goto_prev,  'Previous Diagnostic')
          map(']d',        vim.diagnostic.goto_next,  'Next Diagnostic')
          map('<leader>q', vim.diagnostic.setloclist, 'Diagnostics to Quickfix')

          -- Document highlight: highlight all refs to symbol under cursor on hold.
          local client = vim.lsp.get_client_by_id(event.data.client_id)
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
      -- To add more servers:
      --   1. Add Mason package name to ensure_installed above.
      --   2. Optionally: vim.lsp.config('server_name', { ... })
      --   3. vim.lsp.enable('server_name')
      -- ---------------------------------------------------------------
    end,
  },
}
