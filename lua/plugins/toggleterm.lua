-- toggleterm.lua — embedded terminal + competitive C++ runner
--
-- Global keymaps:
--   <leader>tt          toggle terminal (horizontal split)
--   <leader>ts          send current line / visual selection to terminal
--
-- C/C++ keymaps (FileType autocmd, buffer-local):
--   <F5>        write → compile → run interactively (stdin from keyboard)
--   <F6>        write → compile → run with < input.txt
--   <F7>        write → compile → run with < <exec-name>.txt (e.g. main.txt)
--   <F9>        write → compile only → errors into quickfix
--   <leader>cp  create new problem file from templates/cp.cpp

return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    ft = { 'c', 'cpp' },
    keys = {
      { '<leader>tt', desc = 'Terminal: toggle' },
      { '<leader>ts', desc = 'Terminal: send line',      mode = 'n' },
      { '<leader>ts', desc = 'Terminal: send selection', mode = 'v' },
    },
    config = function()
      require('toggleterm').setup({
        size             = 15,
        direction        = 'horizontal',
        -- Do NOT set open_mapping — the default (<C-\>) conflicts with
        -- vim-tmux-navigator's TmuxNavigatePrevious binding.
        open_mapping     = nil,
        start_in_insert  = false,
        persist_size     = true,
        -- Keep terminal open after the program exits so output can be read.
        close_on_exit    = false,
        shell            = vim.o.shell,
      })

      -- ---------------------------------------------------------------
      -- Global terminal keymaps
      -- ---------------------------------------------------------------
      vim.keymap.set('n', '<leader>tt', '<cmd>ToggleTerm<cr>',
        { desc = 'Terminal: toggle' })
      vim.keymap.set('n', '<leader>ts', '<cmd>ToggleTermSendCurrentLine<cr>',
        { desc = 'Terminal: send current line' })
      vim.keymap.set('v', '<leader>ts', '<cmd>ToggleTermSendVisualSelection<cr>',
        { desc = 'Terminal: send selection' })

      -- ---------------------------------------------------------------
      -- C / C++ runner — registered via FileType so the keymaps work
      -- even before clangd attaches (no LSP dependency).
      -- ---------------------------------------------------------------
      vim.api.nvim_create_autocmd('FileType', {
        group   = vim.api.nvim_create_augroup('nvimtom-cpp-runner', { clear = true }),
        pattern = { 'c', 'cpp' },
        callback = function(event)

          local function buf_map(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'C++: ' .. desc })
          end

          -- Returns absolute paths for the current buffer.
          local function paths()
            local src = vim.fn.expand('%:p')   -- e.g. /home/tom/problems/a/main.cpp
            local out = vim.fn.expand('%:p:r') -- e.g. /home/tom/problems/a/main
            local dir = vim.fn.expand('%:p:h') -- e.g. /home/tom/problems/a
            return src, out, dir
          end

          -- Builds the compile command string.
          -- Uses gcc-14 for C files, g++-14 for C++.
          local function compile_cmd(src, out)
            local is_c = vim.bo.filetype == 'c'
            local compiler = is_c and 'gcc-14'      or 'g++-14'
            local std      = is_c and '-std=c17'    or '-std=c++23'
            local posix    = is_c and '-D_POSIX_C_SOURCE=200809L' or ''
            return string.format(
              '%s %s %s -O2 -Wall -Wextra -Wconversion -g -o %s %s',
              compiler, std, posix,
              vim.fn.shellescape(out),
              vim.fn.shellescape(src)
            )
          end

          -- ── F5: compile + run interactively ───────────────────────
          -- go_back=true: focus returns to editor after launching.
          buf_map('<F5>', function()
            vim.cmd('write')
            local src, out, _ = paths()
            local cmd = compile_cmd(src, out) .. ' && ' .. vim.fn.shellescape(out)
            require('toggleterm').exec(cmd, 1, 15, nil, nil, nil, true)
          end, 'F5: compile + run (interactive)')

          -- ── F6: compile + run with < input.txt ────────────────────
          -- go_back=true: focus returns to the editor after launching.
          buf_map('<F6>', function()
            vim.cmd('write')
            local src, out, dir = paths()
            local input = dir .. '/input.txt'
            local cmd = compile_cmd(src, out)
              .. ' && ' .. vim.fn.shellescape(out)
              .. ' < '  .. vim.fn.shellescape(input)
            require('toggleterm').exec(cmd, 1, 15, nil, nil, nil, true)
          end, 'F6: compile + run with input.txt')

          -- ── F7: compile + run with < <exec-name>.txt ──────────────
          -- Like F6 but uses <exec-name>.txt instead of input.txt.
          -- e.g. main.cpp → main.txt
          buf_map('<F7>', function()
            vim.cmd('write')
            local src, out, _ = paths()
            local input = out .. '.txt'
            local cmd = compile_cmd(src, out)
              .. ' && ' .. vim.fn.shellescape(out)
              .. ' < '  .. vim.fn.shellescape(input)
            require('toggleterm').exec(cmd, 1, 15, nil, nil, nil, true)
          end, 'F7: compile + run with <exec>.txt')

          -- ── F9: compile only → quickfix ───────────────────────────
          -- Async via jobstart — does not block the UI.
          -- Errors are parsed with GCC errorformat and loaded into quickfix.
          buf_map('<F9>', function()
            vim.cmd('write')
            local src, out, _ = paths()
            local stderr_lines = {}

            vim.fn.jobstart(
              (function()
                local is_c = vim.bo.filetype == 'c'
                local args = {
                  is_c and 'gcc-14' or 'g++-14',
                  is_c and '-std=c17' or '-std=c++23',
                }
                if is_c then
                  table.insert(args, '-D_POSIX_C_SOURCE=200809L')
                end
                vim.list_extend(args, { '-O2', '-Wall', '-Wextra', '-Wconversion', '-g', '-o', out, src })
                return args
              end)(),
              {
                stderr_buffered = true,
                on_stderr = function(_, data)
                  if data then vim.list_extend(stderr_lines, data) end
                end,
                on_exit = function(_, code)
                  if code == 0 then
                    vim.notify('Compiled OK — ' .. vim.fn.fnamemodify(out, ':t'),
                      vim.log.levels.INFO)
                    vim.fn.setqflist({}, 'r')
                    vim.cmd('cclose')
                  else
                    vim.fn.setqflist({}, 'r', {
                      title = 'C++ compile errors',
                      lines = stderr_lines,
                      efm   = '%f:%l:%c: %t%*[^:]: %m,%f:%l: %t%*[^:]: %m',
                    })
                    vim.cmd('copen')
                    vim.cmd('cfirst')
                    vim.notify('Compile failed — see quickfix', vim.log.levels.ERROR)
                  end
                end,
              }
            )
          end, 'F9: compile → quickfix')

          -- ── <leader>cp: new problem file from template ────────────
          buf_map('<leader>cp', function()
            local template = vim.fn.stdpath('config') .. '/templates/cp.cpp'
            if not (vim.uv or vim.loop).fs_stat(template) then
              vim.notify('Template not found: ' .. template, vim.log.levels.ERROR)
              return
            end

            vim.ui.input({ prompt = 'Problem name (no extension): ' }, function(name)
              if not name or name == '' then return end

              local dir     = vim.fn.expand('%:p:h')
              local newfile = dir .. '/' .. name .. '.cpp'

              if (vim.uv or vim.loop).fs_stat(newfile) then
                vim.notify('Already exists: ' .. newfile, vim.log.levels.WARN)
                return
              end

              local src = io.open(template, 'r')
              if not src then
                vim.notify('Cannot read template', vim.log.levels.ERROR)
                return
              end
              local content = src:read('*a')
              src:close()

              local dst = io.open(newfile, 'w')
              if not dst then
                vim.notify('Cannot write: ' .. newfile, vim.log.levels.ERROR)
                return
              end
              dst:write(content)
              dst:close()

              vim.cmd('edit ' .. vim.fn.fnameescape(newfile))
            end)
          end, 'New problem from template')

        end, -- FileType callback
      })

    end, -- config
  },
}
