-- The one place that decides the colorscheme.
-- <leader>tt opens a picker: moving previews the theme, <CR> keeps and saves it,
-- <Esc> restores the theme that was active before.
local M = {}

M.default = "catppuccin"

local state_file = vim.fn.stdpath("state") .. "/theme"

function M.saved()
  local f = io.open(state_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  if name and name ~= "" then
    return name
  end
  return nil
end

function M.save(name)
  local f = io.open(state_file, "w")
  if not f then
    vim.notify("theme: cannot write " .. state_file, vim.log.levels.WARN)
    return
  end
  f:write(name, "\n")
  f:close()
end

function M.apply(name)
  local ok = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("theme: '" .. name .. "' failed to load", vim.log.levels.WARN)
  end
  return ok
end

function M.current()
  return vim.g.colors_name
end

function M.pick()
  local themes = vim.fn.getcompletion("", "color")
  table.sort(themes)
  if #themes == 0 then
    vim.notify("theme: no colorschemes found", vim.log.levels.WARN)
    return
  end

  local original = M.current()
  local cursor = 1
  for i, name in ipairs(themes) do
    if name == original then
      cursor = i
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = 44
  local height = math.min(#themes, 15)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    border = "rounded",
    title = " theme ",
    title_pos = "center",
    style = "minimal",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].wrap = false
  vim.wo[win].scrolloff = 3
  vim.wo[win].winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None"

  local finished = false

  local function render()
    local lines = {}
    for i, name in ipairs(themes) do
      local mark = (i == cursor) and "> " or "  "
      local tag = (name == original) and " *" or ""
      lines[i] = mark .. name .. tag
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_cursor(win, { cursor, 0 })
  end

  local function go(index)
    if index < 1 or index > #themes or index == cursor then
      return
    end
    cursor = index
    M.apply(themes[cursor])
    render()
  end

  local function close(keep)
    if finished then
      return
    end
    finished = true
    if keep then
      M.apply(themes[cursor])
      M.save(themes[cursor])
      vim.notify("theme: " .. themes[cursor])
    else
      M.apply(original)
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "j", function() go(cursor + 1) end, opts)
  vim.keymap.set("n", "<Down>", function() go(cursor + 1) end, opts)
  vim.keymap.set("n", "k", function() go(cursor - 1) end, opts)
  vim.keymap.set("n", "<Up>", function() go(cursor - 1) end, opts)
  vim.keymap.set("n", "G", function() go(#themes) end, opts)
  vim.keymap.set("n", "<CR>", function() close(true) end, opts)
  vim.keymap.set("n", "<Esc>", function() close(false) end, opts)
  vim.keymap.set("n", "q", function() close(false) end, opts)
  vim.keymap.set("n", "<C-c>", function() close(false) end, opts)

  -- Closed any other way (:q, :close): still put the old theme back.
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function() close(false) end,
  })

  render()
end

function M.setup()
  local name = M.saved() or M.default
  if not M.apply(name) and name ~= M.default then
    M.apply(M.default)
  end
  vim.keymap.set("n", "<leader>tt", M.pick, { desc = "Theme: pick (live preview)" })
end

return M
