local M = {}
local util = require("config.project.utils")

function M.create()
  local data = {}
  data.name = vim.fn.input("Project name: ")
  if data.name == "" then
    return
  end

  data.path = util.ProjectRoot("Python", data.name)
  vim.fn.system({
    "python",
    "-m",
    "venv",
    data.path .. "/.venv",
  })

  local main_py = data.path .. "/main.py"
  local f = io.open(main_py, "w")
  if f == nil then
    vim.notify("failed to open main_py!")
    return
  end
  f:write([[def main():
  print("Hellow, world!")

if __name__ == "__main__":
  main()
]])
  f:close()

  local cmd = {
    "cd",
    data.path,
  }

  util.GenerateProject(cmd, data.path, data.name)
end

return M
