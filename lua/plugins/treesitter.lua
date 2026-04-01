return {
  {
    'nvim-treesitter/nvim-treesitter',

    -- :TSUpdate updates all installed parsers when the plugin updates.
    build = ':TSUpdate',

    event = { 'BufReadPre', 'BufNewFile' },

    config = function()
      -- nvim-treesitter v1.x API:
      --   setup() only accepts { install_dir } — no highlight/indent/ensure_installed.
      --   Highlighting is NOT auto-enabled; we must call vim.treesitter.start()
      --   ourselves via a FileType autocmd.
      --
      -- Install our parsers asynchronously at startup (skips already-installed ones).
      require('nvim-treesitter').install({ 'c', 'cpp', 'lua', 'vim', 'vimdoc',
        'javascript', 'typescript', 'tsx', 'html', 'css', 'json',
        'go', 'gomod', 'gowork',
        'sql' })

      -- Enable treesitter highlighting for every buffer whose filetype has a
      -- parser. pcall silently skips filetypes with no parser installed.
      vim.api.nvim_create_autocmd('FileType', {
        group    = vim.api.nvim_create_augroup('nvimtom-treesitter', { clear = true }),
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
}
