-- AI assistant backed by the self-hosted Open WebUI instance on the Unraid server.
--
-- Open WebUI serves an OpenAI-compatible API (/api/chat/completions, /api/models)
-- that needs an API key (Open WebUI -> Settings -> Account -> API Keys). The key is
-- read from $OPENWEBUI_API_KEY, falling back to the file written by install.sh /
-- install.ps1 so it never has to live in this repo.
local key_file = vim.fn.stdpath("data") .. "/openwebui_api_key"

local function api_key()
  if vim.env.OPENWEBUI_API_KEY and vim.env.OPENWEBUI_API_KEY ~= "" then
    return vim.env.OPENWEBUI_API_KEY
  end
  local f = io.open(key_file, "r")
  if not f then
    vim.notify("No Open WebUI API key: set OPENWEBUI_API_KEY or write it to " .. key_file, vim.log.levels.WARN)
    return nil
  end
  local key = vim.trim(f:read("*a"))
  f:close()
  return key
end

-- Model ids as Open WebUI lists them (Ollama models carry their tag, e.g. ":latest").
local models = {
  default = "phi3:mini",
  architect = "architect:latest",
  reviewer = "code-reviewer:latest",
  coder = "java-sb-coder:latest",
  quickref = "phi3:mini",
}

---A chat prompt that opens with one of the personas below. A visual selection is
---added to the chat automatically.
local function persona(description, alias, model, system_prompt)
  return {
    interaction = "chat",
    description = description,
    opts = {
      alias = alias,
      ignore_system_prompt = true,
      adapter = { name = "openwebui", model = model },
    },
    prompts = {
      { role = "system", content = system_prompt },
    },
  }
