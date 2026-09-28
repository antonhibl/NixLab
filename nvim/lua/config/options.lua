local opt = vim.opt

vim.env.TERM = "xterm-256color"
opt.termguicolors = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true

opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldminlines = 2

opt.swapfile = false
opt.backup = false
opt.writebackup = false
