return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    -- Load as soon as a file is opened so highlighting is ready immediately.
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('nvim-treesitter.configs').setup({
        -- Parsers to always have installed.
        ensure_installed = { 'c', 'cpp', 'lua', 'vim', 'vimdoc' },

        -- Auto-install a parser the first time a file of that type is opened.
        auto_install = true,

        -- Treesitter-based syntax highlighting — replaces Neovim's regex engine.
        -- Dramatically better for C++ templates, nested generics, and preprocessor
        -- branches that regex patterns mis-parse.
        highlight = {
          enable = true,
        },

        -- Treesitter-based indentation — replaces cindent for C++.
        -- Better handling of lambdas, initialiser lists, and range-for loops.
        indent = {
          enable = true,
        },
      })
    end,
  },
}
