return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<C-n>",
      "<cmd>Yazi<cr>",
      desc = "Open Yazi (File Manager)",
    },
  },
  opts = {
    open_for_directories = true,
  },
}
