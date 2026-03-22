return {
  {
    -- clangd-specific features beyond the standard LSP protocol.
    -- The vanilla LSP integration (diagnostics, go-to-def, rename, etc.)
    -- is handled by lsp.lua. This plugin adds what clangd exposes via its
    -- own protocol extensions.
    'p00f/clangd_extensions.nvim',

    -- Only load when a C/C++ file is opened — zero startup cost otherwise.
    ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },

    config = function()
      require('clangd_extensions').setup({
        inlay_hints = {
          inline = true,
          show_parameter_hints = true,   -- f(/*count=*/3)
          parameter_hints_prefix = '<- ',
          other_hints_prefix    = '=> ', -- used for deduced auto types
          show_variable_name    = false,
          highlight = 'Comment',         -- dim hints so they don't compete with code
        },
        ast = {
          highlights = { detail = 'Comment' },
        },
        memory_usage = { border = 'rounded' },
        symbol_info  = { border = 'rounded' },
      })

      -- Enable inlay hints for every C/C++ buffer when clangd attaches.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('nvimtom-clangd-hints', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == 'clangd' then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          end
        end,
      })

      -- C++-specific keymaps, buffer-local, only when clangd is attached.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('nvimtom-clangd-keys', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not (client and client.name == 'clangd') then return end

          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'C++: ' .. desc })
          end

          -- Most-used C++ navigation: switch between .h / .cpp
          map('<A-o>', '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch header / source')

          -- Inspect the Clang AST for the node under cursor
          map('<leader>cA', '<cmd>ClangdAST<cr>', 'View AST')

          -- Type and canonical declaration of symbol under cursor
          map('<leader>ci', '<cmd>ClangdSymbolInfo<cr>', 'Symbol info')

          -- Per-TU memory breakdown (useful when indexing is slow)
          map('<leader>cm', '<cmd>ClangdMemoryUsage<cr>', 'Memory usage')

          -- Toggle inlay hints for this buffer
          map('<leader>ch', function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
              { bufnr = event.buf }
            )
          end, 'Toggle inlay hints')
        end,
      })
    end,
  },
}
