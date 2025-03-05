-- firenvim.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins"},
  require("plugins/firenvim"),
})

-- -- Hide status line
-- vim.opt.laststatus = 0
--
-- -- Firenvim configuration
-- vim.g.firenvim_config = {
--     localSettings = {
--         [".*"] = {
--             takeover = "never",
--         },
--     },
-- }
--
-- vim.keymap.set("n", "<leader>nf", function()
--     vim.cmd("FirenvimActivate")
-- end, { desc = "Activate Firenvim manually" })
