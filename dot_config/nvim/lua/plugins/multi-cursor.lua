-- Edits happen at the main cursor; the rest catch up via dot-repeat on <Esc>.
-- No insert-mode remaps, so blink.cmp's <CR> keeps working.
local function mc(fn, ...)
  local args = { ... }
  return function()
    require("multicursor-nvim")[fn](unpack(args))
  end
end

return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  -- Defined via `keys` so LazyVim's <C-Up>/<C-Down> window resize maps skip these.
  keys = {
    { "<C-n>", mc("matchAddCursor", 1), mode = { "n", "x" }, desc = "Add cursor at next match" },
    { "<C-Down>", mc("lineAddCursor", 1), mode = { "n", "x" }, desc = "Add cursor below" },
    { "<C-Up>", mc("lineAddCursor", -1), mode = { "n", "x" }, desc = "Add cursor above" },
    { "<C-LeftMouse>", mc("handleMouse"), desc = "Add/remove cursor" },
    { "<C-LeftDrag>", mc("handleMouseDrag") },
    { "<C-LeftRelease>", mc("handleMouseRelease") },
    { "<leader>mA", mc("matchAllAddCursors"), mode = { "n", "x" }, desc = "Add cursors at all matches" },
    { "<leader>ma", mc("alignCursors"), desc = "Align cursors" },
    { "<leader>mr", mc("restoreCursors"), desc = "Restore cleared cursors" },
    { "S", mc("splitCursors"), mode = "x", desc = "Split selection into cursors by regex" },
    { "M", mc("matchCursors"), mode = "x", desc = "Add cursors at regex matches in selection" },
  },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    -- Only active while there are multiple cursors.
    mc.addKeymapLayer(function(set)
      set({ "n", "x" }, "q", function() mc.matchSkipCursor(1) end)
      set({ "n", "x" }, "Q", mc.deleteCursor)
      set({ "n", "x" }, "<Left>", mc.prevCursor)
      set({ "n", "x" }, "<Right>", mc.nextCursor)
      set("n", "<Esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}
