return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
  --   "BufReadPre path/to/my-vault/**.md",
  --   "BufNewFile path/to/my-vault/**.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "brain",
        path = "/home/nicklas/brain",
        -- path = "~/brain",
      },
    },
    disable_frontmatter = true,
    -- see below for full list of options 👇

    -- Mappings TODO

    -- Templates
    templates = {
      folder = "Templates",
      date_format = "%d-%m-%Y",
      time_format = "%H:%M",
    }
    
  },

  log_level = vim.log.levels.INFO,

  -- config = function()
  --   require("nvim-treesitter.configs").setup({
  --     ensure_installed = { "markdown", "markdown_inline" },
  --     highlight = {
  --       enable = true,
  --     },
  --   })
  -- end,
}
