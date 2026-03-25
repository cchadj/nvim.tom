-- dap.lua — debugger for C and C++ via codelldb
--
-- Keymaps (active in C/C++ buffers):
--   <F1>          toggle breakpoint
--   <F2>          continue
--   <F3>          step over
--   <F4>          step into
--   <F8>          step out
--   <leader>dr    restart session
--   <leader>dq    terminate session
--   <leader>du    toggle debugger UI
--   <leader>de    evaluate expression under cursor

return {
  {
    'mfussenegger/nvim-dap',
    ft = { 'c', 'cpp' },
    dependencies = {
      -- Visual debugger UI (scopes, watches, stack, breakpoints, console).
      {
        'rcarriga/nvim-dap-ui',
        dependencies = { 'nvim-neotest/nvim-nio' },
      },
      -- Shows variable values inline in the buffer while debugging.
      'theHamsta/nvim-dap-virtual-text',
      -- Installs codelldb via Mason.
      {
        'mason-org/mason.nvim',
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { 'codelldb' })
        end,
      },
    },

    config = function()
      local dap    = require('dap')
      local dapui  = require('dapui')

      -- ── codelldb adapter ────────────────────────────────────────────
      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
          command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
          args    = { '--port', '${port}' },
        },
      }

      -- ── launch configurations ────────────────────────────────────────
      -- Prompts for the executable path so it works with any build system.
      local launch = {
        {
          name    = 'Launch executable',
          type    = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Executable: ', vim.fn.expand('%:p:r'), 'file')
          end,
          cwd          = '${workspaceFolder}',
          stopOnEntry  = false,
        },
      }
      dap.configurations.c   = launch
      dap.configurations.cpp = launch

      -- ── UI ───────────────────────────────────────────────────────────
      dapui.setup()

      -- Open UI automatically when a session starts/ends.
      dap.listeners.after.event_initialized['dapui'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui']     = function() dapui.close() end

      -- Inline variable values while stepping.
      require('nvim-dap-virtual-text').setup()

      -- ── keymaps (buffer-local for C/C++) ─────────────────────────────
      vim.api.nvim_create_autocmd('FileType', {
        group   = vim.api.nvim_create_augroup('nvimtom-dap', { clear = true }),
        pattern = { 'c', 'cpp' },
        callback = function(event)
          local map = function(key, fn, desc)
            vim.keymap.set('n', key, fn, { buffer = event.buf, desc = 'DAP: ' .. desc })
          end

          map('<F1>',        dap.toggle_breakpoint,              'Toggle breakpoint')
          map('<F2>',        dap.continue,                       'Continue')
          map('<F3>',        dap.step_over,                      'Step over')
          map('<F4>',        dap.step_into,                      'Step into')
          map('<F8>',        dap.step_out,                       'Step out')
          map('<leader>dr',  dap.restart,                        'Restart')
          map('<leader>dq',  dap.terminate,                      'Terminate')
          map('<leader>du',  dapui.toggle,                       'Toggle UI')
          map('<leader>de',  dapui.eval,                         'Evaluate expression')
        end,
      })
    end,
  },
}
