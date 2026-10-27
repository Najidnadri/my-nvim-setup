-- Sidebar listing every live Claude Code session, with a detail tab per session.
local M = {}

local home = vim.env.HOME
local script = home .. "/.claude/scripts/session-board.py"
local heartbeat = home .. "/.claude/state/board/.nvim-alive"
local ns = vim.api.nvim_create_namespace("claude_board")

M.width = 42
M.interval = 2000
M.data = { sessions = {} }

local state = { buf = nil, timer = nil, busy = false, line_to_sid = {} }

local icons = { pending = "?", running = "●", background = "◐", idle = "○", unknown = "·" }
local hl = {
  pending = "DiagnosticWarn",
  running = "DiagnosticInfo",
  background = "DiagnosticHint",
  idle = "Comment",
  unknown = "Comment",
}

function M.find(sid)
  for _, s in ipairs(M.data.sessions or {}) do
    if s.sessionId == sid then
      return s
    end
  end
end

local function count_running(tasks)
  local n = 0
  for _, t in ipairs(tasks or {}) do
    if t.status == "running" then
      n = n + 1
    end
  end
  return n
end

-- One dim line under each session saying what it is doing or waiting on.
local function activity(s)
  local p = s.pendingInput
  if p and p.kind == "question" and p.questions and p.questions[1] then
    return "asks: " .. p.questions[1].question
  elseif p and p.kind == "permission" then
    return "permission: " .. (p.tool or "") .. " " .. (p.detail or "")
  elseif s.status == "pending" then
    return "waiting for input"
  end
  local now = s.runningNow and s.runningNow[#s.runningNow]
  if now and s.status == "running" then
    return now.name .. ": " .. (now.summary or "")
  end
  return s.lastPrompt ~= "" and s.lastPrompt or (s.lastText or "")
end

local function sidebar_win()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == state.buf then
      return win
    end
  end
end

local function render_sidebar()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  local sessions = M.data.sessions or {}
  local counts = { pending = 0, running = 0, background = 0, idle = 0 }
  for _, s in ipairs(sessions) do
    counts[s.status] = (counts[s.status] or 0) + 1
  end
  local lines = {
    string.format(" Claude sessions (%d)", #sessions),
    string.format(" ?%d  ●%d  ◐%d  ○%d", counts.pending, counts.running, counts.background, counts.idle),
    "",
  }
  local marks = { { 0, 0, -1, "Title" }, { 1, 0, -1, "Comment" } }
  state.line_to_sid = {}
  local w = M.width - 2
  for _, s in ipairs(sessions) do
    local agents, bg = #(s.subagents or {}), count_running(s.tasks)
    local badge = ""
    if agents > 0 then
      badge = badge .. " a" .. agents
    end
    if bg > 0 then
      badge = badge .. " b" .. bg
    end
    local cost = (s.usage and s.usage.cost or 0) + (s.subagentUsage and s.subagentUsage.cost or 0)
    if cost >= 0.01 then
      badge = badge .. string.format(" $%.0f", cost < 1 and 1 or cost)
    end
    local name = vim.fn.strcharpart(s.name, 0, w - 3 - #badge)
    local pad = string.rep(" ", math.max(1, w - 2 - vim.fn.strdisplaywidth(name) - #badge))
    local row = #lines
    table.insert(lines, string.format(" %s %s%s%s", icons[s.status] or "·", name, pad, badge))
    table.insert(lines, "   " .. vim.fn.strcharpart(activity(s):gsub("%s+", " "), 0, w - 2))
    table.insert(marks, { row, 1, 1 + #(icons[s.status] or "·"), hl[s.status] or "Comment" })
    table.insert(marks, { row, #lines[row + 1] - #badge, -1, "Special" })
    table.insert(marks, { row + 1, 0, -1, s.status == "pending" and "DiagnosticWarn" or "Comment" })
    state.line_to_sid[row + 1] = s.sessionId
    state.line_to_sid[row + 2] = s.sessionId
  end
  if #sessions == 0 then
    table.insert(lines, " No live sessions")
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local end_col = m[3] == -1 and #lines[m[1] + 1] or m[3]
    pcall(vim.api.nvim_buf_set_extmark, state.buf, ns, m[1], m[2], { end_col = end_col, hl_group = m[4] })
  end
end

local function touch_heartbeat()
  local now = os.time()
  if not vim.uv.fs_utime(heartbeat, now, now) then
    vim.fn.mkdir(vim.fs.dirname(heartbeat), "p")
    local fd = vim.uv.fs_open(heartbeat, "w", 420)
    if fd then
      vim.uv.fs_close(fd)
    end
  end
end

local function board_visible()
  return sidebar_win() ~= nil or require("claude_board.detail").any_open()
end

function M.refresh()
  if state.busy then
    return
  end
  state.busy = true
  vim.system({ "python3", "-I", script }, { text = true }, function(res)
    vim.schedule(function()
      state.busy = false
      if res.code ~= 0 then
        vim.notify("Claude board: " .. (res.stderr or "collector failed"), vim.log.levels.WARN)
        return
      end
      local ok, data = pcall(vim.json.decode, res.stdout, { luanil = { object = true, array = true } })
      if not ok then
        return
      end
      M.data = data
      render_sidebar()
      require("claude_board.detail").render_all()
    end)
  end)
end

local function tick()
  if not board_visible() then
    M.stop()
    return
  end
  touch_heartbeat()
  M.refresh()
end

function M.start()
  if state.timer then
    return
  end
  state.timer = vim.uv.new_timer()
  state.timer:start(0, M.interval, vim.schedule_wrap(tick))
end

function M.stop()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
  -- Pending questions fall back to the terminal once the heartbeat goes stale.
  vim.uv.fs_unlink(heartbeat)
end

local function sid_under_cursor()
  return state.line_to_sid[vim.api.nvim_win_get_cursor(0)[1]]
end

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "claude://sessions")
  vim.bo[buf].filetype = "claudeboard"
  vim.bo[buf].bufhidden = "hide"
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  map("<CR>", function()
    local sid = sid_under_cursor()
    if sid then
      require("claude_board.detail").open(sid)
    end
  end, "Open session")
  map("a", function()
    local sid = sid_under_cursor()
    if sid then
      require("claude_board.detail").attach(sid)
    end
  end, "Attach background session")
  map("r", M.refresh, "Refresh")
  map("q", M.close, "Close")
  return buf
end

function M.open()
  if sidebar_win() then
    return
  end
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    state.buf = create_buf()
  end
  vim.cmd("topleft vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, state.buf)
  vim.api.nvim_win_set_width(win, M.width)
  local wo = vim.wo[win]
  wo.winfixwidth, wo.number, wo.relativenumber = true, false, false
  wo.signcolumn, wo.wrap, wo.cursorline, wo.foldcolumn = "no", false, true, "0"
  render_sidebar()
  M.start()
end

function M.close()
  local win = sidebar_win()
  if win and #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.api.nvim_win_close(win, true)
  end
  if not board_visible() then
    M.stop()
  end
end

function M.toggle()
  if sidebar_win() then
    M.close()
  else
    M.open()
  end
end

-- Headless check: print the parsed board.
function M.dump()
  local res = vim.system({ "python3", "-I", script }, { text = true }):wait()
  M.data = vim.json.decode(res.stdout, { luanil = { object = true, array = true } })
  for _, s in ipairs(M.data.sessions) do
    print(string.format("%-10s %-28s agents=%d bg=%d  %s", s.status, s.name, #s.subagents, count_running(s.tasks), activity(s)))
  end
end

return M
