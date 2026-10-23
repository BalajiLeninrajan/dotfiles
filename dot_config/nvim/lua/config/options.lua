-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- The shell exports JAVA_HOME=temurin-8-jdk for Hadoop/Maven, but jdtls needs
-- Java 21+ and metals needs 9+ for --add-opens. Point nvim at a modern JDK;
-- the shell keeps 8.
vim.env.JAVA_HOME = "/usr/lib/jvm/java-25-openjdk"

-- Open PDFs in the system viewer (zathura) instead of loading the bytes as
-- text. This lives here, not in autocmds.lua, because autocmds.lua loads on
-- VeryLazy, after `nvim file.pdf` has already read the file.
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "*.pdf",
  callback = function(ev)
    vim.ui.open(vim.fn.fnamemodify(ev.file, ":p"))
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.api.nvim_buf_delete(ev.buf, { force = true })
      end
    end)
  end,
})
