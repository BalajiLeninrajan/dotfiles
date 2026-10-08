-- Cforall (cs343): .cfa sources and .hfa headers.
--
-- clangd can't parse CFA syntax (`for ( i; n )`, `with ( s )` clauses,
-- `suspend;`, `?{}` constructors), so .cfa/.hfa get their own filetype. clangd
-- only attaches to c/cpp, so the new filetype keeps its false errors out.
-- Highlighting borrows the C++ tree-sitter parser: CFA's try/catch and
-- references parse better as C++ than as C, and the parts that don't parse
-- just show up unhighlighted. Indent uses cindent instead: tree-sitter's
-- indent rules misfire inside the ERROR nodes CFA syntax produces (a new line
-- under `for () {` landed 3 columns too deep).
--
-- Language features come from cfa-lsp (~/Documents/code/cfa-lsp), built on a
-- fork of the CFA translator: compiler diagnostics as you type, and hover,
-- go-to-definition, references, completion, signature help and semantic
-- tokens from the translator's resolved AST.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.filetype.add({ extension = { cfa = "cfa", hfa = "cfa" } })
      vim.treesitter.language.register("cpp", "cfa")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "cfa",
        callback = function(ev)
          vim.bo[ev.buf].commentstring = "// %s"
          pcall(vim.treesitter.start, ev.buf, "cpp")
          -- Not "" with 'cindent': LazyVim's FileType handler replaces an
          -- indentexpr still at its global default with the tree-sitter one.
          vim.bo[ev.buf].indentexpr = "cindent(v:lnum)"
        end,
      })
    end,
  },
  {
    -- C snippets (#ifndef, #def, main, struct, for, ...) in CFA buffers, on top
    -- of the CFA ones in ~/.config/nvim/snippets/cfa.json.
    "saghen/blink.cmp",
    opts = {
      sources = {
        providers = {
          snippets = { opts = { extended_filetypes = { cfa = { "c" } } } },
        },
      },
    },
  },
  {
    -- Snacks, lualine, etc. get icons from mini.icons. Reuse its C glyphs in
    -- other colors so CFA files stand out from C: .cfa (and the cfa filetype)
    -- gets the .c glyph in red, .hfa the .h glyph in orange (peach in catppuccin).
    "nvim-mini/mini.icons",
    opts = {
      extension = {
        cfa = { glyph = "󰙱", hl = "MiniIconsRed" },
        hfa = { glyph = "󰫵", hl = "MiniIconsOrange" },
      },
      filetype = {
        cfa = { glyph = "󰙱", hl = "MiniIconsRed" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cfa_lsp = {
          mason = false, -- installed with `make install`, not Mason
          cmd = { "cfa-lsp" },
          filetypes = { "cfa" },
          root_markers = { "cfa_flags.txt", "Makefile", ".git" },
        },
      },
    },
  },
}
