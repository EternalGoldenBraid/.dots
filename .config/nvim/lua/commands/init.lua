local M = {
  did_setup = false,
}

function M.setup()
  if M.did_setup then
    return
  end

  require("commands.blob_diff").setup()

  M.did_setup = true
end

return M
