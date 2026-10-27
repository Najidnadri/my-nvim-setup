-- Per-session detail tab: pending question, status, activity, subagents and background tasks.
local M = {}

local script = vim.env.HOME .. "/.claude/scripts/session-board.py"
local ns = vim.api.nvim_create_namespace("claude_board_detail")

-- sid -> { buf, sent } ; sent holds the answer we queued until the question clears.
local views = {}

local function board()
  return require("claude_board")
end

local mode_names = { default = "manual", acceptEdits = "accept edits", auto = "auto", plan = "plan", bypassPermissions = "bypass" }

local function tokens(n)
  if n >= 1e6 then
    return string.format("%.1fM", n / 1e6)
  elseif n >= 1e3 then
    return string.format("%dk", math.floor(n / 1e3))
  end
  return tostring(n)
end

-- Short usage summary: context fill, model and estimated API-price cost.
function M.usage_line(u)
  if not u or (u.input + u.output + u.cache_read + u.cache_write) == 0 then
    return "no usage yet"
  end
  local pct = u.window and u.window > 0 and math.floor(u.context * 100 / u.window) or 0
  return string.format("ctx %s/%s (%d%%) · %s in · %s out · %s$%.2f", tokens(u.context), tokens(u.window or 0), pct,
    tokens(u.input + u.cache_read + u.cache_write), tokens(u.output), u.priced and "" or "≥", u.cost)
end

local function ago(sec)
  if not sec then
    return ""
  elseif sec < 60 then
    return sec .. "s"
  elseif sec < 3600 then
    return math.floor(sec / 60) .. "m"
  end
  return string.format("%dh%02dm", math.floor(sec / 3600), math.floor(sec % 3600 / 60))
end

function M.any_open()
  for sid, v in pairs(views) do
    if vim.api.nvim_buf_is_valid(v.buf) and vim.fn.bufwinid(v.buf) ~= -1 then
      return true
    elseif not vim.api.nvim_buf_is_valid(v.buf) then
      views[sid] = nil
    end
  end
  return false
end

local function question_of(s)
  local p = s and s.pendingInput
  if p and p.kind == "question" and p.questions and #p.questions > 0 then
    return p
  end
end

