-- Error checking for loose C3 files (no project.json), e.g. learning files.
--
-- c3lsp only reports errors by running `c3c build`, which needs a project.
-- For a file outside any project, run `c3c compile-only -C <file>` (lex, parse
-- and type-check only, writes no files) on open and save and show its errors
-- as diagnostics. Inside a project this does nothing; c3lsp handles errors.
local ns = vim.api.nvim_create_namespace("c3_single_file")

local function in_project(bufnr)
  return vim.fs.root(bufnr, { "project.json", "manifest.json" }) ~= nil
end

local severity = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.INFO,
}

local function check(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" or in_project(bufnr) or vim.fn.executable("c3c") == 0 then
    vim.diagnostic.reset(ns, bufnr)
    return
  end
  vim.system({ "c3c", "compile-only", "-C", file }, { text = true, cwd = vim.fs.dirname(file) }, function(res)
    vim.schedule(function()
      local out = (res.stdout or "") .. (res.stderr or "")
      local diags = {}
      for line in out:gmatch("[^\n]+") do
        -- "/path/file.c3:8:13: error: You cannot cast 'String' to 'int'."
        local path, lnum, col, kind, msg = line:match("^(.-):(%d+):(%d+): (%a+): (.*)$")
        if path and severity[kind] and vim.fn.fnamemodify(path, ":p") == vim.fn.fnamemodify(file, ":p") then
          table.insert(diags, {
            lnum = tonumber(lnum) - 1,
            col = tonumber(col) - 1,
            severity = severity[kind],
            message = msg,
            source = "c3c",
          })
        end
      end
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.set(ns, bufnr, diags)
      end
    end)
  end)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  pattern = { "*.c3", "*.c3i" },
  callback = function(args)
    check(args.buf)
  end,
})

-- <leader>cb in a loose file: `c3c compile-run` it instead of `c3c build`.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "c3",
  callback = function(args)
    if not in_project(args.buf) then
      vim.bo[args.buf].makeprg = "c3c compile-run %"
    end
  end,
})
