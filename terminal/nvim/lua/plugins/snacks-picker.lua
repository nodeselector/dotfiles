-- Follow symlinks in file pickers (fzf-lua + snacks)
-- Without this, symlinked directories show zero results in find_files and live_grep.

return {
  -- fzf-lua: active picker (LazyVim default)
  {
    "ibhagwan/fzf-lua",
    optional = true,
    opts = {
      files = {
        fd_opts = "--color=never --type f --type l --exclude .git -L",
        rg_opts = '--color=never --files -g "!.git" -L',
        find_opts = "-type f -follow \\! -path '*/.git/*'",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -L -e",
      },
    },
  },
  -- snacks.picker: fallback if used instead
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        follow = true,
      })
      opts.picker.sources.grep = vim.tbl_deep_extend("force", opts.picker.sources.grep or {}, {
        follow = true,
      })
    end,
  },
}
