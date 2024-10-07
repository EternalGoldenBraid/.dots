-- ultisnips.lua
return {
  -- {
  --   "Olical/conjure",
  --   ft = { "clojure", "fennel", "python" }, -- etc
  --   lazy = true,
  --   init = function()
  --     -- Set configuration options here
  --     -- Uncomment this to get verbose logging to help diagnose internal Conjure issues
  --     -- This is VERY helpful when reporting an issue with the project
  --     -- vim.g["conjure#debug"] = true
  --   end,
  --
  --   -- Optional cmp-conjure integration
  --   dependencies = { "PaterJason/cmp-conjure" },
  -- },
  {
    "PaterJason/cmp-conjure",
    lazy = true,
    config = function()
      local cmp = require("cmp")
      local config = cmp.get_config()
      table.insert(config.sources, { name = "conjure" })
      return cmp.setup(config)
    end,
  },
  {
    "folke/zen-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- Set width
      width = 1,
      height = 1,
      -- backdrop=0.95,
      backdrop=1.00,
    }
  },
  {
  "github/copilot.vim",
  config = function()
  end
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      -- { "github/copilot.lua" }, -- or github/copilot.vim
      { "github/copilot.vim" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    opts = {
      debug = false, 
      window = {
          layout = 'float',
          relative = 'cursor',
          width = 0.8,
          height = 0.8,
          row = 1
    },
    mappings = {
      reset = {
        normal = '',
        insert = ''
      }
    }
      -- See Configuration section for rest
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  {
      'sindrets/diffview.nvim',
      cmd = 'DiffviewOpen',
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
       "nvim-treesitter/nvim-treesitter",
       "nvim-tree/nvim-web-devicons"
    },
    config = function() require('aerial').setup() end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",  -- This runs TSUpdate after installation
    config = function()
      require("nvim-treesitter.configs").setup({
        -- ensure_installed = "all",  -- Automatically install all maintained parsers
        ensure_installed = {
          "bash", "c", "cpp", "markdown",
          "css", "html", "javascript", "toml",
          "yaml", "json", "lua", "regex",
          "python", "rust", "latex",
        },
        highlight = { 
          enable = true,
          -- disable = {"tex", "latex"}, 
        },
        indent = { 
          enable = true,
          -- disable = {"tex", "latex"}, 
        },
      })
    end
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
      'windwp/nvim-autopairs',
      event = "InsertEnter",
      config = true
      -- use opts = {} for passing setup options
      -- this is equalent to setup({}) function
  },
  {
      "kylechui/nvim-surround",
      version = "*", -- Use for stability; omit to use `main` branch for the latest features
      event = "VeryLazy",
      config = function()
          require("nvim-surround").setup({
              -- Configuration here, or leave empty to use defaults
          })
      end
  },
  {
    "ms-jpq/coq.artifacts",
    branch = "artifacts",
    event = "VimEnter"
    -- No specific Lua configuration required for artifacts, they just need to be included
  },
  {
    "ms-jpq/coq.thirdparty",
    branch = "3p",
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

  -- Debugging
  {
    "mfussenegger/nvim-dap",
    config = function()
    end
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function()
      require("dap").adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }
      require("dap-python").setup("~/venvs/debugpy/bin/python")
      require("dap-python").test_runner = "pytest"
      require("dap-python").setup()
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"}
  },
  -- { 
  --   "folke/neodev.nvim",
  --   opts = {},
  --   config = function()
  --     require("neodev").setup({
  --       library = { plugins = { "nvim-dap-ui" }, types = true },
  --     })
  --   end
  -- },

}
