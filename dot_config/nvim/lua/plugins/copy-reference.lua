return {
  {
    "cajames/copy-reference.nvim",
    opts = {},
    keys = {
      { "yr", "<cmd>CopyReference line<cr>", mode = { "n", "v" }, desc = "Copy file:line reference" },
      { "yf", "<cmd>CopyReference file<cr>", mode = { "n", "v" }, desc = "Copy file path" },
    },
  },
}
