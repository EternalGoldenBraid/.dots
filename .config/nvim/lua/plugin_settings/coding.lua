-- Copilot settings
vim.g.copilot_filetypes = {markdown = true}
vim.g.copilot_no_tab_map = true

-- Key mappings for Copilot
-- These mappings use Vimscript syntax for specific plugin functions
-- They are set using vim.api.nvim_set_keymap with the 'expr' option
vim.api.nvim_set_keymap('i', '<C-J>', 'copilot#Accept("\\<CR>")', {silent = true, script = true, expr = true})
vim.api.nvim_set_keymap('i', '<C-L>', '<Plug>(copilot-accept-word)', {silent = true})

-- Slime
vim.g.slime_target = 'tmux'
-- vim.g.slime_default_config = {"socket_name" = "default", "target_pane" = "{last}"}
vim.g.slime_default_config = {
  -- Lua doesn't have a string split function!
  socket_name = vim.api.nvim_eval('get(split($TMUX, ","), 0)'),
  target_pane = '{top-right}',
}

-- Comment
require('Comment').setup()

-- Zen
vim.api.nvim_set_keymap('n', '<leader>z', ':ZenMode<CR>', {silent = true})
