return {
  {
  	"L3MON4D3/LuaSnip",
  	-- follow latest release.
  	version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  	-- install jsregexp (optional!).
  	build = "make install_jsregexp"
  },
  {
    "iurimateus/luasnip-latex-snippets.nvim",
    dependencies = { "L3MON4D3/LuaSnip", "lervag/vimtex" },
    config = function()
      require("luasnip-latex-snippets").setup( { use_treesitter = true } )
      require("luasnip").config.setup { enable_autosnippets = true }
    end,
  }

}
