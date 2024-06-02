return {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
     -- or                              , branch = '0.1.x',
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
  }
}
