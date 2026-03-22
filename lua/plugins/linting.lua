return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufWritePost', 'BufReadPost' },
    config = function()
      local lint = require('lint')

      lint.linters_by_ft = {
        -- C/C++ linting is intentionally omitted here.
        -- clangd already runs clang-tidy inline via --clang-tidy and reports
        -- results as LSP diagnostics. Adding clangtidy here would run it a
        -- second time and produce duplicate entries in the diagnostics list.
        --
        -- Add other languages here as needed, e.g.:
        --   sh  = { 'shellcheck' },
        --   py  = { 'pylint' },
      }

      -- Re-lint on write and on entering a buffer, so diagnostics are always
      -- current without requiring a manual trigger.
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost' }, {
        group = vim.api.nvim_create_augroup('nvimtom-lint', { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
