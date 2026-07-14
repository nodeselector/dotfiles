-- Branch diff file picker: browse files changed between current branch and base.
-- Uses fzf-lua to list `git diff --name-only` against the merge-base.

return {
  "ibhagwan/fzf-lua",
  optional = true,
  keys = {
    {
      "<leader>bg",
      function()
        local fzf = require("fzf-lua")

        -- Detect repository default/base branch for diffing.
        -- Deliberately ignores @{upstream} — pushed feature branches track
        -- origin/<same-name>, making merge-base HEAD (empty diff).
        local function get_base_branch()
          -- Prefer origin/HEAD (set by git clone or `git remote set-head`)
          local origin_head = vim.fn.systemlist("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null")[1]
          if vim.v.shell_error == 0 and origin_head and origin_head ~= "" then
            return origin_head:gsub("^refs/remotes/", "")
          end
          -- Fall back: check if origin/main exists
          local main_check = vim.fn.systemlist("git rev-parse --verify origin/main 2>/dev/null")[1]
          if vim.v.shell_error == 0 and main_check and main_check ~= "" then
            return "origin/main"
          end
          -- Fall back: check if origin/master exists
          local master_check = vim.fn.systemlist("git rev-parse --verify origin/master 2>/dev/null")[1]
          if vim.v.shell_error == 0 and master_check and master_check ~= "" then
            return "origin/master"
          end
          return nil
        end

        local base = get_base_branch()
        if not base then
          vim.notify("No base branch found (tried origin/HEAD, origin/main, origin/master)", vim.log.levels.WARN)
          return
        end

        local merge_base = vim.fn.systemlist("git merge-base HEAD " .. base)
        if vim.v.shell_error ~= 0 or not merge_base[1] or merge_base[1] == "" then
          vim.notify("Could not find merge-base with " .. base, vim.log.levels.WARN)
          return
        end
        merge_base = merge_base[1]

        local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
          vim.notify("Not inside a git repository", vim.log.levels.WARN)
          return
        end

        fzf.fzf_exec("git diff --name-only " .. merge_base, {
          prompt = "Branch changes (" .. base .. ")❯ ",
          cwd = git_root,
          preview = "git diff " .. merge_base .. " -- " .. git_root .. "/{} | delta --line-numbers 2>/dev/null || git diff " .. merge_base .. " -- " .. git_root .. "/{}",
          actions = fzf.defaults.actions.files,
        })
      end,
      desc = "Changed files (branch diff)",
    },
  },
}