local function render(sid)
  local v = views[sid]
  if not (v and vim.api.nvim_buf_is_valid(v.buf)) then
    return
  end
  local s = board().find(sid)
  local lines, marks = {}, {}
  v.files = {}
  local function add(text, group, file)
    table.insert(lines, text)
    if file then
      v.files[#lines] = file
    end
    if group then
      table.insert(marks, { #lines - 1, group })
    end
  end
  local function section(title, count)
    add("")
    add(count and string.format("## %s (%d)", title, count) or ("## " .. title), "Title")
  end

  if not s then
    add("Session has ended.", "Comment")
  else
    add(string.format("%s   [%s] · %s mode · %s", s.name, s.status, mode_names[s.mode] or (s.mode ~= "" and s.mode or "?"),
      (s.usage and s.usage.model or ""):gsub("^claude%-", "")), "Title")
    add(s.cwd, "Comment")
    if s.title ~= "" and s.title ~= s.name then
      add(s.title, "Comment")
    end

    local q = question_of(s)
    if q then
      v.sent = v.sent and v.sent.ts == q.ts and v.sent or nil
      section("Question")
      for qi, item in ipairs(q.questions) do
        add(string.format("%d. %s%s", qi, item.question, item.multiSelect and "  (pick several)" or ""), "DiagnosticWarn")
        for oi, opt in ipairs(item.options or {}) do
          add(string.format("   %d) %s", oi, opt.label))
          if opt.description and opt.description ~= "" then
            add("      " .. opt.description:gsub("%s+", " "), "Comment")
          end
        end
      end
      if v.sent then
        add("Answer sent, waiting for the session to pick it up…", "DiagnosticOk")
      elseif q.answerable then
        add(#q.questions == 1 and not q.questions[1].multiSelect and "Press 1-9 to answer, o for your own answer, A to step through"
          or "Press A to answer", "DiagnosticHint")
      else
        add("Asked while the board was closed; answer it in the session's terminal.", "Comment")
      end
    elseif s.pendingInput and s.pendingInput.kind == "permission" then
      local p = s.pendingInput
      v.sent = v.sent and v.sent.ts == p.ts and v.sent or nil
      section("Permission")
      add((p.tool or "") .. "  " .. (p.detail or ""):gsub("%s+", " "), "DiagnosticWarn")
      if p.description and p.description ~= "" then
        add(p.description, "Comment")
      end
      if v.sent then
        add("Decision sent, waiting for the session to pick it up…", "DiagnosticOk")
      elseif p.answerable then
        add("y allow · e allow + accept edits · u allow + auto mode · m allow + manual mode", "DiagnosticHint")
        add("n deny · N deny with a note", "DiagnosticHint")
      else
        add("Asked while the board was closed; approve or deny it in the session's terminal.", "Comment")
      end
    elseif s.pendingInput and s.pendingInput.kind == "plan" then
      local p = s.pendingInput
      section("Plan waiting for approval")
      add("Approve it (and pick the mode) or reject it in the session's terminal. <CR> opens the plan file.", "DiagnosticHint", p.planFilePath)
      for _, l in ipairs(vim.split(p.plan or "", "\n", { plain = true })) do
        add("  " .. l, nil, p.planFilePath)
      end
    end

    section("Usage")
    add("Session:   " .. M.usage_line(s.usage))
    local au = s.subagentUsage
    if au and (au.input + au.output) > 0 then
      add(string.format("Subagents: %s in · %s out · %s$%.2f (all spawned so far)", tokens(au.input + au.cache_read + au.cache_write),
        tokens(au.output), au.priced and "" or "≥", au.cost))
      add(string.format("Total:     %s$%.2f at API prices", (s.usage.priced and au.priced) and "" or "≥", s.usage.cost + au.cost), "Special")
    end

    section("Status")
    add("Last prompt: " .. (s.lastPrompt ~= "" and s.lastPrompt or "-"))
    add("Last reply:  " .. (s.lastText ~= "" and s.lastText or "-"))
    if s.attachable then
      add("Background session: press a to attach in this tab", "DiagnosticHint")
    end

    section("Running now", #(s.runningNow or {}))
    for _, t in ipairs(s.runningNow or {}) do
      add(string.format("- %s  %s  (%s)", t.name, t.summary or "", ago(t.ago)))
    end

    section("Subagents", #(s.subagents or {}))
    for _, a in ipairs(s.subagents or {}) do
      add(string.format("- %s · %s%s  %s", a.type, (a.usage.model ~= "" and a.usage.model or a.model):gsub("^claude%-", ""),
        a.background and " · bg" or "", a.desc))
      add("    " .. M.usage_line(a.usage), "Comment")
      if a.doing ~= "" then
        add("    " .. a.doing, "Comment")
      end
    end

    local listed = {}
    for _, a in ipairs(s.subagents or {}) do
      listed[a.id] = true
    end
    local groups = { shell = {}, monitor = {}, other = {} }
    for _, t in ipairs(s.tasks or {}) do
      if t.status == "running" and not listed[t.id] then
        table.insert(groups[groups[t.kind] and t.kind or "other"], t)
      end
    end
    local function list(title, items)
      section(title, #items)
      for _, t in ipairs(items) do
        add(string.format("- %s%s  (%s, %s)", (t.kind == "shell" or t.kind == "monitor") and "" or (t.kind .. ": "), t.desc, t.id, ago(t.ago)))
      end
    end
    list("Shells", groups.shell)
    list("Monitors", groups.monitor)
    list("Tasks", groups.other)

    local status_hl = { approved = "DiagnosticOk", rejected = "DiagnosticError", waiting = "DiagnosticWarn" }
    section("Plans", #(s.plans or {}))
    for _, p in ipairs(s.plans or {}) do
      add(string.format("- [%s] %s  (%s ago)", p.status, p.title, ago(p.ago)), status_hl[p.status], p.file ~= "" and p.file or nil)
    end
    section("Documents", #(s.docs or {}))
    for _, d in ipairs(s.docs or {}) do
      add(string.format("- %s  (%s ago)", vim.fn.fnamemodify(d.path, ":~:."), ago(d.ago)), nil, d.path)
    end
    if #(s.plans or {}) + #(s.docs or {}) > 0 then
      add("<CR> on a plan or document opens it beside this view", "Comment")
    end
  end

  vim.bo[v.buf].modifiable = true
  vim.api.nvim_buf_set_lines(v.buf, 0, -1, false, lines)
  vim.bo[v.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(v.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(v.buf, ns, m[1], 0, { end_col = #lines[m[1] + 1], hl_group = m[2] })
  end
end

function M.render_all()
  for sid in pairs(views) do
    render(sid)
  end
end

local function send(sid, q, answers)
  local tmp = vim.fn.tempname() .. ".json"
  vim.fn.writefile({ vim.json.encode(answers) }, tmp)
  vim.system({ "python3", "-I", script, "answer", sid, tmp }, {}, function(res)
    vim.schedule(function()
      vim.fn.delete(tmp)
      if res.code ~= 0 then
        vim.notify("Claude board: could not send the answer", vim.log.levels.ERROR)
        return
      end
      views[sid].sent = { ts = q.ts }
      render(sid)
    end)
  end)
end

local function current_question(sid)
  local q = question_of(board().find(sid))
  if not q then
    vim.notify("No pending question for this session", vim.log.levels.INFO)
  elseif not q.answerable then
    vim.notify("This question was asked before the board was open; answer it in the terminal", vim.log.levels.WARN)
  else
    return q
  end
end

-- Asks every question in turn, then sends all the answers together.
local function step_through(sid)
  local q = current_question(sid)
  if not q then
    return
  end
  local answers = {}
  local function ask(i)
    local item = q.questions[i]
    if not item then
      send(sid, q, answers)
      return
    end
    local labels = vim.tbl_map(function(o)
      return o.label
    end, item.options or {})
    local function take(answer)
      if not answer or answer == "" then
        return
      end
      answers[item.question] = answer
      ask(i + 1)
    end
    if item.multiSelect then
      local menu = {}
      for oi, l in ipairs(labels) do
        table.insert(menu, oi .. ") " .. l)
      end
      vim.ui.input({ prompt = item.question .. "  [" .. table.concat(menu, "  ") .. "]  numbers or text: " }, function(input)
        if not input then
          return
        end
        local picked = {}
        for n in input:gmatch("%d+") do
          table.insert(picked, labels[tonumber(n)])
        end
        take(#picked > 0 and table.concat(picked, ", ") or input)
      end)
    else
      local choices = vim.list_extend(vim.deepcopy(labels), { "Other…" })
      vim.ui.select(choices, { prompt = item.question }, function(choice, idx)
        if idx == #choices then
          vim.ui.input({ prompt = item.question .. ": " }, take)
        else
          take(choice)
        end
      end)
    end
  end
  ask(1)
end

local function quick_pick(sid, n)
  local q = current_question(sid)
  if not q then
    return
  end
  local item = q.questions[1]
  if #q.questions > 1 or item.multiSelect then
    step_through(sid)
    return
  end
  local opt = (item.options or {})[n]
  if opt then
    send(sid, q, { [item.question] = opt.label })
  end
end

local function own_answer(sid)
  local q = current_question(sid)
  if not q then
    return
  end
  if #q.questions > 1 then
    step_through(sid)
    return
  end
  vim.ui.input({ prompt = q.questions[1].question .. ": " }, function(input)
    if input and input ~= "" then
      send(sid, q, { [q.questions[1].question] = input })
    end
  end)
end

local function decide(sid, behavior, with_note, mode)
  local s = board().find(sid)
  local p = s and s.pendingInput
  if not (p and p.kind == "permission") then
    vim.notify("No pending permission prompt for this session", vim.log.levels.INFO)
    return
  elseif not p.answerable then
    vim.notify("This prompt was raised before the board was open; answer it in the terminal", vim.log.levels.WARN)
    return
  end
  if not with_note then
    send(sid, p, { behavior = behavior, mode = mode })
    return
  end
  vim.ui.input({ prompt = "Reason for Claude: " }, function(input)
    if input then
      send(sid, p, { behavior = behavior, message = input ~= "" and input or nil })
    end
  end)
end

function M.attach(sid)
  local s = board().find(sid)
  if not (s and s.attachable) then
    vim.notify("Only background sessions (claude --bg) can be opened here", vim.log.levels.INFO)
    return
  end
  M.open(sid)
  vim.cmd("enew")
  vim.fn.jobstart({ "claude", "attach", sid }, { term = true })
  vim.cmd("startinsert")
end

-- Header bar listing every tab; session tabs carry their status icon. Click or gt/gT to switch.
function M.winbar()
  local parts, cur = {}, vim.api.nvim_get_current_tabpage()
  for i, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local ok, sid = pcall(vim.api.nvim_tabpage_get_var, tab, "claude_board_sid")
    local label
    if ok then
      local s = board().find(sid)
      label = (s and (board().icons[s.status] or "·") or "×") .. " " .. (s and s.name or "ended")
    else
      local name = ""
      for _, win in ipairs({ vim.api.nvim_tabpage_get_win(tab), unpack(vim.api.nvim_tabpage_list_wins(tab)) }) do
        name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
        if not name:find("^claude://") then
          break
        end
      end
      label = (name ~= "" and not name:find("^claude://")) and vim.fn.fnamemodify(name, ":t") or "[No Name]"
    end
    label = vim.fn.strcharpart(label, 0, 22)
    local group = tab == cur and "%#TabLineSel#" or "%#TabLine#"
    table.insert(parts, string.format("%s%%%d@v:lua.ClaudeBoardTab@ %d %s %%X", group, tab, i, (label:gsub("%%", "%%%%"))))
  end
  return table.concat(parts, "%#TabLineFill# ") .. "%#TabLineFill#"
end

_G.ClaudeBoardTab = function(tab)
  if vim.api.nvim_tabpage_is_valid(tab) then
    vim.api.nvim_set_current_tabpage(tab)
  end
end

local function find_tab(sid)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local ok, val = pcall(vim.api.nvim_tabpage_get_var, tab, "claude_board_sid")
    if ok and val == sid then
      return tab
    end
  end
end

function M.open(sid)
  local tab = find_tab(sid)
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
    return
  end
  local s = board().find(sid)
  vim.cmd("tabnew")
  vim.t.claude_board_sid = sid
  local v = views[sid]
  if not (v and vim.api.nvim_buf_is_valid(v.buf)) then
    local buf = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, buf, "claude://" .. (s and s.name or sid))
    vim.bo[buf].filetype = "claudeboard"
    vim.bo[buf].bufhidden = "hide"
    v = { buf = buf }
    views[sid] = v
    local map = function(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc })
    end
    for n = 1, 9 do
      map(tostring(n), function()
        quick_pick(sid, n)
      end, "Answer with option " .. n)
    end
    map("o", function()
      own_answer(sid)
    end, "Answer in your own words")
    map("A", function()
      step_through(sid)
    end, "Answer each question")
    map("y", function()
      decide(sid, "allow")
    end, "Allow the pending permission")
    map("e", function()
      decide(sid, "allow", false, "acceptEdits")
    end, "Allow and switch to accept-edits mode")
    map("u", function()
      decide(sid, "allow", false, "auto")
    end, "Allow and switch to auto mode")
    map("m", function()
      decide(sid, "allow", false, "default")
    end, "Allow and switch to manual mode")
    map("<CR>", function()
      local file = views[sid].files[vim.api.nvim_win_get_cursor(0)[1]]
      if file and vim.fn.filereadable(file) == 1 then
        vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(file))
      elseif file then
        vim.notify("File no longer exists: " .. file, vim.log.levels.WARN)
      end
    end, "Open the plan or document under the cursor")
    map("n", function()
      decide(sid, "deny")
    end, "Deny the pending permission")
    map("N", function()
      decide(sid, "deny", true)
    end, "Deny with a note")
    map("a", function()
      M.attach(sid)
    end, "Attach background session")
    map("r", board().refresh, "Refresh")
    map("q", "<cmd>tabclose<cr>", "Close tab")
  end
  vim.api.nvim_win_set_buf(0, v.buf)
  vim.wo.number, vim.wo.relativenumber, vim.wo.signcolumn, vim.wo.wrap = false, false, "no", true
  vim.wo.winbar = "%!v:lua.require'claude_board.detail'.winbar()"
  board().ensure_sidebar(false)
  render(sid)
  board().start()
end

return M
