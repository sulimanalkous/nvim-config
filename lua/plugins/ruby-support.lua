-- Ruby / Rails editor support.
--
-- Keymaps here are buffer-local, so they never touch non-Ruby buffers. No
-- LuaSnip spec: lua/plugins/nvim-cmp.lua already loads the vscode snippet
-- collection (friendly-snippets) once.
--
-- Spec runners deliberately avoid <leader>rn, which is LSP rename everywhere:
--   <leader>rr  run the spec nearest the cursor   (the one you use most)
--   <leader>rf  run the whole spec file
--   <leader>rl  run the last spec again
--   <leader>ra  run every spec
-- Rails file jumps: <leader>rc/<leader>rm/<leader>rv/<leader>rs/<leader>rt
return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "ruby", "eruby" },
        callback = function()
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
          end
          map("<leader>rc", ":Econtroller<CR>", "Go to controller")
          map("<leader>rm", ":Emodel<CR>", "Go to model")
          map("<leader>rv", ":Eview<CR>", "Go to view")
          map("<leader>rs", ":Espec<CR>", "Go to spec")
          map("<leader>rt", ":Etest<CR>", "Go to test")
        end,
      })
    end,
  },
  {
    "vim-ruby/vim-ruby",
    ft = { "ruby", "eruby" },
    config = function()
      vim.g.ruby_indent_assignment_style = "variable"
      vim.g.ruby_indent_block_style = "do"
    end,
  },
  {
    "thoughtbot/vim-rspec",
    ft = { "ruby" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ruby",
        callback = function()
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
          end
          map("<leader>rr", ":call RunNearestSpec()<CR>", "Run nearest spec")
          map("<leader>rf", ":call RunCurrentSpecFile()<CR>", "Run spec file")
          map("<leader>rl", ":call RunLastSpec()<CR>", "Run last spec")
          map("<leader>ra", ":call RunAllSpecs()<CR>", "Run all specs")
        end,
      })
    end,
  },
  {
    "tpope/vim-endwise",
    ft = { "ruby", "eruby" },
  },
  {
    "dense-analysis/ale",
    ft = { "ruby", "eruby" },
    config = function()
      vim.g.ale_linters = { ruby = { "rubocop", "solargraph" } }
      vim.g.ale_fixers = { ruby = { "rubocop" } }
      vim.g.ale_fix_on_save = 1
      -- Resolved from PATH, so the same file works on Linux and macOS; unset
      -- means ALE uses its own "rubocop" lookup.
      local rubocop = vim.fn.exepath("rubocop")
      if rubocop ~= "" then
        vim.g.ale_ruby_rubocop_executable = rubocop
      end
    end,
  },
}
