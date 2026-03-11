local M = {}

function M.setup()
  local dap = require("dap")
  require("dapui").setup()

  local python = require("plugin_settings.coding.python")
  local cpp = require("plugin_settings.coding.cpp")

  vim.keymap.set("n", "<Leader>dd", function()
    if cpp.is_cpp_filetype(vim.bo.filetype) then
      cpp.continue_or_launch(dap)
      return
    end
    dap.continue()
  end)

  local function debug_test()
    local ft = vim.bo.filetype
    if python.is_python_filetype(ft) then
      python.debug_test()
      return
    end

    if cpp.is_cpp_filetype(ft) then
      cpp.debug_test(dap)
      return
    end

    vim.notify("No debug test mapping for filetype: " .. ft, vim.log.levels.WARN)
  end

  vim.keymap.set("n", "<leader>dt", debug_test, { desc = "Debug Test (python/cpp)" })
  vim.keymap.set("n", "<A-b>", function() require("dap").toggle_breakpoint() end)
  vim.keymap.set("n", "<Leader>dr", function() require("dap").repl.open() end)
  vim.keymap.set("n", "<Leader>dl", function() require("dap").run_last() end)
  vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
    require("dap.ui.widgets").hover()
  end)
  vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
    require("dap.ui.widgets").preview()
  end)
  vim.keymap.set("n", "<Leader>df", function()
    local widgets = require("dap.ui.widgets")
    widgets.centered_float(widgets.frames)
  end)
  vim.keymap.set("n", "<Leader>ds", function()
    local widgets = require("dap.ui.widgets")
    widgets.centered_float(widgets.scopes)
  end)
  vim.keymap.set("n", "<Leader>c", function()
    vim.cmd("close")
  end)
  vim.keymap.set("n", "<Leader>du", function()
    require("dapui").toggle()
  end)

  vim.keymap.set("x", "<leader>di", function()
    local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"))
    dap.repl.open()
    dap.repl.execute(table.concat(lines, "\n"))
  end)

  vim.keymap.set("n", "<C-A-b>", function()
    dap.clear_breakpoints()
  end)
end

return M
