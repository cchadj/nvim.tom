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

        -- Python: ruff covers style (PEP8), unused imports, and common bugs.
        -- pyright handles type errors; ruff handles everything else.
        -- Install via Mason: auto-installed by mason-tool-installer (lsp.lua).
        python = { 'ruff' },
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
