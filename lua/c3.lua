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

-- c3lsp answers `initialize` only after indexing the stdlib (~2 s, since
-- c3lsp-fresh clears its cache on every start), so it attaches late. If you
-- were already typing `io::` or `std::` by then, nvim-cmp had no LSP source
-- and does not ask again on its own. Worse, cmp-nvim-lsp only registers a new
-- server on InsertEnter, so it stayed missing until your next insert. Once
-- the server is in: register it with cmp now and re-open the menu.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "c3_lsp" then
      return
    end
    vim.schedule(function()
      local cmp = package.loaded.cmp
      if not cmp or args.buf ~= vim.api.nvim_get_current_buf() then
        return
      end
      if not vim.api.nvim_get_mode().mode:match("^i") then
        return
      end
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok and cmp_lsp._on_insert_enter then
        cmp_lsp._on_insert_enter()
      end
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local before = vim.api.nvim_get_current_line():sub(1, col)
      if before:match("[%w_:.]$") then
        cmp.complete()
      end
    end)
  end,
})

-- Electric indent, like Emacs: each line lands at the right indentation as
-- you type (on Enter, and when a line starts with `}`), using the C3
-- tree-sitter indent rules. Indent with tabs, as c3fmt does, so saving
-- (format on save) does not shift what you typed.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c3", "c3i" },
  callback = function(args)
    local bo = vim.bo[args.buf]
    bo.expandtab = false
    bo.tabstop = 4
    bo.shiftwidth = 4
    bo.softtabstop = 0
    bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    -- Re-indent on `case`/`default` rather than on every ":", which would
    -- also fire on the `::` of `io::printn` while the line is half-typed.
    bo.indentkeys = "0{,0},0),0],!^F,o,O,e,0=case,0=default"
  end,
})
