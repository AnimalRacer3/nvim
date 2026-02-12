local M = {}
local util = require("config.project.utils")

local SDKS = {
  { name = ".NET 8", id = "net8.0" },
  { name = ".NET 10", id = "net10.0" },
}

function M.create()
  local data = {}

  data.name = vim.fn.input("Project name: ")
  if data.name == "" then
    return
  end

  util.SingleSelect(SDKS, "Select .NET SDK:", function(sdk)
    data.sdk = sdk.id
    data.path = util.ProjectRoot("DotNet", data.name)

    local cmd = {
      "dotnet",
      "new",
      "console",
      "--framework",
      data.sdk,
      "--name",
      data.name,
    }

    util.GenerateProject(cmd, data.path, data.name)
  end)
end

return M
