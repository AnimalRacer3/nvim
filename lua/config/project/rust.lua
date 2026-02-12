local M = {}
local util = require("config.project.utils")

function M.create()
  local data = {}
  data.name = vim.fn.input("Project name: ")
  if data.name == "" then
    vim.notify("No project name provided", vim.log.levels.WARN)
    return
  end

  data.path = util.ProjectRoot("Rust", data.name)
  local cmd = {
    "cargo",
    "init",
    data.name,
    "--vcs=none",
  }

  util.GenerateProject(cmd, data.path, data.name)
end

return M
