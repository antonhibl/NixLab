-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  {
    "maxmx03/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local dracula = require("dracula")

      dracula.setup({
        on_highlights = function(colors, color)
          return {
            SnacksDashboardHeader = { fg = colors.green },
            DashboardHeader = { fg = colors.green },
          }
        end,
      })

      vim.cmd.colorscheme("dracula")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
