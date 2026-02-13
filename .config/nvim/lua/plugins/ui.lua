-- ultisnips.lua
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local ok, p = pcall(require, "theme.generated_palette")
      if not ok then
        return { style = "moon" }
      end

      return {
        style = "moon",
        on_colors = function(c)
          c.bg = p.bg
          c.bg_dark = p.violet
          c.bg_float = p.inactive_bg
          c.bg_highlight = p.inactive_bg
          c.fg = p.fg
          c.fg_dark = p.semilightgray
          c.border = p.orange
          c.comment = p.semilightgray
          c.blue = p.orange
          c.green = p.green
          c.red = p.red
          c.magenta = p.violet
          c.teal = p.green
        end,
      }
    end,
  }
}
