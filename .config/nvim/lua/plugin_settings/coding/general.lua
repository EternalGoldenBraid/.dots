local zen_mode = require("zen-mode")
vim.keymap.set("n", "<leader>z", zen_mode.toggle, { desc = "Zen mode toggle" })

vim.api.nvim_set_keymap("n", "<M-i>", ":CopilotChatToggle<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<M-C-i>", ":CopilotChatReset<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<M-I>", ":CopilotChatFix<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ct", ":Copilot toggle<CR>", { noremap = true, silent = true })

vim.g.slime_target = "tmux"
vim.g.slime_default_config = {
  socket_name = vim.api.nvim_eval('get(split($TMUX, ","), 0)'),
  target_pane = "{top-right}",
}

require("Comment").setup()

vim.cmd([[
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI *
          \ if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif

  autocmd FileChangedShellPost *
    \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
]])

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "GD", function()
      vim.cmd("tabnew")
      vim.lsp.buf.definition()
    end, opts)
  end,
})

vim.api.nvim_set_keymap("n", "GD", ":lua goto_definition_in_new_tab()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<space>e", ":lua vim.diagnostic.open_float(0, {scope=\"line\"})<CR>", { noremap = true, silent = true })
