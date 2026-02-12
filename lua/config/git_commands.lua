local M = {}

local function is_git_repo()
  return vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
end

local function has_remote()
  return vim.fn.system("git remote"):match("origin")
end

local function current_branch()
  return vim.fn.system("git branch --show-current"):gsub("\n", "")
end

local function has_upstream()
  return vim.fn.system("git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null"):match("/")
end

function M.GitPushSmart()
  if not is_git_repo() then
    vim.notify("Not a git repository", vim.log.levels.ERROR)
    return
  end

  local status = vim.fn.system("git status --porcelain")
  if status ~= "" then
    local commit_msg = vim.fn.input("Commit message (leave empty to cancel): ")
    if commit_msg == "" then
      vim.notify("Push cancelled", vim.log.levels.WARN)
      return
    end
    vim.fn.system("git add .")
    vim.fn.system(string.format("git commit -m %q", commit_msg))
  end

  if not has_remote() then
    local repo_name = vim.fn.input("GitHub repo name: ")
    if repo_name == "" then
      vim.notify("Repo creation cancelled", vim.log.levels.WARN)
      return
    end

    vim.notify("Creating GitHub repository…")
    vim.fn.system(string.format("gh repo create %s --source=. --private --push", repo_name))
    vim.notify("Repository created and pushed!", vim.log.levels.INFO)
    return
  end

  local branch = current_branch()

  if not has_upstream() then
    vim.notify("Setting upstream and pushing…")
    vim.fn.system(string.format("git push -u origin %s", branch))
  else
    vim.notify("Pushing to origin/" .. branch)
    vim.fn.system("git push")
  end

  vim.notify("Push complete ✅", vim.log.levels.INFO)
end

function M.GitNewBranch()
  if not is_git_repo() then
    vim.notify("Not a git repository", vim.log.levels.ERROR)
    return
  end

  local branch = vim.fn.input("New branch name: ")
  if branch == "" then
    vim.notify("Branch creation cancelled", vim.log.levels.WARN)
    return
  end

  vim.fn.system(string.format("git checkout -b %s", branch))
  vim.notify("Switched to new branch: " .. branch, vim.log.levels.INFO)
end

return M
