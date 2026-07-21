-- ultisnips.lua
local treesitter_languages = {
  "bash", "c", "cpp", "markdown", "markdown_inline",
  "css", "html", "javascript", "toml",
  "yaml", "json", "lua", "regex",
  "python", "rust", "latex",
}

local treesitter_filetypes = {
  "bash", "c", "cpp", "css", "html", "javascript",
  "json", "lua", "markdown", "python", "rust",
  "sh", "tex", "toml", "yaml", "zsh",
}

return {
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
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        auth_provider_url = "https://nestai.ghe.com/",
        
        -- 1. Filetypes (Replacement for vim.g.copilot_filetypes)
        -- By default it runs on all files. If you want to FORCE it for markdown:
        filetypes = {
          markdown = true, 
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ["."] = false,
        },
  
        -- 2. Ghost Text & Keymaps (Replacement for vim.api mappings)
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            -- Your old <C-J> mapping to accept
            accept = "<C-J>", 
            
            -- Your old <C-L> mapping to accept just one word
            accept_word = "<C-L>", 
            
            -- Standard defaults you might want
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- Ensure load order
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      debug = false,
      window = {
        layout = "float",
        relative = "cursor",
        width = 0.8,
        height = 0.8,
        row = 1,
      },
      mappings = {
        reset = {
          normal = "",
          insert = "",
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      input = {},
      picker = {},
      terminal = {},
      gitbrowse = {
        open = function(url)
          vim.fn.setreg("+", url)
          vim.notify("Git URL copied to clipboard: " .. url, vim.log.levels.INFO)
        end,
      },
    },
    keys = {
      { "<leader>gb", function() require("snacks").gitbrowse() end, mode = { "n", "v" }, desc = "Copy GitHub/GitLab link" },
    },
  },
  {
      "sindrets/diffview.nvim",
      cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggleFiles",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
        "DiffviewFileHistory",
      },
      keys = {
        { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
        { "<leader>gD", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "Diffview vs HEAD~1" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File History (Current File)" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Repo File History" },
        { "<leader>gf", "<cmd>DiffviewToggleFiles<CR>", desc = "Diffview Toggle File Panel" },
        { "<leader>gF", "<cmd>DiffviewFocusFiles<CR>", desc = "Diffview Focus File Panel" },
        { "<leader>gr", "<cmd>DiffviewRefresh<CR>", desc = "Diffview Refresh" },
        { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Diffview Close" },
      },
  },
  {
      'numToStr/Comment.nvim',
      opts = {
          -- add any options here
      },
      lazy = false,
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
    branch = "main",
    lazy = false,
    build = function()
      local treesitter = require("nvim-treesitter")
      treesitter.install(treesitter_languages):wait(300000)
      treesitter.update(treesitter_languages):wait(300000)
    end,
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()

      local group = vim.api.nvim_create_augroup("nfianda-treesitter", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = treesitter_filetypes,
        callback = function(args)
          vim.treesitter.start(args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
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
      "neovim/nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })

        vim.diagnostic.config({
          virtual_text = { source = "if_many" },
          float = { source = true },
        })
    
        -- PYRIGHT
        vim.lsp.config("pyright", {
          settings = {
            python = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic", -- "standard"/"strict" are basedpyright terms
                reportUnusedImport = "none",
                reportUnusedVariable = "none",
              },
            },
          },
        })

        -- BASEDPYRIGHT
        vim.lsp.config("basedpyright", {
          settings = {
            basedpyright = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "standard", -- or "strict"
                reportUnusedImport = "none",
                reportUnusedVariable = "none",
              },
            },
            -- Some setups also honor this block:
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        })
    
        -- Enable exactly ONE of these:
        vim.lsp.enable("pyright")
        -- vim.lsp.enable("basedpyright")

        vim.lsp.config("ruff", {})
        vim.lsp.enable("ruff")

        -- C / C++
        -- sudo pacman -S clang llvm

        vim.lsp.config("clangd", {
          cmd = {
              "clangd",
              "--background-index",
              "--clang-tidy",
              "--completion-style=detailed",
              "--header-insertion=iwyu",
              "--header-insertion-decorators",
          },
          filetypes = { "c", "cpp", "objc", "objcpp" },
          root_markers = {
            "compile_commands.json",
            "compile_flags.txt",
            ".git",
          },
        })

      vim.lsp.enable("clangd")


      end,
    },


  -- Debugging
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
    opts = {
      ensure_installed = { "codelldb" },
      automatic_installation = true,
    },
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      require("plugin_settings.coding.cpp").setup_dap(require("dap"))
    end
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function()
      require("plugin_settings.coding.python").setup_dap_python()
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"}
  },
}
