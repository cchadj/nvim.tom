-- keymaps.lua — global keymaps not tied to any specific plugin

-- <Esc> exits terminal mode back to normal mode.
-- Set as buffer-local on TermOpen so it reliably overrides any plugin defaults.
vim.api.nvim_create_autocmd('TermOpen', {
  group    = vim.api.nvim_create_augroup('nvimtom-terminal', { clear = true }),
  callback = function(event)
    vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = event.buf, desc = 'Exit terminal mode' })
  end,
})

-- <C-/> toggles comments using Neovim's built-in gc operator (0.10+).
-- gcc in normal mode, gc in visual mode. Filetype-aware via treesitter.
-- WSL2 terminals send <C-_> for Ctrl+/, so bind both.
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-/>', 'gc',  { remap = true, desc = 'Toggle comment' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-_>', 'gc',  { remap = true, desc = 'Toggle comment' })
