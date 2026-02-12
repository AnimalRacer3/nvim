-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Project Creator
local project_gen = require("config.project")
vim.keymap.set("n", "<leader>cp", project_gen.create_project, { desc = "Create new project (interactive)" })

-- Github commands
local git = require("config.git_commands")
vim.keymap.set("n", "<leader>g<C-p>", git.GitPushSmart, { desc = "Push current changes to repo or create new repo." })
vim.keymap.set("n", "<leader>gn", git.GitNewBranch, { desc = "Create new branch" })

-- New Split commands
vim.keymap.set("n", "<leader>Sv", ":vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>Sh", ":split<CR>", { desc = "Split horizontally" })

-- toggling NvimTree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- Save all
vim.keymap.set("n", "<leader>w", "<cmd>wa<cr>", { desc = "Write all" })
