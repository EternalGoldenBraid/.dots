local M = {}

local function join_paths(...)
  return table.concat({ ... }, "/")
end

local function blob_to_lines(text)
  if text == nil or text == "" then
    return {}
  end

  local lines = vim.split(text, "\n", { plain = true, trimempty = false })

  if text:sub(-1) == "\n" then
    table.remove(lines)
  end

  return lines
end

local function read_text_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, string.format("BlobDiff failed to read %s", path)
  end

  return table.concat(lines, "\n"), nil
end

local function ensure_target_buffer(path)
  local current = vim.api.nvim_buf_get_name(0)
  if current ~= path then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end
end

local function configure_diff_window(win)
  vim.wo[win].foldenable = false
  vim.wo[win].foldmethod = "manual"
  vim.wo[win].foldcolumn = "0"
end

local function set_buffer_context(buf, context)
  vim.b[buf].blob_repo_root = context and context.repo_root or nil
  vim.b[buf].blob_relpath = context and context.relpath or nil
end

local function get_buffer_context(buf)
  local repo_root = vim.b[buf].blob_repo_root
  if repo_root == nil or repo_root == "" then
    return nil
  end

  return {
    repo_root = repo_root,
    relpath = vim.b[buf].blob_relpath,
    newpath = nil,
  }
end

local function set_snapshot_buffer(buf, display_name, text, filetype_hint, context)
  vim.api.nvim_buf_set_name(buf, display_name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, blob_to_lines(text))
  set_buffer_context(buf, context)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  local filetype = vim.filetype.match({ filename = filetype_hint })
  if filetype then
    vim.bo[buf].filetype = filetype
  end
end

local function open_text_view(display_name, text, filetype_hint, context)
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  set_snapshot_buffer(buf, display_name, text, filetype_hint, context)
end

local function open_text_diff(display_name, text, newpath, filetype_hint, context)
  ensure_target_buffer(newpath)
  local target_win = vim.api.nvim_get_current_win()
  vim.cmd("vert new")

  local buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  set_snapshot_buffer(buf, display_name, text, filetype_hint or newpath, context)

  vim.cmd("diffthis")
  configure_diff_window(source_win)
  vim.cmd("wincmd p")
  vim.cmd("diffthis")
  configure_diff_window(target_win)
end

local function read_blob_text(rev, path, repo_root)
  local result = vim.system({ "git", "show", string.format("%s:%s", rev, path) }, {
    text = true,
    cwd = repo_root,
  }):wait()

  if result.code ~= 0 then
    return nil, result.stderr or string.format("BlobDiff failed for %s:%s", rev, path)
  end

  return result.stdout, nil
end

local function open_blob_diff(rev, oldpath, newpath, context)
  local text, err = read_blob_text(rev, oldpath, context.repo_root)
  if not text then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  open_text_diff(string.format("blobdiff://%s:%s", rev, oldpath), text, newpath, oldpath, {
    repo_root = context.repo_root,
    relpath = oldpath,
  })
end

local function open_blob_view(rev, path, context)
  local text, err = read_blob_text(rev, path, context.repo_root)
  if not text then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  open_text_view(string.format("blobview://%s:%s", rev, path), text, path, {
    repo_root = context.repo_root,
    relpath = path,
  })
end

local function open_local_diff(oldpath, newpath)
  if oldpath == newpath then
    vim.notify("BlobDiff source file matches the current buffer", vim.log.levels.WARN)
    return
  end

  local text, err = read_text_file(oldpath)
  if not text then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  open_text_diff(string.format("blobdiff://local:%s", oldpath), text, newpath, oldpath)
end

