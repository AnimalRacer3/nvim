local M = {}

local generators = {
  {
    name = "Java - Spring Boot",
    id = "spring",
    module = "config.project.spring",
  },
  {
    name = "C# - .NET",
    id = "dotnet",
    module = "config.project.dotnet",
  },
  {
    name = "Rust",
    id = "rust",
    module = "config.project.rust",
  },
  {
    name = "Python",
    id = "python",
    module = "config.project.python",
  },
}

function M.create_project()
  vim.ui.select(generators, {
    prompt = "Select project type:",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if not choice then
      return
    end
    require(choice.module).create()
  end)
end

return M
