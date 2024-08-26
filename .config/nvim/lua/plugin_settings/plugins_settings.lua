-- plugins.lua

-- UltiSnips settings
vim.g.UltiSnipsExpandTrigger = "<tab>"
vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
vim.g.UltiSnipsEditSplit = "vertical"

-- Keymaps for Telescope and its plugins
-- Load the telescope file browser extension
require('telescope').load_extension('file_browser')
require('telescope').setup{
    -- other setup configuration
    extensions = {
        file_browser = {
            -- File browser specific settings
            mappings = {
                ["i"] = {
                    -- insert mode mappings
                },
                ["n"] = {
                    -- normal mode mappings
                    ["j"] = require('telescope.actions').move_selection_next,
                    ["k"] = require('telescope.actions').move_selection_previous,
                    ["<CR>"] = require('telescope.actions').select_default + require('telescope.actions').center,
                    -- Add more bindings as needed
                },
            },
        },
    },
}

vim.api.nvim_set_keymap('n', '<leader>fd', '<cmd>Telescope file_browser<cr>', {noremap = true, silent = true})
vim.keymap.set("n", "<space>fb", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

-- Disable folding in Telescope's result window.
vim.api.nvim_create_autocmd("FileType", 
  { pattern = "TelescopeResults", command = [[setlocal nofoldenable]] }
)

-- Keymaps for vimtex
vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_compiler_method = 'latexmk'
vim.keymap.set('n', '<leader>l', function()
  vim.cmd('VimtexCompile')
  vim.cmd('VimtexView')
end, {desc = 'Compile and view LaTeX'})

-- Aerial settings --

-- Toggle the aerial window
vim.api.nvim_set_keymap('n', '<leader>a', '<cmd>AerialToggle<CR>', { noremap = true, silent = true })

-- Jump to the next/previous symbol
vim.api.nvim_set_keymap('n', '<', '<cmd>AerialPrev<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '>', '<cmd>AerialNext<CR>', { noremap = true, silent = true })

-- ALE settings
