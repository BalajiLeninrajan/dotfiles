return {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle", -- Load on demand when you use the command
    config = function()
      -- Optional: Configure persistent undo
      if vim.fn.has("persistent_undo") == 1 then
        local undodir = vim.fn.expand("~/.local/share/nvim/undodir")
        vim.fn.mkdir(undodir, "p")
        vim.opt.undodir = undodir
        vim.opt.undofile = true
      end
    end,
    keys = {
      { "<leader>z", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undo Tree" },
    },
  },
}
