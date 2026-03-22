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
