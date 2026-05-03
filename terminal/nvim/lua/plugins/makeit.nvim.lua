return {
  { -- This plugin
    "nodeselector/makeit.nvim",
    cmd = { "MakeitOpen", "MakeitToggleResults", "MakeitRedo" },
    dependencies = { "stevearc/overseer.nvim" },
    opts = {},
    keys = {
      { "<leader>me", "<cmd>MakeitOpen<cr>", desc = "Explore make directives" },
      { "<leader>mp", "<cmd>MakeitToggleResults<cr>", desc = "Toggle panel" },
      { "<leader>mr", "<cmd>MakeitRedo<cr>", desc = "Rerun last" },
    },
  },
  { -- The task runner we use
    "stevearc/overseer.nvim",
    commit = "400e762648b70397d0d315e5acaf0ff3597f2d8b",
    cmd = { "MakeitOpen", "MakeitToggleResults", "MakeitRedo" },
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
    },
  },
}
