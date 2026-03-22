return {
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
      },
    },
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<cr>',                desc = 'Find files' },
      { '<leader>fg', '<cmd>Telescope live_grep<cr>',                 desc = 'Live grep' },
      { '<leader>fb', '<cmd>Telescope buffers<cr>',                   desc = 'Buffers' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>',                  desc = 'Recent files' },
      { '<leader>fh', '<cmd>Telescope help_tags<cr>',                 desc = 'Help tags' },
      { '<leader>fd', '<cmd>Telescope diagnostics<cr>',               desc = 'Diagnostics' },
      { '<leader>fs', '<cmd>Telescope lsp_document_symbols<cr>',      desc = 'Document symbols' },
      { '<leader>/',  '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Fuzzy find in buffer' },
    },
    config = function()
      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              -- Free up <C-k> so vim-tmux-navigator can use it outside telescope.
              -- Remap the scroll-results-up action to <C-u> instead.
              ['<C-k>'] = false,
              ['<C-u>'] = require('telescope.actions').move_selection_previous,
            },
          },
        },
      })

      telescope.load_extension('fzf')
    end,
  },
}
