-- autopairs.lua — auto-close brackets, parens, quotes as you type.
-- Smart enough to skip closing when you type the closing char yourself,
-- and integrates with nvim-cmp so confirmed completions don't double-close.

return {
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      local autopairs = require('nvim-autopairs')
      autopairs.setup({ check_ts = true }) -- use treesitter to avoid pairing inside strings/comments

      -- Integrate with nvim-cmp: insert closing pair when confirming a completion.
      local ok, cmp = pcall(require, 'cmp')
      if ok then
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
      end
    end,
  },
}
