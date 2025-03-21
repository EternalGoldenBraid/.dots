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
  require("plugins/ui"),
  -- require("plugins/ultisnips"),
  require("plugins/luasnips"),
  require("plugins/obsidian_nvim"),
  require("plugins/coding"),
  require("plugins/telescope"),
  require("plugins/vimtex"),
})
-- require('Comment').setup()
