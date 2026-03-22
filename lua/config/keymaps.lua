-- keymaps.lua — global keymaps not tied to any specific plugin

-- <C-/> toggles comments using Neovim's built-in gc operator (0.10+).
-- gcc in normal mode, gc in visual mode. Filetype-aware via treesitter.
-- WSL2 terminals send <C-_> for Ctrl+/, so bind both.
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-/>', 'gc',  { remap = true, desc = 'Toggle comment' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-_>', 'gc',  { remap = true, desc = 'Toggle comment' })
