-- keys.lua

-- Clipboard copy and paste
vim.opt.clipboard = "unnamedplus" -- Old way
-- vim.g.clipboard = {
--   name = 'OSC 52',
--   copy = {
--     ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
--     ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
--   },
--   paste = {
--     ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
--     ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
--   },
-- }

-- Set leader and localleader
vim.g.mapleader = "-"
vim.g.maplocalleader = "]"

-- Open buffer in new tab
vim.api.nvim_set_keymap('n', 'tt', ':tab split<CR>', {noremap = true})

-- Delete line in insert mode
vim.api.nvim_set_keymap('i', '<c-d>', '<esc>ddi', {noremap = true})

-- Move top and bottom of view with shift-h and shift-l in both normal and visual mode
vim.api.nvim_set_keymap('n', '<S-l>', 'H', {noremap = true})
vim.api.nvim_set_keymap('n', '<S-h>', 'L', {noremap = true})
vim.api.nvim_set_keymap('v', '<S-l>', 'H', {noremap = true})
vim.api.nvim_set_keymap('v', '<S-h>', 'L', {noremap = true})

-- Increase and decrease window size with ctrl+W+j/k/h/l
vim.api.nvim_set_keymap('n', '<A-j>', '<c-w>-', {noremap = true})
vim.api.nvim_set_keymap('n', '<A-k>', '<c-w>+', {noremap = true})
vim.api.nvim_set_keymap('n', '<A-h>', '<c-w><', {noremap = true})
vim.api.nvim_set_keymap('n', '<A-l>', '<c-w>>', {noremap = true})

-- Move between splits with ctrl+h/j/k/l
vim.api.nvim_set_keymap('n', '<c-j>', '<c-w>j', {noremap = true})
vim.api.nvim_set_keymap('n', '<c-k>', '<c-w>k', {noremap = true})
vim.api.nvim_set_keymap('n', '<c-h>', '<c-w>h', {noremap = true})
vim.api.nvim_set_keymap('n', '<c-l>', '<c-w>l', {noremap = true})


-- Insert newline and enter normal mode
vim.api.nvim_set_keymap('n', '<S-Enter>', 'O<Esc>', {noremap = true})
vim.api.nvim_set_keymap('n', '<CR>', 'o<Esc>', {noremap = true})

-- Uppercase word in insert and normal modes
vim.api.nvim_set_keymap('i', '<c-u>', '<esc>VUi', {noremap = true})
vim.api.nvim_set_keymap('n', '<c-u>', 'VU', {noremap = true})

-- Open .vimrc in vsplit and source .vimrc
vim.api.nvim_set_keymap('n', '<leader>ev', ':vsplit $MYVIMRC<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>sv', ':source $MYVIMRC<cr>', {noremap = true})

-- Clipboard copy and paste
vim.api.nvim_set_keymap('n', '<leader>y', '"+y', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>p', '"+p', {noremap = true})

-- Add quotes to word
vim.api.nvim_set_keymap('n', '<leader>"', 'viw<esc>a"<esc>bi"<esc>lel', {noremap = true})

-- Escape from insert mode
vim.api.nvim_set_keymap('i', 'jk', '<esc>', {noremap = true})

-- -- Toggle paste mode
-- local function toggle_paste()
--     if vim.o.paste == false then
--         vim.o.paste = true
--         print("Paste Mode Enabled")
--     else
--         vim.o.paste = false
--         print("Paste Mode Disabled")
--     end
-- end
-- vim.api.nvim_set_keymap('n', '<leader>pa', '<cmd>lua toggle_paste()<cr>', {noremap = true})

-- Disable arrow keys in normal mode
local disable_keys = {'<up>', '<down>', '<left>', '<right>'}
for _, key in ipairs(disable_keys) do
    vim.api.nvim_set_keymap('n', key, '<nop>', {noremap = true})
    vim.api.nvim_set_keymap('i', key, '<nop>', {noremap = true})
end

-- Set folding
vim.api.nvim_set_keymap(
	'n', '<space>', 
  'za &#8203;``【oaicite:0】``&#8203; ', {noremap = true})
	
-- Set mouse scrolling
vim.o.mouse = 'a'
