return {
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    keys = {
      { '<C-n>',     '<cmd>NvimTreeToggle<cr>',   desc = 'Toggle file tree' },
      { '<leader>E', '<cmd>NvimTreeFindFile<cr>', desc = 'Reveal file in tree' },
    },
    ---@type nvim_tree.config
    opts = {
      sort = {
        sorter = 'case_sensitive',
      },
      view = {
        width = 35,
      },
      renderer = {
        group_empty = true,   -- collapse empty single-child directories into one line
      },
      filters = {
        dotfiles = false,     -- show hidden files (consistent with oil)
      },
    },
  },
}
