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

        -- Detect base branch: upstream tracking target, or fall back to main/master
        local function get_base_branch()
          -- Try the upstream of the current branch (e.g. origin/main)
          local upstream = vim.fn.systemlist("git rev-parse --abbrev-ref @{upstream} 2>/dev/null")[1]
          if upstream and upstream ~= "" and not upstream:match("^fatal") then
            return upstream
          end
          -- Fall back to origin HEAD (usually main)
          local origin_head = vim.fn.systemlist("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null")[1]
          if origin_head and origin_head ~= "" and not origin_head:match("^fatal") then
            return origin_head:gsub("^refs/remotes/", "")
          end
          return "origin/main"
        end

        local base = get_base_branch()
        local merge_base = vim.fn.systemlist("git merge-base HEAD " .. base)[1]
        if not merge_base or merge_base == "" then
          vim.notify("Could not find merge-base with " .. base, vim.log.levels.WARN)
          return
        end

        local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

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
