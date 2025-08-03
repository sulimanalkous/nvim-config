return {
  {
    "olimorris/codecompanion.nvim",
    -- CodeCompanion re-enabled - much better than Avante
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
      "j-hui/fidget.nvim", -- for status feedback
      "MeanderingProgrammer/render-markdown.nvim", -- optional markdown rendering
    },

    init = function()
      require("plugins.codecompanion.fidget-spinner"):init()
    end,

    config = function()
      local cc = require("codecompanion")

      cc.setup({
        strategies = {
          chat = {
            adapter = "local_ai",
            window = {
              layout = "right", -- or "bottom"
              width = 0.4,
            },
          },

          inline = {
            adapter = "local_ai",
            keymaps = {
              accept_change = {
                modes = { n = "<leader>aa" },
                description = "Accept the suggested change",
              },
              reject_change = {
                modes = { n = "<leader>ar" },
                opts = { nowait = true },
                description = "Reject the suggested change",
              },
            },
            variables = {
              ["project_context"] = {
                callback = function()
                  local cwd = vim.fn.getcwd()
                  local project_name = vim.fn.fnamemodify(cwd, ":t")
                  return "Current project: " .. project_name .. " at " .. cwd
                end,
                description = "Current project context",
                opts = {
                  contains_code = false,
                },
              },
              ["current_file"] = {
                callback = function()
                  return vim.fn.expand("%:p")
                end,
                description = "Current file path",
                opts = {
                  contains_code = false,
                },
              },
            },
          },

          cmd = {
            adapter = "local_ai",
          },

          agent = {
            adapter = "local_ai",
          },
        },

        adapters = {
          local_ai = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              env = {
                url = "http://localhost:1234",
              },
              headers = {
                ["Content-Type"] = "application/json",
              },
              schema = {
                model = {
                  default = "qwen2.5-coder-1.5b-instruct",
                  type = "string",
                  description = "Model name to use with local AI",
                },
                temperature = {
                  type = "number",
                  default = 0.1,
                  desc = "Controls randomness (0.0 = deterministic, 1.0 = creative)",
                },
                max_tokens = {
                  type = "integer",
                  default = 2048,
                  desc = "Max number of tokens to generate",
                },
              },
              handlers = {
                -- Ensure proper response formatting for inline mode
                form_parameters = function(self, params, messages)
                  return {
                    model = params.model,
                    messages = messages,
                    temperature = params.temperature,
                    max_tokens = params.max_tokens,
                    stream = false, -- Disable streaming for inline mode
                  }
                end,
              },
            })
          end,
        },

        opts = {
          -- Enable system prompt with working directory context
          system_prompt = function()
            local cwd = vim.fn.getcwd()
            local project_name = vim.fn.fnamemodify(cwd, ":t")
            return string.format([[You are an AI coding assistant. You are currently working in the "%s" project located at: %s

Key context:
- Always consider the current working directory and project structure
- Provide code suggestions that fit the existing codebase style
- When editing files, maintain existing formatting and conventions
- Suggest improvements and fixes based on the current file context

Current working directory: %s]], project_name, cwd, cwd)
          end,

          -- Enable file context awareness
          send_code = true,
          silence_notifications = false,
        },

        -- Enable auto-suggestions and completion
        display = {
          action_palette = {
            width = 95,
            height = 10,
            preview = true,
          },
          chat = {
            intro_message = "Welcome! I can help with code editing, fixes, and suggestions. I'm aware of your current working directory and project context.",
          },
          inline = {
            layout = "vertical", -- vertical|horizontal|buffer
          },
        },

        -- Optional: enable logs if you want to debug
        log_level = "INFO",

        -- Add custom tools for file operations
        tools = {
          open_file = {
            callback = function(args)
              local file_path = args.file_path or args[1]
              if file_path then
                vim.cmd("edit " .. file_path)
                return "Opened file: " .. file_path
              else
                return "Error: No file path provided"
              end
            end,
            description = "Open a file in the editor",
            opts = {
              user_prompt = false,
            },
          },
          read_file = {
            callback = function(args)
              local file_path = args.file_path or args[1]
              if file_path then
                local lines = vim.fn.readfile(file_path)
                return table.concat(lines, "\n")
              else
                return "Error: No file path provided"
              end
            end,
            description = "Read contents of a file",
            opts = {
              user_prompt = false,
            },
          },
          init_project = {
            callback = function(args)
              local cwd = vim.fn.getcwd()
              local project_name = vim.fn.fnamemodify(cwd, ":t")
              
              -- Get all files recursively (excluding common ignore patterns)
              local find_cmd = "find " .. cwd .. " -type f ! -path '*/.*' ! -path '*/node_modules/*' ! -path '*/target/*' ! -path '*/build/*' ! -path '*/dist/*' ! -name '*.pyc' ! -name '*.o' ! -name '*.so' | head -50"
              local files = vim.fn.systemlist(find_cmd)
              
              local content = "# " .. project_name .. " Project Analysis\n\n"
              content = content .. "**Generated:** " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
              content = content .. "**Location:** " .. cwd .. "\n\n"
              
              content = content .. "## Project Structure\n\n"
              for _, file in ipairs(files) do
                local rel_path = string.gsub(file, cwd .. "/", "")
                content = content .. "- " .. rel_path .. "\n"
              end
              
              content = content .. "\n## File Contents Analysis\n\n"
              
              -- Read and analyze files using treesitter detection
              for _, file in ipairs(files) do
                local rel_path = string.gsub(file, cwd .. "/", "")
                
                -- Use vim.filetype.match to detect file type
                local filetype = vim.filetype.match({filename = file}) or "text"
                
                -- Check if treesitter has a parser for this filetype
                local has_parser = pcall(vim.treesitter.get_parser, 0, filetype)
                
                -- Read text files (exclude binary files)
                local is_text_file = false
                local file_handle = io.open(file, "rb")
                if file_handle then
                  local first_chunk = file_handle:read(512)
                  file_handle:close()
                  
                  if first_chunk then
                    -- Simple binary detection: check for null bytes
                    is_text_file = not string.find(first_chunk, "\0")
                  end
                end
                
                if is_text_file then
                  local lines = vim.fn.readfile(file)
                  if #lines > 0 then
                    content = content .. "### " .. rel_path .. "\n\n"
                    content = content .. "**Filetype:** " .. filetype .. "\n"
                    content = content .. "**Treesitter:** " .. (has_parser and "✓" or "✗") .. "\n\n"
                    content = content .. "```" .. filetype .. "\n"
                    
                    -- Truncate very long files
                    local max_lines = 50
                    for i = 1, math.min(#lines, max_lines) do
                      content = content .. lines[i] .. "\n"
                    end
                    
                    if #lines > max_lines then
                      content = content .. "... (truncated, " .. (#lines - max_lines) .. " more lines)\n"
                    end
                    
                    content = content .. "```\n\n"
                  end
                end
              end
              
              -- Write to PROJECT_ANALYSIS.md
              local output_file = cwd .. "/PROJECT_ANALYSIS.md"
              vim.fn.writefile(vim.split(content, "\n"), output_file)
              
              return "Project analysis complete! Created " .. output_file .. " with structure and file contents of " .. project_name .. " project."
            end,
            description = "Analyze current project structure and create PROJECT_ANALYSIS.md",
            opts = {
              user_prompt = false,
            },
          },
        },
      })

      -- Official Recommended Workflow (from CodeCompanion docs)
      vim.keymap.set({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "AI Actions Menu" })
      vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "Toggle AI Chat" })
      
      -- Note: inline accept/reject keys are configured above as <leader>aa and <leader>ar 
      -- to avoid conflict with LSP 'gr' (go to references)
      vim.keymap.set("v", "<leader>cA", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "Add selection to chat" })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])

      -- Additional useful keymaps
      -- Core Commands
      vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "Open AI Chat" })
      vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "Chat about selection" })

      -- Inline Assistant
      vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "Open Inline Assistant" })
      vim.keymap.set("v", "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "Inline Assistant for selection" })
      
      -- Command Mode
      vim.keymap.set("n", "<leader>cs", "<cmd>CodeCompanionCmd<cr>", { desc = "AI Command Mode" })

      -- Prompt Library Shortcuts (using '/' prefix)
      vim.keymap.set("n", "<leader>cf", "<cmd>CodeCompanion /fix<cr>", { desc = "AI Fix Code" })
      vim.keymap.set("n", "<leader>co", "<cmd>CodeCompanion /optimize<cr>", { desc = "AI Optimize Code" })
      vim.keymap.set("n", "<leader>ce", "<cmd>CodeCompanion /explain<cr>", { desc = "AI Explain Code" })
      vim.keymap.set("v", "<leader>cr", "<cmd>CodeCompanion /refactor<cr>", { desc = "AI Refactor Selection" })
      vim.keymap.set("n", "<leader>cd", "<cmd>CodeCompanion /document<cr>", { desc = "AI Document Code" })
      vim.keymap.set("n", "<leader>ct", "<cmd>CodeCompanion /tests<cr>", { desc = "AI Generate Tests" })

      -- Custom prompts with context
      vim.keymap.set("n", "<leader>cw", function()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        vim.cmd("CodeCompanion Analyze the " .. project_name .. " project structure in: " .. cwd)
      end, { desc = "AI Analyze Working Directory" })

      vim.keymap.set("n", "<leader>ch", "<cmd>CodeCompanion /help<cr>", { desc = "AI Help" })
      vim.keymap.set("n", "<leader>cR", "<cmd>CodeCompanionChat RefreshCache<cr>", { desc = "Refresh Chat Cache" })
      
      -- Auto-generate workspace file
      vim.keymap.set("n", "<leader>cw", function()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        local workspace_file = cwd .. "/codecompanion-workspace.json"
        
        -- Check if workspace already exists and ask to override
        if vim.fn.filereadable(workspace_file) == 1 then
          local choice = vim.fn.input("Workspace file exists. Override? (y/N): ")
          if choice:lower() ~= "y" and choice:lower() ~= "yes" then
            print("\nWorkspace generation cancelled.")
            return
          end
        end
        
        -- Get project files with priority (important files first)
        local important_patterns = {
          "package%.json$", "Cargo%.toml$", "go%.mod$", "requirements%.txt$", "pyproject%.toml$",
          "README%.md$", "%.md$", "tsconfig%.json$", "%.config%.", "%.json$"
        }
        
        local find_cmd = "find " .. cwd .. " -type f ! -path '*/.*' ! -path '*/node_modules/*' ! -path '*/target/*' ! -path '*/build/*' ! -path '*/dist/*' ! -name '*.pyc' ! -name '*.o' ! -name '*.so' | head -30"
        local all_files = vim.fn.systemlist(find_cmd)
        
        -- Prioritize important files
        local important_files = {}
        local other_files = {}
        
        for _, file in ipairs(all_files) do
          local is_important = false
          for _, pattern in ipairs(important_patterns) do
            if string.match(file, pattern) then
              table.insert(important_files, file)
              is_important = true
              break
            end
          end
          if not is_important then
            table.insert(other_files, file)
          end
        end
        
        -- Combine important files first, then others (limit to 20 total)
        local files = {}
        for i, file in ipairs(important_files) do
          if i <= 20 then table.insert(files, file) end
        end
        for i, file in ipairs(other_files) do
          if #files < 20 then table.insert(files, file) end
        end
        
        -- Detect project type
        local project_type = "Generic Project"
        local system_prompt = "This is a " .. project_name .. " project."
        
        if vim.fn.filereadable(cwd .. "/package.json") == 1 then
          project_type = "JavaScript/Node.js Project"
          system_prompt = "This is a " .. project_name .. " JavaScript/Node.js project with package.json configuration."
        elseif vim.fn.filereadable(cwd .. "/Cargo.toml") == 1 then
          project_type = "Rust Project" 
          system_prompt = "This is a " .. project_name .. " Rust project with Cargo package management."
        elseif vim.fn.filereadable(cwd .. "/requirements.txt") == 1 or vim.fn.filereadable(cwd .. "/pyproject.toml") == 1 then
          project_type = "Python Project"
          system_prompt = "This is a " .. project_name .. " Python project."
        elseif vim.fn.filereadable(cwd .. "/go.mod") == 1 then
          project_type = "Go Project"
          system_prompt = "This is a " .. project_name .. " Go project with module management."
        end
        
        -- Generate workspace JSON
        local workspace = {
          name = project_name .. " (" .. project_type .. ")",
          version = "1.0.0",
          system_prompt = system_prompt,
          groups = {
            {
              name = "Project Files",
              system_prompt = "Key project files for understanding the codebase structure and configuration.",
              data = {}
            }
          },
          data = {}
        }
        
        -- Add important files to workspace
        for _, file in ipairs(files) do
          local rel_path = string.gsub(file, cwd .. "/", "")
          local file_key = string.gsub(rel_path, "[^%w]", "-"):lower()
          local description = "Project file: " .. rel_path
          
          -- Add to group
          table.insert(workspace.groups[1].data, file_key)
          
          -- Add to data
          workspace.data[file_key] = {
            type = "file",
            path = rel_path,
            description = description
          }
        end
        
        -- Write workspace file
        local json_content = vim.fn.json_encode(workspace)
        vim.fn.writefile({json_content}, workspace_file)
        
        print("Generated workspace file: " .. workspace_file)
        print("Now you can use /workspace in CodeCompanion chat!")
      end, { desc = "Generate Workspace File" })

      -- Quick inline prompts
      vim.keymap.set("v", "<leader>cb", "<cmd>CodeCompanion Add debugging logs to this code<cr>", { desc = "Add Debug Logs" })
      vim.keymap.set("v", "<leader>cm", "<cmd>CodeCompanion Add comprehensive comments to this code<cr>", { desc = "Add Comments" })
      vim.keymap.set("n", "<leader>cp", "<cmd>CodeCompanion Review this file for potential improvements<cr>", { desc = "Code Review" })

      -- Manual accept/reject keymaps as backup (always available)
      vim.keymap.set("n", "<leader>aa", function()
        -- Try to accept changes if CodeCompanion is active
        local ok, result = pcall(function()
          require("codecompanion").accept()
        end)
        if not ok then
          print("No CodeCompanion changes to accept")
        end
      end, { desc = "Accept AI Changes (Manual)" })

      vim.keymap.set("n", "<leader>ar", function()
        -- Try to reject changes if CodeCompanion is active
        local ok, result = pcall(function()
          require("codecompanion").reject()
        end)
        if not ok then
          print("No CodeCompanion changes to reject")
        end
      end, { desc = "Reject AI Changes (Manual)" })
    end,
  },

  {
    "j-hui/fidget.nvim",
    opts = {},
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
  },
}

