-- ~/.config/nvim/lua/plugins/dashboard.lua

local direwolf = [[
                                ▄                         █▄▄        
               ▄▄               ██▄                       ████       
              █▀▓▒▄        █▄▄  ▐█▓█                      █▓▓█       
▄▓▓▄▄ ▄▄▄      ▀▀▀  ▄▓▓▄▄  ▒░██  ▓▓▓▒       ▄▄█▓██▓█▄▄   ▄▓▓▒▒ ▄▄▄   
 ▀▒░█▀▀█▓▒▄   ▄█▓▒  ▀▒▓▒░  ▒▒░█  ▒▒░█      ▓▀▓▓▀  ▀▓▓█▓   ▀▒░█▀▀█▓▒▄ 
 ▒░██   ▒░░▄  ▓▒░█   ▀░▒░▒▄█▒▀   ░███     ▒▒░░      ░░▒▒  ▒░██   ▒░░▄
 ░███   ░██▀  ▒░██    ▄▒▒▀██░▒▄  ████     ▀░░█▄    ▄█░░█  ░███   ░██▀
 ███▀   ██▀   ░███▀  ▄░░▀  ▒░▓█  ▀█▄██▄▄▀   ▀███▄▄██████  ████▌ ▐██▀ 
 █▀   ▄▀▀      ▀▀▀  ▐███   ░▓█▀    ▀▀▀▀       ▀▀▀▀▀▀ ▀▀▀  █▀ ▀███▀   
                    ▀███▌  █▀                                        
                      ▀▀                                             
]]

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard.preset.header = direwolf

      table.insert(opts.dashboard.preset.keys, 3, {
        icon = "󰉋 ",
        key = "y",
        desc = "Yazi File Manager",
        action = ":Yazi",
      })
    end,
  },
  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      opts.config.header = vim.split(direwolf, "\n")
      table.insert(opts.config.center, 3, {
        action = "Yazi",
        desc = " Yazi File Manager",
        icon = "󰉋 ",
        key = "y",
      })
    end,
  },
}
