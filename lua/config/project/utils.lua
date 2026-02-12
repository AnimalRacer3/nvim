local M = {}

local PROJECTS_DIR = vim.fn.expand("~/Documents/Projects")

function M.ProjectRoot(lang, name)
  local path = string.format("%s/%s/%s", PROJECTS_DIR, lang, name)
  vim.fn.mkdir(path, "p")
  return path
end

function M.GenerateProject(cmd, path, name)
  vim.notify(string.format("Generating %s project...", name), vim.log.levels.INFO)

  vim.fn.mkdir(path, "p")

  -- Execute in terminal
  vim.cmd("split")
  vim.cmd("enew") -- ensures a normal, modifiable buffer

  vim.api.nvim_set_option_value("buftype", "", { buf = 0 })
  vim.api.nvim_set_option_value("modifiable", true, { buf = 0 })

  local job_id = vim.fn.jobstart(cmd, {
    term = true,
    cwd = path,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("Project generation failed", vim.log.levels.ERROR)
        end)
        return
      end

      vim.schedule(function()
        local ok = pcall(vim.api.nvim_set_current_dir, path)
        if ok then
          vim.notify(string.format("Project %s created successfully!", name), vim.log.levels.INFO)
        end
      end)
    end,
  })

  if job_id <= 0 then
    vim.notify("Error starting Spring Initializr job", vim.log.levels.ERROR)
    return
  end
end

-- Multiselect Panel
function M.MultiSelect(items, title, callback)
  local prev_win = vim.api.nvim_get_current_win()
  local selected = {}
  local index = 1

  -- Create buffer once
  local buf = vim.api.nvim_create_buf(false, true)

  -- Render menu
  local function render()
    local lines = {
      title .. " (Space = toggle, Enter = confirm, q/Esc = cancel)",
      "",
    }

    for i, item in ipairs(items) do
      local checkbox = selected[i] and "[✓]" or "[ ]"
      local cursor = (i == index) and ">" or " "
      table.insert(lines, string.format("%s %s %s", cursor, checkbox, item.name))
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  end

  -- Open floating window once
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local function close(result)
    vim.cmd("stopinsert")

    if vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
    else
      vim.cmd("enew")
    end

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    callback(result)
  end

  -- Key handlers
  vim.keymap.set("n", "j", function()
    index = math.min(index + 1, #items)
    render()
  end, { buffer = buf })

  vim.keymap.set("n", "k", function()
    index = math.max(index - 1, 1)
    render()
  end, { buffer = buf })

  vim.keymap.set("n", "<Down>", function()
    index = math.min(index + 1, #items)
    render()
  end, { buffer = buf })

  vim.keymap.set("n", "<Up>", function()
    index = math.max(index - 1, 1)
    render()
  end, { buffer = buf })

  vim.keymap.set("n", "<Space>", function()
    selected[index] = not selected[index]
    render()
  end, { buffer = buf })

  vim.keymap.set("n", "<CR>", function()
    local result = {}
    for i, ok in ipairs(selected) do
      if ok then
        table.insert(result, items[i].id)
      end
    end
    close(result)
  end, { buffer = buf })

  vim.keymap.set("n", "q", function()
    close(nil)
  end, { buffer = buf })

  vim.keymap.set("n", "<Esc>", function()
    close(nil)
  end, { buffer = buf })

  render()
end

-- Single select function
function M.SingleSelect(items, title, on_selected, display_fn)
  display_fn = display_fn or function(item)
    return item.name or item
  end

  vim.ui.select(items, {
    prompt = title,
    format_item = function(item)
      return display_fn(item)
    end,
  }, function(selected)
    if selected then
      on_selected(selected)
    end
    vim.api.nvim_echo({
      { "Please select an option or press ", "WarningMsg" },
      { "<Esc>", "ErrorMsg" },
      { " to quit", "WarningMsg" },
    }, true, {})

    vim.defer_fn(function()
      M.SingleSelect(items, title, on_selected, display_fn)
    end, 100)
  end)
end

return M
