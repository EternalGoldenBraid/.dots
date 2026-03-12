local M = {}

local cpp_filetypes = {
  c = true,
  cpp = true,
  objc = true,
  objcpp = true,
  rust = true,
}

function M.is_cpp_filetype(ft)
  return cpp_filetypes[ft] == true
end

local function project_root(cwd)
  local cc_path = vim.fn.findfile("compile_commands.json", cwd .. ";")
  if cc_path ~= "" then
    return vim.fn.fnamemodify(cc_path, ":h")
  end
  return cwd
end

local function collect_build_dirs(root)
  local build_dirs = {}
  for _, dir in ipairs(vim.fn.glob(root .. "/build*", true, true)) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(build_dirs, dir)
    end
  end
  return build_dirs
end

local function find_candidate_binaries(build_dirs, basename)
  local candidates = {}
  local seen = {}

  for _, dir in ipairs(build_dirs) do
    for _, candidate in ipairs(vim.fn.glob(dir .. "/**/" .. basename, true, true)) do
      if seen[candidate] == nil and vim.fn.isdirectory(candidate) == 0 and vim.fn.executable(candidate) == 1 then
        seen[candidate] = true
        table.insert(candidates, candidate)
      end
    end
  end

  return candidates
end

local function preferred_default_path(root, build_dirs)
  local tests_dir = root .. "/bot_sort/tests/"
  if vim.fn.isdirectory(tests_dir) == 1 then
    return tests_dir
  end

  if #build_dirs > 0 then
    return build_dirs[1] .. "/"
  end

  return root .. "/"
end

function M.resolve_program()
  local cwd = vim.fn.getcwd()
  local root = project_root(cwd)
  local build_dirs = collect_build_dirs(root)
  local basename = vim.fn.expand("%:t:r")

  if basename ~= "" then
    local matches = find_candidate_binaries(build_dirs, basename)
    if #matches == 1 then
      return matches[1]
    end

    local default_choice = matches[1] or preferred_default_path(root, build_dirs)
    return vim.fn.input("Path to executable: ", default_choice, "file")
  end

  return vim.fn.input("Path to executable: ", preferred_default_path(root, build_dirs), "file")
end

function M.setup_dap(dap)
  local codelldb_path = vim.fn.exepath("codelldb")
  if codelldb_path == "" then
    vim.notify("codelldb not found in PATH. Install it to debug C/C++ (e.g., via Mason or system package).", vim.log.levels.WARN)
    return
  end

  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb_path,
      args = { "--port", "${port}" },
    },
  }

  dap.configurations.cpp = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = M.resolve_program,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    },
    {
      name = "Attach to process",
      type = "codelldb",
      request = "attach",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }

  dap.configurations.c = dap.configurations.cpp
  dap.configurations.rust = dap.configurations.cpp

  local root = project_root(vim.fn.getcwd())
  local launchjs = root .. "/.vscode/launch.json"
  if vim.fn.filereadable(launchjs) == 1 then
    require("dap.ext.vscode").load_launchjs(launchjs, {
      codelldb = { "c", "cpp", "rust" },
    })
  end
end

function M.continue_or_launch(dap)
  if dap.session() then
    dap.continue()
    return
  end

  local ft = vim.bo.filetype
  if not M.is_cpp_filetype(ft) then
    dap.continue()
    return
  end

  local configs = dap.configurations[ft] or dap.configurations.cpp
  if configs and #configs > 0 then
    for _, cfg in ipairs(configs) do
      if cfg.request == "launch" and type(cfg.program) == "string" then
        dap.run(cfg)
        return
      end
    end

    dap.run(configs[1])
    return
  end

  dap.continue()
end

function M.debug_test(dap)
  if not dap.adapters.codelldb then
    vim.notify("codelldb adapter not configured. Ensure nvim-dap sets dap.adapters.codelldb.", vim.log.levels.ERROR)
    return
  end

  dap.run({
    name = "Debug C/C++ Test",
    type = "codelldb",
    request = "launch",
    program = M.resolve_program,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  })
end

return M
