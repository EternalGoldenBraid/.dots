return {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
     -- or                              , branch = '0.1.x',
    config = function()
      require('telescope').setup{
        defaults = {
          preview = {
            treesitter = false
          }
        }
      }
      -- Disable folding in Telescope's result window.
      vim.api.nvim_create_autocmd("FileType", { pattern = "TelescopeResults", command = [[setlocal nofoldenable]] })
    end,
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter'
    },
  {
  },
      "nvim-telescope/telescope-file-browser.nvim",
      dependencies = { 
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim"
    }
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' 
  },
}
