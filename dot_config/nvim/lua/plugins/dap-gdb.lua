-- GDB's native DAP server (gdb >= 14) for C/C++.
-- LazyVim's clangd extra already registers codelldb; this prepends a gdb
-- config so it's the default pick in the config list.
return {
  "mfussenegger/nvim-dap",
  optional = true,
  opts = function()
    local dap = require("dap")

    dap.adapters.gdb = {
      type = "executable",
      command = "gdb",
      args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }

    local function exe()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
    end

    for _, lang in ipairs({ "c", "cpp" }) do
      dap.configurations[lang] = dap.configurations[lang] or {}
      table.insert(dap.configurations[lang], 1, {
        name = "gdb: launch",
        type = "gdb",
        request = "launch",
        program = exe,
        args = {}, -- <leader>da prompts for these; <leader>dc runs with none
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      })
      table.insert(dap.configurations[lang], 2, {
        name = "gdb: attach to process",
        type = "gdb",
        request = "attach",
        pid = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      })
    end
  end,
}
