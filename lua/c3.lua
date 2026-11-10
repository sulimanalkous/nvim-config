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

-- K: c3lsp explains functions, constants, modules and your own symbols, but
-- has nothing for the language itself (fn, switch, defer, int, void...). For
-- those, K shows the matching section of the official C3 manual instead,
-- found by c3doc (~/.local/bin/c3doc, searches the installed C3's docs).
-- K twice enters the popup to scroll it, as with LSP hover. Operators are
-- covered too (see operator_section below).
local manual_section = {
  fn = "5_3_1 Regular functions", void = "3_2_2 Basic types",
  bool = "Booleans", ["true"] = "Booleans", ["false"] = "Booleans",
  float = "Floating point types", double = "Floating point types",
  float16 = "Floating point types", bfloat = "Floating point types",
  float128 = "Floating point types",
  null = "Pointer types", any = "The any type", typeid = "The typeid type",
  fault = "The fault type", faultdef = "Faults",
  ["if"] = "If statement", ["else"] = "If statement",
  ["for"] = "3_1_3 For Loop", foreach = "3_1_4 Foreach Loop",
  foreach_r = "3_1_4 Foreach Loop", ["while"] = "3_1_5 While Loop",
  ["do"] = "3_1_5 While Loop", ["return"] = "Return statement",
  ["break"] = "Break, continue, nextcase", continue = "Break, continue, nextcase",
  nextcase = "Break, continue, nextcase", case = "Switch statement",
  default = "Switch statement", switch = "Switch statement",
  struct = "Struct types", union = "Union types", enum = "Enum and constsets",
  constset = "Enum and constsets", bitstruct = "Bitstructs",
  interface = "Interface types", typedef = "Typedef - Distinct type definitions",
  alias = "Type aliases", macro = "Macros", import = "Modules And Import",
  module = "Modules And Import", defer = "Defer", try = "Optional",
  catch = "Optional", const = "Constants", assert = "Contracts",
}
for _, t in ipairs({ "ichar", "char", "short", "ushort", "int", "uint", "long", "ulong",
  "int128", "uint128", "iptr", "uptr", "sz", "usz" }) do
  manual_section[t] = "Integer types"
end

-- Operators: K on `??`, `!!`, `::`, `..`, `+=`... (cursor on any of its
-- characters). C3's own operators open their section; the C-like ones open
-- the operator table (all operators, by precedence).
local OPS = "Binary operators"
local operator_section = {
  ["??"] = "Return a default value if Optional is empty",
  ["!!"] = "Force unwrapping expressions",
  ["?:"] = OPS,
  ["::"] = "Modules And Import Instead Of",
  [".."] = "5_1_5 Slices",
  ["..."] = "Splat",
  ["=>"] = "5_3_4 Short function declaration syntax",
  ["$$"] = "10_2_1 Builtin constants",
  ["$"] = "Compile Time Execution",
  ["@"] = "6_13_1 Built in attributes",
  ["<*"] = "5_8_1 Doc contracts", ["*>"] = "5_8_1 Doc contracts",
  ["+++"] = "Compile-time operators", ["&&&"] = "Compile-time operators",
  ["|||"] = "Compile-time operators",
  ["."] = "4_1_7 Member access using",
}
for _, op in ipairs({ "+", "-", "*", "/", "%", "<<", ">>", "&", "|", "^", "~",
  "==", "!=", "<", "<=", ">", ">=", "&&", "||", "=", "+=", "-=", "*=", "/=",
  "%=", "&=", "|=", "^=", "<<=", ">>=", "++", "--", "!", "?", ":" }) do
  operator_section[op] = operator_section[op] or OPS
end

-- The operator under the cursor (longest match covering it), and the
-- section to show. A few symbols mean different things by position.
local function operator_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  if not line:sub(col, col):match("[%p]") then
    return nil
  end
  local best
  for op in pairs(operator_section) do
    local start = math.max(1, col - #op + 1)
    for i = start, col do
      if line:sub(i, i + #op - 1) == op and (not best or #op > #best.op) then
        best = { op = op, s = i, e = i + #op - 1 }
      end
    end
  end
  if not best then
    return nil
  end
  local before = line:sub(1, best.s - 1)
  local after = line:sub(best.e + 1)
  local op = best.op
  if op == "!" and before:match("[%w_%)%]]$") then
    return "Using the Rethrow operator" -- foo()! : pass the fault up
  elseif op == "?" and before:match("[%w_%]%*]$") then
    return "6_8_1 What is an Optional" -- int? : an Optional type
  elseif op == "?" or (op == ":" and before:match("%?")) then
    return "Ternary expression" -- a ? b : c
  elseif op == ":" then
    return nil -- `case 1:`, labels: nothing to explain
  elseif (op == "*" or op == "&") and not before:match("[%w_%)%]]%s*$") then
    return "5_1_9 Pointer types" -- prefix *p (deref), &x (address of)
  elseif op == "$$" and after:match("^[%a_]") then
    return "10_2_1 Builtin constants" -- $$LINE, $$FILE...
  elseif op == "$" and after:match("^[%a_]") then
    local word = after:match("^[%w_]+")
    return (word == "if" or word == "switch" or word == "endif" or word == "endswitch")
      and "`$if` and `$switch`" or "Compile Time Execution"
  elseif op == "@" and after:match("^[%a_]") then
    return nil -- @pool, @builtin...: the word is the thing, LSP may know it
  end
  return operator_section[op]
end

local function show_manual(word, query)
  query = query or manual_section[word]
  if not query or vim.fn.executable("c3doc") == 0 then
    vim.notify("No information available", vim.log.levels.INFO)
    return
  end
  vim.system({ "c3doc", "-d", "-n", "1", "-m", "3000", query }, { text = true }, function(res)
    vim.schedule(function()
      local lines = vim.split(res.stdout or "", "\n")
      -- drop c3doc's own header (size line, "Reference from..."), keep the section
      while #lines > 0 and not lines[1]:match("^###") do
        table.remove(lines, 1)
      end
      if #lines == 0 then
        vim.notify("No information available", vim.log.levels.INFO)
        return
      end
      -- "### If statement  [C3 0.8.5_1 manual]" -> "### If statement"
      lines[1] = lines[1]:gsub("%s*%[C3 [^%]]*%]", ""):gsub("%s*{:[^}]*}", "")
      vim.lsp.util.open_floating_preview(lines, "markdown", {
        border = "rounded",
        focus_id = "c3_manual",
        max_width = math.min(100, math.floor(vim.o.columns * 0.8)),
        max_height = math.floor(vim.o.lines * 0.6),
      })
    end)
  end)
end

local function hover(bufnr)
  local op_query = operator_at_cursor()
  if op_query then
    return show_manual(nil, op_query)
  end
  local word = vim.fn.expand("<cword>")
  -- `$if`, `$switch`, `$for`...: compile-time versions of the keywords
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local line = vim.api.nvim_get_current_line()
  local s = col
  while s > 1 and line:sub(s - 1, s - 1):match("[%w_]") do
    s = s - 1
  end
  if line:sub(s - 1, s - 1) == "$" then
    return show_manual(nil, line:sub(s - 2, s - 2) == "$" and "10_2_1 Builtin constants"
      or (word == "if" or word == "switch" or word == "endif" or word == "endswitch")
        and "`$if` and `$switch`"
      or "Compile Time Execution")
  end
  if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" }) == 0 then
    return show_manual(word)
  end
  local params = function(client)
    return vim.lsp.util.make_position_params(0, client.offset_encoding)
  end
  vim.lsp.buf_request_all(bufnr, "textDocument/hover", params, function(results)
    for _, r in pairs(results) do
      local c = r.result and r.result.contents
      if c and (c.value or c[1] or (type(c) == "string" and c ~= "")) then
        return vim.lsp.buf.hover() -- the server knows it: normal LSP popup
      end
    end
    show_manual(word)
  end)
end

local function map_hover(bufnr)
  vim.keymap.set("n", "K", function() hover(bufnr) end,
    { buffer = bufnr, desc = "Hover: LSP, or the C3 manual for keywords/types" })
end
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c3", "c3i" },
  callback = function(args) map_hover(args.buf) end,
})
-- lsp-config maps K to plain LSP hover on LspAttach; put ours back after it.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    if vim.bo[args.buf].filetype == "c3" or vim.bo[args.buf].filetype == "c3i" then
      vim.schedule(function() map_hover(args.buf) end)
    end
  end,
})
