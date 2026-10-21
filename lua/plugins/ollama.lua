return {
  "nomnivore/ollama.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  -- All the user commands added by the plugin
  cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

  ---@type Ollama.Config
  opts = {
    -- Self-hosted Ollama server. Override per machine with NVIM_AI_URL,
    -- e.g. `export NVIM_AI_URL=http://127.0.0.1:11434` to use a local instance.
    url = vim.env.NVIM_AI_URL or "https://ai.garykellstrom.dev",
    model = "phi3:mini",
    view = "float",
    conversation = true,
    -- Conversation-specific settings
    serve = {
      -- The server is remote, so never try to start `ollama serve` locally.
      on_start = false,
      command = "ollama",
      args = { "serve" },
      stop_command = "pkill",
      stop_args = { "-f", "ollama serve" },
    },
    -- This is the corrected prompts table.
    -- The 'model' key is NOW INSIDE each prompt definition.
    prompts = {
      -- Template for the Architect to explain selected code
      Architect = {
        prompt = [[You are a Senior Software Architect AI. Your role is to:
1. **Think at a system level** - Consider scalability, maintainability, and performance.
2. **Recommend appropriate technologies** - Suggest libraries/frameworks with pros/cons.
3. **Design before coding** - Outline structure, data flow, and key components.
4. **Review existing code** - Identify architectural improvements or potential issues.
5. **Clarify requirements** - Ask probing questions before proposing solutions.

You communicate in clear, structured responses. Use bullet points, diagrams (ASCII/mermaid when helpful), and analogies. Always consider trade-offs.:

$input
---
$buf]],
        model = "architect",
        conversation = true,
      },

      -- Template for the Reviewer to review selected code
      Reviewer = {
        prompt = [[You are a meticulous Senior Code Reviewer AI. Your expertise includes:

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

Always reference specific lines when possible.
---
$input
---
$buf]],
        model = "code-reviewer",
        conversation = true,
      },

      -- Template for the Coder to generate code from an instruction
      Coder = {
        prompt = [[You are a Senior Code Generator AI with expertise in multiple programming languages and frameworks. Your role is to:

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

Always ask for clarification when requirements are ambiguous.
---
$input
---
$buf]],
        model = "java-sb-coder",
        conversation = true,
      },
      -- Template for the general-purpose Assistant
      QuickRef = {
        prompt = [[You are a Senior Developer's Quick Reference AI. Your role is to provide **concise, accurate, practical information** similar to a developer's ideal Google search result.

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

Keep responses under 300 words unless complexity requires more.
        ---
        $input]],
        model = "phi3:mini",
        conversation = true,
      },
    }, -- Custom actions/mappings for conversation mode
    actions = {
      -- You can add custom keymaps here for conversation
    },
  },

  -- Key mappings setup
  keys = {
    -- Architect AI
    { "<leader>aa", "<cmd>Ollama Architect<cr>", desc = "Ask Architect" },
    { "<leader>as", ":Ollama Architect ", desc = "Ask Architect with selection" },

    -- Code Reviewer
    { "<leader>rr", "<cmd>Ollama Reviewer<cr>", desc = "Ask Reviewer" },
    { "<leader>rs", ":Ollama Reviewer ", desc = "Ask Reviewer with selection" },

    -- Code Generator
    { "<leader>cg", "<cmd>Ollama Coder<cr>", desc = "Ask Coder" },
    { "<leader>cs", ":Ollama Coder ", desc = "Ask Coder with selection" },

    -- Quick Reference
    { "<leader>qq", "<cmd>Ollama QuickRef<cr>", desc = "Quick Reference" },
    { "<leader>qs", ":Ollama QuickRef ", desc = "Quick Reference with selection" },
  },

  -- Init function to set up additional configuration
  init = function()
    -- Create custom commands for each AI role
    vim.api.nvim_create_user_command("AskArchitect", function(opts)
      require("ollama").prompt("Architect", opts.args)
    end, { nargs = "*" })

    vim.api.nvim_create_user_command("AskReviewer", function(opts)
      require("ollama").prompt("Reviewer", opts.args)
    end, { nargs = "*" })

    vim.api.nvim_create_user_command("AskCoder", function(opts)
      require("ollama").prompt("Coder", opts.args)
    end, { nargs = "*" })

    vim.api.nvim_create_user_command("QuickRef", function(opts)
      require("ollama").prompt("QuickRef", opts.args)
    end, { nargs = "*" })
  end,
}
