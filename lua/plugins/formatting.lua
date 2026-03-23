return {
  {
    'stevearc/conform.nvim',

    -- BufWritePre: run the formatter synchronously just before each save.
    event = 'BufWritePre',
    -- ConformInfo: show which formatters are active for the current buffer.
    cmd = 'ConformInfo',

    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        c   = { 'clang_format' },
        cpp = { 'clang_format' },
        -- lua = { 'stylua' },  -- uncomment once stylua is added to Mason ensure_installed

        -- Web: prettier handles all JS/TS/web filetypes.
        -- Uses the project-local prettier (node_modules/.bin/prettier) if present,
        -- otherwise falls back to a global install (npm install -g prettier).
        javascript      = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript      = { 'prettier' },
        typescriptreact = { 'prettier' },
        html            = { 'prettier' },
        css             = { 'prettier' },
        json            = { 'prettier' },
        yaml            = { 'prettier' },
      },

      -- Format synchronously on save.
      -- lsp_fallback: if conform has no formatter for the filetype, ask the
      -- LSP to format instead (e.g. for languages not listed above).
      format_on_save = {
        timeout_ms   = 500,
        lsp_fallback = true,
      },
    },
  },
}
