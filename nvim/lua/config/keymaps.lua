local map = vim.keymap.set

map("n", "<C-x><C-s>", "<cmd>w<cr>", { desc = "Save" })
map("n", "<C-x><C-c>", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<C-x>0", "<cmd>q<cr>", { desc = "Close Window" })
map("n", "<C-x>1", "<cmd>only<cr>", { desc = "Close Other Windows" })

map("n", "<C-x>2", "<cmd>split<cr>", { desc = "Split Horizontal" })
map("n", "<C-x>3", "<cmd>vsplit<cr>", { desc = "Split Vertical" })

map("n", "<C-x><C-f>", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<C-c>t", "<cmd>terminal<cr>", { desc = "Open Terminal" })
map("n", "<C-c>g", "<cmd>LazyGit<cr>", { desc = "Open LazyGit" })

map("n", "<C-n><C-t>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<C-g><C-t>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
