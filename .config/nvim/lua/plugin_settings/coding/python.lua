local M = {}

function M.is_python_filetype(ft)
  return ft == "python"
end

function M.setup_dap_python()
  local dap_python = require("dap-python")
  dap_python.setup("~/venvs/neovim/bin/python")
  dap_python.test_runner = "pytest"
end

function M.debug_test()
  require("dap-python").test_method()
end

return M
