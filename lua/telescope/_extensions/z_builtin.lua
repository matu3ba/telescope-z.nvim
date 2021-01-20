local actions = require'telescope.actions'
local conf = require'telescope.config'.values
local entry_display = require'telescope.pickers.entry_display'
local finders = require'telescope.finders'
local from_entry = require'telescope.from_entry'
local pickers = require'telescope.pickers'
local previewers = require'telescope.previewers.term_previewer'
local utils = require'telescope.utils'

local M = {}

local function gen_from_z(opts)
  local displayer = entry_display.create{
    separator = ' ',
    items = {
      {width = 7, right_justify = true}, -- score
      {remaining = true}, -- path
    },
  }

  local function make_display(entry)
    return displayer{
      {('%.2f'):format(entry.value), 'TelescopeResultsIdentifier'},
      entry.path,
    }
  end

  return function(line)
    local score_str, path = line:match'([%.%d]+)%s+(.+)'
    local score = tonumber(score_str)

    return {
      value = score,
      ordinal = path,
      path = path,
      display = make_display,
    }
  end
end

M.list = function(opts)
  opts = opts or {}
  opts.cmd = utils.get_default(opts.cmd, {vim.o.shell, '-c', 'z -l'})
  opts.entry_maker = utils.get_lazy_default(opts.entry_maker, function()
    return gen_from_z(opts)
  end)

  pickers.new(opts, {
    prompt_title = 'Visited directories from z',
    finder = finders.new_table{
      results = utils.get_os_command_output(opts.cmd),
      entry_maker = opts.entry_maker,
    },
    sorter = conf.file_sorter(opts),
    previewer = previewers.cat.new(opts),
    attach_mappings = function(prompt_bufnr)
      actions._goto_file_selection:replace(function(_, cmd)
        local entry = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        local path = from_entry.path(entry)
        if cmd == 'edit' then
          require'telescope.builtin'.find_files{cwd = path}
        elseif cmd == 'new' then
          vim.cmd('cd '..path)
          print('chdir to '..path)
        elseif cmd == 'vnew' then
          vim.cmd('lcd '..path)
          print('lchdir to '..path)
        end
      end)
      return true
    end,
  }):find()
end

return M