end

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  opts = {
    adapters = {
      http = {
        openwebui = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "openwebui",
            formatted_name = "Open WebUI",
            env = {
              -- Override per machine, e.g. NVIM_AI_URL=http://<unraid-ip>:3000 on the LAN.
              url = vim.env.NVIM_AI_URL or "https://ai.garykellstrom.dev",
              api_key = api_key,
              chat_url = "/api/chat/completions",
              models_endpoint = "/api/models",
            },
            schema = {
              model = { default = models.default },
            },
          })
        end,
      },
    },
    interactions = {
      chat = { adapter = "openwebui" },
      inline = { adapter = "openwebui" },
      cmd = { adapter = "openwebui" },
      background = { adapter = "openwebui" },
    },
    prompt_library = {
      ["Architect"] = persona("Senior Software Architect", "architect", models.architect, [[
You are a Senior Software Architect AI. Your role is to:
1. **Think at a system level** - Consider scalability, maintainability, and performance.
2. **Recommend appropriate technologies** - Suggest libraries/frameworks with pros/cons.
3. **Design before coding** - Outline structure, data flow, and key components.
4. **Review existing code** - Identify architectural improvements or potential issues.
5. **Clarify requirements** - Ask probing questions before proposing solutions.

You communicate in clear, structured responses. Use bullet points, diagrams (ASCII/mermaid when helpful), and analogies. Always consider trade-offs.]]),
      ["Reviewer"] = persona("Senior Code Reviewer", "reviewer", models.reviewer, [[
You are a meticulous Senior Code Reviewer AI. Your expertise includes:

**Primary Responsibilities:**
1. **Bug Detection** - Find logic errors, edge cases, and potential failures
2. **Code Quality** - Assess readability, maintainability, and adherence to standards
3. **Performance Analysis** - Identify bottlenecks and optimization opportunities
4. **Security Review** - Spot vulnerabilities and unsafe practices
5. **Best Practices** - Ensure modern, idiomatic code for the language
6. **Answering Code Questions** - Explain behavior, bugs, or design decisions

**Review Methodology:**
- Be constructive, not critical
- Prioritize issues (Critical/High/Medium/Low)
- Provide specific fixes, not just problems
- Consider context and practical trade-offs
- When unsure, ask clarifying questions

**Response Format:**
1. **Summary** - Overall assessment
2. **Critical Issues** (if any)
3. **Detailed Findings** with code snippets
4. **Suggestions** with before/after examples
5. **Questions** (if needing clarification)

Always reference specific lines when possible.]]),
      ["Coder"] = persona("Senior Code Generator", "coder", models.coder, [[
You are a Senior Code Generator AI with expertise in multiple programming languages and frameworks. Your role is to:

**Primary Capabilities:**
1. **Generate production-ready code** - Complete, tested, and maintainable
2. **Create project skeletons/boilerplate** - Well-structured starting points
3. **Implement specific algorithms/patterns** - With proper edge cases
4. **Convert requirements to code** - Bridging specification and implementation
5. **Migrate/translate code** - Between languages or versions
6. **Generate code with context** - Considering existing codebase patterns

**Code Generation Principles:**
- **Complete**: Include imports, error handling, and comments
- **Idiomatic**: Follow language/framework best practices
- **Practical**: Balance perfection with real-world constraints
- **Secure**: Default to safe, validated patterns
- **Testable**: Structure for easy unit/integration testing
- **Configurable**: Use parameters, not hard-coded values

**Response Format:**
1. **Overview**: What the code does and key design decisions
2. **Dependencies**: Required packages/libraries
3. **Implementation**: Complete, runnable code
4. **Usage Example**: How to call/use the generated code
5. **Notes**: Caveats, optimizations, alternatives

Always ask for clarification when requirements are ambiguous.]]),
      ["QuickRef"] = persona("Developer's quick reference", "quickref", models.quickref, [[
You are a Senior Developer's Quick Reference AI. Your role is to provide **concise, accurate, practical information** similar to a developer's ideal Google search result.

**Core Principles:**
1. **Be Fast** - Get straight to the point
2. **Be Practical** - Provide immediately usable information
3. **Be Accurate** - Give correct syntax, commands, facts
4. **Be Context-Aware** - Consider the user's likely environment
5. **Provide Examples** - Show, don't just tell

**Response Format (Always Use):**
🔍 **Topic**: [What's being asked]
📌 **Quick Answer**: 1-2 sentence direct answer
📝 **Key Points**: 3-5 bullet points
💡 **Example**: Minimal working example
🔗 **Related/Useful**: 2-3 related topics or next steps
⚠️ **Watch Out**: Common pitfalls or important notes

Keep responses under 300 words unless complexity requires more.]]),
    },
  },
  init = function()
    -- Show a spinner notification (with the model and elapsed time) while a
    -- request is running, since a large model can take a while to load.
    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    local timers = {}

    local function notify(id, msg, level, opts)
      local ok, snacks = pcall(require, "snacks")
      if ok and snacks.notifier then
        snacks.notifier.notify(msg, level, vim.tbl_extend("force", { id = "codecompanion_" .. id, title = "AI" }, opts))
      end
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = { "CodeCompanionRequestStarted", "CodeCompanionRequestFinished" },
      group = vim.api.nvim_create_augroup("CodeCompanionProgress", {}),
      callback = function(args)
        local data = args.data or {}
        local id = tostring(data.id or 0)
        local model = tostring(data.adapter and data.adapter.model or "AI")

        if args.match == "CodeCompanionRequestStarted" then
          local start, frame = vim.uv.now(), 0
          local timer = assert(vim.uv.new_timer())
          timers[id] = timer
          timer:start(0, 120, vim.schedule_wrap(function()
            if timers[id] ~= timer then
              return
            end
            frame = frame % #spinner + 1
            local secs = math.floor((vim.uv.now() - start) / 1000)
            notify(id, ("%s %s is working... %ds"):format(spinner[frame], model, secs), "info", { timeout = false })
          end))
          return
        end

        local timer = timers[id]
        timers[id] = nil
        if timer then
          timer:stop()
          timer:close()
        end
        if data.status == "success" then
          notify(id, ("✓ %s finished"):format(model), "info", { timeout = 2000 })
        elseif data.status == "cancelled" then
          notify(id, ("%s request cancelled"):format(model), "warn", { timeout = 2000 })
        else
          notify(id, ("%s request failed (details in ~/.local/state/nvim/codecompanion.log)"):format(model), "error", { timeout = 5000 })
        end
      end,
    })
  end,
  keys = {
    -- In visual mode the selection is sent along with the prompt.
    { "<leader>aa", ":CodeCompanion /architect<cr>", mode = { "n", "v" }, desc = "Ask Architect" },
    { "<leader>rr", ":CodeCompanion /reviewer<cr>", mode = { "n", "v" }, desc = "Ask Reviewer" },
    { "<leader>cg", ":CodeCompanion /coder<cr>", mode = { "n", "v" }, desc = "Ask Coder" },
    { "<leader>aq", ":CodeCompanion /quickref<cr>", mode = { "n", "v" }, desc = "Quick Reference" },
    { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle AI chat" },
    { "<leader>ap", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI actions" },
  },
}
