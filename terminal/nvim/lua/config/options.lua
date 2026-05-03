-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.root_spec = { "cwd" }
vim.g.autoformat = false

-- Terminal title: ✎ project/filename
vim.opt.title = true
vim.opt.titlestring = "✎ %{fnamemodify(getcwd(), ':t')}/%t"