local function open_local_view(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function selection_display_name(prefix, selection)
  if selection.kind == "local" then
    return string.format("%s://local:%s", prefix, selection.relpath)
  end

  return string.format("%s://%s:%s", prefix, selection.rev, selection.relpath)
end

local function selection_filetype_hint(selection)
  return selection.path or selection.relpath
end

local function read_selection_text(selection)
  if selection.kind == "local" then
    return read_text_file(selection.path)
  end

  return read_blob_text(selection.rev, selection.relpath, selection.repo_root)
end

local function open_selection_view(selection)
  if selection.kind == "local" then
    open_local_view(selection.path)
    return
  end

  local text, err = read_selection_text(selection)
  if not text then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  open_text_view(selection_display_name("blobview", selection), text,
    selection_filetype_hint(selection), {
      repo_root = selection.repo_root,
      relpath = selection.relpath,
    })
end

local function open_selection_diff(left_selection, right_selection)
  local left_text, left_err = read_selection_text(left_selection)
  if not left_text then
    vim.notify(left_err, vim.log.levels.ERROR)
    return
  end

  local right_text, right_err = read_selection_text(right_selection)
  if not right_text then
    vim.notify(right_err, vim.log.levels.ERROR)
    return
  end

  vim.cmd("tabnew")

  local right_buf = vim.api.nvim_get_current_buf()
  local right_win = vim.api.nvim_get_current_win()
  set_snapshot_buffer(right_buf, selection_display_name("blobdiff", right_selection), right_text,
    selection_filetype_hint(right_selection), {
      repo_root = right_selection.repo_root,
      relpath = right_selection.relpath,
    })

  vim.cmd("vert new")

  local left_buf = vim.api.nvim_get_current_buf()
  local left_win = vim.api.nvim_get_current_win()
  set_snapshot_buffer(left_buf, selection_display_name("blobdiff", left_selection), left_text,
    selection_filetype_hint(left_selection), {
      repo_root = left_selection.repo_root,
      relpath = left_selection.relpath,
    })

  vim.cmd("diffthis")
  configure_diff_window(left_win)
  vim.cmd("wincmd p")
  vim.cmd("diffthis")
  configure_diff_window(right_win)
end

local function run_git(args, cwd)
  local result = vim.system(args, {
    text = true,
    cwd = cwd,
  }):wait()

  if result.code ~= 0 then
    return nil, result.stderr or string.format("BlobDiff git command failed: %s", table.concat(args, " "))
  end

  return blob_to_lines(result.stdout), nil
end

local function get_repo_root(start_dir)
  local result = vim.system({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end

  return vim.trim(result.stdout)
end

local function relpath_from_repo(repo_root, path)
  if path == nil or path == "" then
    return nil
  end

  if path:sub(1, #repo_root) == repo_root then
    return path:sub(#repo_root + 2)
  end

  return vim.fn.fnamemodify(path, ":t")
end

local function get_current_context()
  local buffer_context = get_buffer_context(0)
  if buffer_context then
    return buffer_context
  end

  local newpath = vim.fn.expand("%:p")
  if newpath == "" then
    newpath = vim.api.nvim_buf_get_name(0)
  end

  local start_dir = newpath ~= "" and vim.fn.fnamemodify(newpath, ":h") or vim.fn.getcwd()
  local repo_root = get_repo_root(start_dir)
  if not repo_root then
    vim.notify("Blob commands require the current buffer, stored blob context, or working directory to be inside a git repository", vim.log.levels.ERROR)
    return nil
  end

  return {
    newpath = newpath ~= "" and newpath or nil,
    repo_root = repo_root,
    relpath = relpath_from_repo(repo_root, newpath),
  }
end

local function pick_with_telescope(title, entries, opts, on_select)
  opts = opts or {}

  local ok, pickers = pcall(require, "telescope.pickers")
  local ok_finders, finders = pcall(require, "telescope.finders")
  local ok_config, config = pcall(require, "telescope.config")
  local ok_actions, actions = pcall(require, "telescope.actions")
  local ok_state, action_state = pcall(require, "telescope.actions.state")

  if not (ok and ok_finders and ok_config and ok_actions and ok_state) then
    local items = {}
    for _, item in ipairs(entries) do
      items[#items + 1] = item.display or item
    end

    vim.ui.select(items, { prompt = title }, function(choice, idx)
      if choice == nil or idx == nil then
        return
      end

      local selected = entries[idx]
      on_select(selected.value or selected)
    end)
    return
  end

  local entry_maker = opts.entry_maker or function(item)
    local display = item.display or item
    local ordinal = item.ordinal or display
    return {
      value = item.value or item,
      display = display,
      ordinal = ordinal,
    }
  end

  pickers.new({}, {
    prompt_title = title,
    default_text = opts.default_text,
    finder = finders.new_table({
      results = entries,
      entry_maker = entry_maker,
    }),
    sorter = config.values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          on_select(selection.value, selection)
        end
      end)
      return true
    end,
  }):find()
end

local function pick_snapshot(context, title_prefix, on_select)
  pick_with_telescope(title_prefix .. " source", {
    { value = "local", display = "Local working tree" },
    { value = "commit", display = "Commit..." },
    { value = "origin", display = "Origin branch..." },
  }, nil, function(kind)
    if kind == "local" then
      local files, err = run_git({ "git", "ls-files", "--cached", "--others", "--exclude-standard" }, context.repo_root)
      if not files then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      pick_with_telescope(title_prefix .. " file", files, {
        default_text = context.relpath,
      }, function(relpath)
        on_select({
          kind = "local",
          repo_root = context.repo_root,
          relpath = relpath,
          path = join_paths(context.repo_root, relpath),
        })
      end)
      return
    end

    if kind == "commit" then
      local commits, err = run_git({
        "git",
        "log",
        "--date=short",
        "--pretty=format:%H%x09%h %ad %s",
      }, context.repo_root)
      if not commits then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      local entries = {}
      for _, line in ipairs(commits) do
        local hash, display = line:match("^([^\t]+)\t(.+)$")
        if hash and display then
          entries[#entries + 1] = {
            value = hash,
            display = display,
            ordinal = display,
          }
        end
      end

      pick_with_telescope(title_prefix .. " commit", entries, nil, function(rev)
        local files_at_rev, files_err = run_git({ "git", "ls-tree", "-r", "--name-only", rev }, context.repo_root)
        if not files_at_rev then
          vim.notify(files_err, vim.log.levels.ERROR)
          return
        end

        pick_with_telescope(string.format("%s file @ %s", title_prefix, rev:sub(1, 7)), files_at_rev, {
          default_text = context.relpath,
        }, function(relpath)
          on_select({
            kind = "blob",
            repo_root = context.repo_root,
            relpath = relpath,
            rev = rev,
          })
        end)
      end)
      return
    end

    local branches, err = run_git({
      "git",
      "for-each-ref",
      "--format=%(refname:short)",
      "refs/remotes/origin",
    }, context.repo_root)
    if not branches then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    local branch_entries = {}
    for _, branch in ipairs(branches) do
      if branch ~= "origin/HEAD" then
        branch_entries[#branch_entries + 1] = branch
      end
    end

    pick_with_telescope(title_prefix .. " origin branch", branch_entries, {
      default_text = "origin/",
    }, function(rev)
      local files_at_rev, files_err = run_git({ "git", "ls-tree", "-r", "--name-only", rev }, context.repo_root)
      if not files_at_rev then
        vim.notify(files_err, vim.log.levels.ERROR)
        return
      end

      pick_with_telescope(string.format("%s file @ %s", title_prefix, rev), files_at_rev, {
        default_text = context.relpath,
      }, function(relpath)
        on_select({
          kind = "blob",
          repo_root = context.repo_root,
          relpath = relpath,
          rev = rev,
        })
      end)
    end)
  end)
end

local function open_picker_diff()
  local context = get_current_context()
  if not context then
    return
  end

  pick_snapshot(context, "BlobDiff left", function(left_selection)
    pick_snapshot({
      repo_root = context.repo_root,
      relpath = left_selection.relpath or context.relpath,
      newpath = nil,
    }, "BlobDiff right", function(right_selection)
      open_selection_diff(left_selection, right_selection)
    end)
  end)
end

local function open_picker_view()
  local context = get_current_context()
  if not context then
    return
  end

  pick_snapshot(context, "BlobView", function(selection)
    open_selection_view(selection)
  end)
end

function M.setup()
  if vim.fn.exists(":BlobDiff") == 2 then
    return
  end

  vim.api.nvim_create_user_command("BlobDiff", function(opts)
    if #opts.fargs == 0 then
      open_picker_diff()
      return
    end

    if #opts.fargs ~= 3 then
      vim.notify("BlobDiff expects either 0 arguments or exactly 3 arguments: <rev> <oldpath> <newpath>", vim.log.levels.ERROR)
      return
    end

    local repo_root = get_repo_root(vim.fn.getcwd())
    open_blob_diff(opts.fargs[1], opts.fargs[2], opts.fargs[3], {
      repo_root = repo_root,
      relpath = opts.fargs[2],
    })
  end, { nargs = "*", desc = "Diff a git blob or selected source against a file" })

  vim.api.nvim_create_user_command("BlobView", function(opts)
    if #opts.fargs == 0 then
      open_picker_view()
      return
    end

    if #opts.fargs ~= 2 then
      vim.notify("BlobView expects either 0 arguments or exactly 2 arguments: <rev> <path>", vim.log.levels.ERROR)
      return
    end

    local repo_root = get_repo_root(vim.fn.getcwd())
    open_blob_view(opts.fargs[1], opts.fargs[2], {
      repo_root = repo_root,
      relpath = opts.fargs[2],
    })
  end, { nargs = "*", desc = "Open a git blob or selected source in a normal buffer" })
end

return M
