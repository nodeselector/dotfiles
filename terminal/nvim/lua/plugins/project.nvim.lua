return {
  { "nvim-telescope/telescope.nvim", tag = "0.1.8" },
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({})
    end,
    keys = {
      { "<leader>pp", "<cmd>Telescope projects<cr>", desc = "Switch between project files" },
      { "<leader>pl", "<cmd>Telescope projects<cr>", desc = "Switch between project files" },
    },
  },
}
