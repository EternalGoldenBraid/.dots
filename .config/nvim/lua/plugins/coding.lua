-- ultisnips.lua
return {
  {
  "github/copilot.vim",
  config = function()
  end
  },
  {
      'numToStr/Comment.nvim',
      opts = {
          -- add any options here
      },
      lazy = false,
  },

  -- From https://forem.julialang.org/navi/set-up-neovim-tmux-for-a-data-science-workflow-with-julia-3ijk
  {
      "jpalardy/vim-slime",
      config = function()
      end
  },
  {
    'stevearc/aerial.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = {
       -- "nvim-treesitter/nvim-treesitter",
       {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
          require("nvim-treesitter.configs").setup({
            ensure_installed = "all", -- or specify languages like { "c", "lua", "vim" }
            highlight = { enable = true },
            indent = { enable = true }
          })
       end},
       "nvim-tree/nvim-web-devicons"
    },
    config = function() require('aerial').setup() end
  },
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    event = "VimEnter",
    config = function()
      require("coq") -- initialize the coq plugin
    end
  },
  {
    "ms-jpq/coq.artifacts",
    branch = "artifacts",
    event = "VimEnter"
    -- No specific Lua configuration required for artifacts, they just need to be included
  },
  {
    "dense-analysis/ale",
    event = "VimEnter",
    config = function()
      vim.g.ale_fix_on_save = 0  -- Automatically fix issues when saving files
      vim.g.ale_linters_explicit = 1  -- Only use linters that are explicitly enabled
      vim.g.ale_lint_on_enter = 1  -- Lint files when first opened

      -- Enable specific linters and fixers
      vim.g.ale_linters = {
        python = {
          -- 'flake8', 
          'pyright',
        },
      }

      vim.g.ale_fixers = {
        ['*'] = {'remove_trailing_lines', 'trim_whitespace'},  -- Universal fixers
        python = {'black', 'isort'},  -- Python specific fixers
      }
    end
  },
  {
    "folke/zen-mode.nvim",
    opts = 
    {
      window = { width = 120, } 
    }
  },
}
