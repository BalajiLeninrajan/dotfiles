-- Make pyright understand uv-style monorepos (one .venv per subproject,
-- cross-project imports written relative to the repo root).
--
-- Neovim starts one pyright client per root_dir (the nearest pyproject.toml),
-- so each subproject gets its own client. For each one:
--   * pythonPath -> <root_dir>/.venv/bin/python, if it exists. Pyright never
--     auto-detects .venv (verified with the CLI); before this only uv.nvim's
--     cwd-based activation made it work, and only when nvim was started
--     inside the subproject.
--   * extraPaths -> the git root, when it differs from root_dir, so imports
--     like `utils.src.messages` resolve from any subproject.
--   * ROS packages (package.xml next to setup.py, deps only exist inside the
--     ROS install / docker image): unresolved imports become warnings, not
--     errors, so files that are fine at runtime don't light up red.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          before_init = function(_, config)
            local root = config.root_dir
            if not root then
              return
            end
            -- Mutate settings in place: the client keeps a reference to it.
            config.settings = config.settings or {}
            local py = config.settings.python or {}
            config.settings.python = py

            local python = root .. "/.venv/bin/python"
            if vim.uv.fs_stat(python) then
              py.pythonPath = python
            end

            local repo = vim.fs.root(root, ".git")
            if repo and repo ~= root then
              py.analysis = py.analysis or {}
              local extra = py.analysis.extraPaths or {}
              if not vim.tbl_contains(extra, repo) then
                table.insert(extra, repo)
              end
              py.analysis.extraPaths = extra
            end

            if vim.uv.fs_stat(root .. "/package.xml") then
              py.analysis = py.analysis or {}
              py.analysis.diagnosticSeverityOverrides = vim.tbl_extend(
                "keep",
                py.analysis.diagnosticSeverityOverrides or {},
                { reportMissingImports = "warning", reportMissingModuleSource = "warning" }
              )
            end
          end,
        },
      },
    },
  },
}
