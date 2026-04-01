return {
  -- Snippet engine — required to expand clangd's function-arg-placeholder
  -- completions. LuaSnip handles the LSP snippet format that clangd emits.
  {
    'L3MON4D3/LuaSnip',
    build = 'make install_jsregexp',
    lazy = true,
  },

  -- nvim-cmp: completion engine. Aggregates sources (LSP, buffer, path,
  -- snippets) and renders them in a popup menu in insert mode.
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',     -- LSP completions (clangd, lua_ls, etc.)
      'hrsh7th/cmp-buffer',       -- words from open buffers
      'hrsh7th/cmp-path',         -- filesystem paths
      'saadparwaiz1/cmp_luasnip', -- LuaSnip as a cmp source
      'L3MON4D3/LuaSnip',
    },
    config = function()
      local cmp     = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ['<C-n>']     = cmp.mapping.select_next_item(),
          ['<C-p>']     = cmp.mapping.select_prev_item(),
          ['<C-d>']     = cmp.mapping.scroll_docs(-4),
          ['<C-f>']     = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>']      = cmp.mapping.confirm({ select = true }),

          -- Tab: advance through completion list OR jump snippet placeholder.
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),

          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),

        -- Sources in priority order. Group 1 is tried first; group 2 fills in
        -- when group 1 returns nothing (e.g. in a comment or plain text).
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- LSP completions (highest priority)
          { name = 'luasnip' },  -- snippet completions
        }, {
          { name = 'buffer' },   -- words from open buffers (fallback)
          { name = 'path' },     -- filesystem paths
        }),
      })

      -- Override cmp's internal <Esc> handler which only closes the popup
      -- without exiting insert mode. This mapping takes priority because it
      -- is set after cmp.setup() as a plain insert keymap.
      vim.keymap.set('i', '<Esc>', function()
        if cmp.visible() then cmp.abort() end
        vim.cmd('stopinsert')
      end, { desc = 'Close completion and exit insert' })
    end,
  },
}
