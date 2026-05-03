-- Auto-update Mason packages periodically (daily)
-- Prevents LSP tools from going stale (e.g. gopls lagging behind Go releases).
-- Checks once per day on VeryLazy, updates any outdated packages in the background.

return {
  "williamboman/mason.nvim",
  opts = function(_, opts)
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        local state_file = vim.fn.stdpath("state") .. "/mason-last-update"
        local now = os.time()
        local last = 0

        local f = io.open(state_file, "r")
        if f then
          last = tonumber(f:read("*a")) or 0
          f:close()
        end

        -- Check at most once per day
        if now - last < 86400 then
          return
        end

        f = io.open(state_file, "w")
        if f then
          f:write(tostring(now))
          f:close()
        end

        vim.defer_fn(function()
          local registry = require("mason-registry")

          -- Ensure registry is fresh before checking versions
          registry.update(function(ok)
            if not ok then
              return
            end

            local installed = registry.get_installed_packages()
            for _, pkg in ipairs(installed) do
              pkg:check_new_version(function(has_new, version)
                if has_new then
                  vim.notify("Mason: updating " .. pkg.name .. " to " .. (version.latest_version or "latest"), vim.log.levels.INFO)
                  pkg:install()
                end
              end)
            end
          end)
        end, 5000) -- 5s delay to not block startup
      end,
    })
    return opts
  end,
}
