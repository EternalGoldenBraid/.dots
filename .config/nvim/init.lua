-- init.lua

local home = os.getenv("HOME")
local root = home .. "/.config/nvim"

-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3092
local ts_path = '~/.config/nvim > ls /home/nicklas/.local/share/nvim/lazy/nvim-treesitter'
vim.opt.runtimepath:prepend(ts_path)


-- Check if running inside VSCode
if vim.g.vscode then
    -- vim.cmd("source " .. home .. "/.config/nvim/vscode.vim")
    vim.cmd('echo "init.lua: VSCode Neovim Loaded"')
    require('keys')
else
  
  -- Using require for modules
  require('keys')
  require("nicklas.lazy")
  require('general')
  require('gui')

  require('plugin_settings/coding')
  require('plugin_settings/plugins_settings')
  require('filetypes')


  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
  vim.keymap.set('n', '<leader>fs', builtin.commands, {})
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

end
