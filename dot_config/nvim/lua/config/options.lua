-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- The shell exports JAVA_HOME=temurin-8-jdk for Hadoop/Maven, but jdtls needs
-- Java 21+ and metals needs 9+ for --add-opens. Point nvim at a modern JDK;
-- the shell keeps 8.
vim.env.JAVA_HOME = "/usr/lib/jvm/java-25-openjdk"
