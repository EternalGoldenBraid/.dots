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

  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
  
    
  -- require("lazy").setup("plugins")
  require("lazy").setup({
    require("plugins/ui"),
    require("plugins/ultisnips"),
    require("plugins/obsidian_nvim"),
    require("plugins/coding"),
    require("plugins/telescope"),
    require("plugins/vimtex"),
  })
  require('Comment').setup()
  
  -- Using require for modules
  require('general')
  require('gui')
  require('keys')
  -- require('plugins_settings')
  require('plugin_settings/coding')
  require('plugin_settings/plugins_settings')
  require('filetypes')


  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
  vim.keymap.set('n', '<leader>fs', builtin.commands, {})
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

    -- vim.cmd("source " .. home .. "/.config/nvim/old/general.vim")
    -- vim.cmd("source " .. home .. "/.config/nvim/old/gui.vim")
    -- vim.cmd("source " .. home .. "/.config/nvim/old/keys.vim")
    -- vim.cmd("source " .. home .. "/.config/nvim/old/plugins.vim")
    -- vim.cmd("source " .. home .. "/.config/nvim/filetypes.vim")
    -- Uncomment the next line if you want to source coc.vim
    -- vim.cmd("source " .. home .. "/.config/nvim/coc.vim")

end
