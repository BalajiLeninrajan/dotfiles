return {
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- Use Zathura as PDF viewer with synctex support
      vim.g.vimtex_view_method = "zathura"

      -- Enable synctex for forward/inverse search
      vim.g.vimtex_view_forward_search_on_start = true
    end,
  },
}
