-- Zen mode toggle leader+z
local zen_mode = require('zen-mode')
vim.keymap.set('n', '<leader>z', zen_mode.toggle, {desc = 'Zen mode toggle'})


-- Copilog chat settings
vim.api.nvim_set_keymap('n', '<M-i>', ':CopilotChatToggle<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<M-C-i>', ':CopilotChatReset<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<M-I>', ':CopilotChatFix<CR>', {noremap = true, silent = true})

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


-- Reload file when changed on disk
vim.cmd([[
  " Triger `autoread` when files changes on disk
  " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
  " https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI *
          \ if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif

  " Notification after file change
  " https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
  autocmd FileChangedShellPost *
    \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
]])

-- dap-python and dap-python-ui
local dap = require("dap")
local dapui = require('dapui').setup()
vim.keymap.set('n', '<Leader>dd', function()
  dap.continue()
end)

local keymap = vim.keymap.set
keymap("n", "<leader>dt", function() require('dap-python').test_method() end, { desc = "Debug Method" })

vim.keymap.set('n', '<A-b>', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
  require('dap.ui.widgets').hover()
end)
vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
  require('dap.ui.widgets').preview()
end)
vim.keymap.set('n', '<Leader>df', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.frames)
end)
vim.keymap.set('n', '<Leader>ds', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.scopes)
end)
vim.keymap.set('n', '<Leader>c', function()
  vim.cmd('close')
end)
vim.keymap.set('n', '<Leader>du', function()
  require('dapui').toggle()
end)

vim.keymap.set("x", "<leader>di", function()
  local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"))
  dap.repl.open()
  dap.repl.execute(table.concat(lines, "\n"))
end)

-- dap.clear_breakpoints() ctrl+alt+b
vim.keymap.set('n', '<C-A-b>', function()
  dap.clear_breakpoints()
end)


-- Keybindigns
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

    -- Definition in new tab
    vim.keymap.set("n", "GD", function()
      vim.cmd("tabnew")
      vim.lsp.buf.definition()
    end, opts)

    -- vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    -- vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    -- vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    -- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

    -- Handy diagnostic navigations (optional)
    -- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    -- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    -- vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
  end,
})


vim.api.nvim_set_keymap('n', 'GD', ':lua goto_definition_in_new_tab()<CR>', {noremap = true, silent = true})

-- Linting
-- map <space>e :lua vim.diagnostic.open_float(0, {scope="line"})<CR>                                                      
vim.api.nvim_set_keymap('n', '<space>e', ':lua vim.diagnostic.open_float(0, {scope="line"})<CR>', {noremap = true, silent = true})
