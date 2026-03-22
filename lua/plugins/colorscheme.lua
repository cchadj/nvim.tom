return {
  {
    'catppuccin/nvim',
    name     = 'catppuccin',
    lazy     = false,
    priority = 1000, -- load before all other plugins
    opts = {
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme('catppuccin')
    end,
  },
}
