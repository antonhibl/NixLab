if not vim.env.NIXLAB_NVIM_PLUGINS then
  return {}
end

return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.install_dir = vim.env.NIXLAB_TS_DIR
      opts.ensure_installed = {}
    end,
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
      local configs = {
        {
          name = "Launch (gdb)",
          type = "gdb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = true,
        },
        {
          name = "Attach to process (gdb)",
          type = "gdb",
          request = "attach",
          pid = require("dap.utils").pick_process,
        },
      }
      dap.configurations.c = configs
      dap.configurations.cpp = configs
    end,
  },
}
