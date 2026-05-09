return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      dir_path = "assets",
    },
  },
  keys = {
    { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
  },
}
