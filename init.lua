vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw in favour of nvim-tree (must be set before plugins load).
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('config.options')
require('config.lazy')
