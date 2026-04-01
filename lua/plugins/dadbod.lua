-- dadbod.lua — SQL keyword completions via vim-dadbod-completion.
-- No live database connection required for keyword/function completions.
-- Connect to a database via :DBUI or :DB mysql://user:pass@host/dbname
-- for schema-aware completions (table/column names).

return {
  {
    'kristijanhusak/vim-dadbod-completion',
    ft           = { 'sql', 'mysql', 'plsql' },
    lazy         = true,
    dependencies = { 'tpope/vim-dadbod' },
    config       = function()
      -- Register dadbod as a cmp source for SQL buffers.
      -- vim-dadbod must be loaded (via dependencies) for keyword completions to work.
      local cmp = require('cmp')
      cmp.setup.filetype({ 'sql', 'mysql', 'plsql' }, {
        sources = cmp.config.sources({
          { name = 'vim-dadbod-completion' },
          { name = 'buffer' },
        }),
      })
    end,
  },
}
