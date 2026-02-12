-- Enhanced Spring Boot project generator with interactive UI
local M = {}
local util = require("config.project.utils")

-- Common Spring Boot dependencies
local DEPENDENCIES = {
  { name = "Spring Web", id = "web" },
  { name = "Spring Data JPA", id = "data-jpa" },
  { name = "PostgreSQL Driver", id = "postgresql" },
  { name = "MySQL Driver", id = "mysql" },
  { name = "Spring Data Redis", id = "data-redis" },
  { name = "Spring Security", id = "security" },
  { name = "Spring Boot Actuator", id = "actuator" },
  { name = "Flyway Migration", id = "flyway" },
  { name = "Liquibase Migration", id = "liquibase" },
  { name = "Validation", id = "validation" },
  { name = "Lombok", id = "lombok" },
  { name = "Configuration Processor", id = "configuration-processor" },
  { name = "Spring Boot DevTools", id = "devtools" },
  { name = "Testcontainers", id = "testcontainers" },
  { name = "Spring Boot Test", id = "spring-boot-starter-test" },
  { name = "Spring Cloud Config Client", id = "cloud-config-client" },
  { name = "Spring Cloud Netflix Eureka Client", id = "cloud-netflix-eureka-client" },
  { name = "Resilience4J", id = "resilience4j" },
  { name = "Spring Kafka", id = "kafka" },
  { name = "Spring for Apache Kafka", id = "spring-kafka" },
  { name = "Spring Batch", id = "batch" },
  { name = "Spring Integration", id = "integration" },
}

-- Spring Boot versions
local BOOT_VERSIONS = {
  "4.0.1",
  "3.5.9",
}

-- Java versions
local JAVA_VERSIONS = {
  "25",
  "21",
  "17",
}

-- Build tools
local BUILD_TOOLS = {
  { name = "Maven", id = "maven-project" },
  { name = "Gradle", id = "gradle-project" },
  { name = "Gradle (Kotlin)", id = "gradle-project-kotlin" },
}

-- Main function
function M.create()
  -- Collect project information
  local project_data = {}

  -- Get project name
  project_data.project_name = vim.fn.input("Project name: ")
  if project_data.project_name == "" then
    return
  end

  -- Get description
  project_data.description = vim.fn.input("Description: ", project_data.project_name .. " Service")

  -- Get groupId (default to com.[username])
  local default_group = "com." .. (vim.fn.system("whoami"):gsub("\n", ""):gsub("%s+", ""))
  project_data.group_id = vim.fn.input("Group ID: ", default_group)

  -- Get artifactId (default to project name)
  project_data.artifact_id = vim.fn.input("Artifact ID: ", project_data.project_name:gsub(" ", "-"):lower())

  -- Get package name (default to groupId.artifactId)
  local default_package = project_data.group_id .. "." .. project_data.artifact_id:gsub("-", "")
  project_data.package_name = vim.fn.input("Package name: ", default_package)

  -- Select build tool
  util.SingleSelect(BUILD_TOOLS, "Select build tool:", function(selected)
    project_data.build_tool = selected

    -- Select Spring Boot version
    util.SingleSelect(BOOT_VERSIONS, "Select Spring Boot version:", function(selected_version)
      project_data.boot_version = selected_version

      -- Select Java version
      util.SingleSelect(JAVA_VERSIONS, "Select Java version:", function(selected_java)
        project_data.java_version = selected_java

        -- Select dependencies
        util.MultiSelect(
          DEPENDENCIES,
          "Select dependencies (Space to toggle, Enter when done):",
          function(selected_deps)
            project_data.dependencies = selected_deps
            M.confirm_and_generate(project_data)
          end
        )
      end)
    end)
  end)
end

function M.confirm_and_generate(data)
  -- Confirm and generate
  local confirm_msg = string.format(
    [["

  === Project Configuration ===
  
  Project: %s
  Description: %s
  Group ID: %s
  Artifact ID: %s
  Package: %s
  Build Tool: %s
  Spring Boot: %s
  Java: %s
  Dependencies: %s

  Generate project? (y/n):]],
    data.project_name,
    data.description,
    data.group_id,
    data.artifact_id,
    data.package_name,
    data.build_tool,
    data.boot_version,
    data.java_version,
    table.concat(data.dependencies, ", ")
  )

  local confirm = vim.fn.confirm(confirm_msg, "&Yes\n&No", 2)
  if confirm == 1 then
    M.generate_project(data)
  else
    vim.notify("Project generation cancelled", vim.log.levels.WARN)
  end
end

-- Generate project function
function M.generate_project(data)
  local zip_name = string.format("%s.zip", data.project_name)
  local base_path = util.ProjectRoot("Java", data.project_name)

  -- Build curl command
  local cmd_parts = {
    'curl -s "https://start.spring.io/starter.zip"',
    string.format("-d type=%s", data.build_tool),
    "-d language=java",
    string.format("-d platformVersion=%s", data.boot_version),
    string.format("-d groupId=%s", data.group_id),
    string.format("-d artifactId=%s", data.artifact_id),
    string.format('-d name="%s"', data.project_name),
    string.format('-d description="%s"', data.description),
    string.format("-d packageName=%s", data.package_name),
    "-d packaging=jar",
    string.format("-d jvmVersion=%s", data.java_version),
    "-d configurationFileFormat=properties",
  }

  -- Add dependencies if any
  if #data.dependencies > 0 then
    table.insert(cmd_parts, string.format("-d dependencies=%s", table.concat(data.dependencies, ",")))
  end

  local full_cmd = {
    "sh",
    "-c",
    string.format(
      "cd %s && %s -o %s && unzip -q %s && rm -f %s",
      base_path,
      table.concat(cmd_parts, " "),
      zip_name,
      zip_name,
      zip_name
    ),
  }

  util.GenerateProject(full_cmd, base_path, data.project_name)
end

return M
