-- Names each tab after the directory of its focused terminal while that
-- terminal sits at a shell prompt, and after the terminal's title while a
-- program runs in it. A tab renamed by hand keeps its name; rename it to an
-- empty name to hand it back.
--
-- Event handlers only run in a script, not in init.lua, so init.lua starts
-- this as: rex do tab_names.lua --all

local terminal = "com.superlogical.terminal"
local home = os.getenv("HOME")

-- Rex reports the login process as the terminal's foreground process
-- whatever runs under the shell, so the title is the only sign of a running
-- program. oh-my-zsh titles an idle shell "%n@%m:%~" and a busy one with its
-- command line, and programs such as hx and claude set their own.
local function at_prompt(title)
  return title:match("^[^%s@]+@[^%s:]+:") ~= nil
end

-- pwd is a file:// URL that includes the hostname and percent-encodes
-- characters such as spaces.
local function dir_name(pwd)
  local path = pwd and pwd:match("^file://[^/]*(/.*)$")
  if path == nil then return nil end
  path = path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  path = path:gsub("(.)/$", "%1")
  if path == home then return "~" end
  return path:match("([^/]+)$") or path
end

-- rex.block.call only reaches a block from inside an event handler, or when
-- the script inherited a session from the terminal it was started in. This
-- script calls from timers, under the server, so name the session on every
-- call.
local function block_method(session_id, block_id, method)
  return rex.call("block.method", {
    session_id = session_id, block_id = block_id, method = method,
  })
end

local function tab_name(session_id, block_id)
  if block_id == nil then return nil end
  local t = block_method(session_id, block_id, "title")
  if t == nil then return nil end
  local title = t.title or ""
  if title ~= "" and not at_prompt(title) then return title end
  local p = block_method(session_id, block_id, "pwd")
  return dir_name(p and p.pwd)
end

-- The label this script last gave each window, to tell its own names apart
-- from ones set by hand.
local named = {}

local function is_ours(window, want)
  local label = window.label or ""
  return label == ""
    or label == "Window " .. window.window_id:sub(-8)
    or label == named[window.window_id]
    -- After a restart named is empty, so also claim a tab whose name already
    -- matches what this script would give it.
    or label == want
end

local function refresh(session_id)
  local view = rex.session.view{ session_id = session_id }
  if view == nil then return end
  for _, w in ipairs(view.windows or {}) do
    local want = tab_name(session_id, w.focused_block_id)
    if want ~= nil and is_ours(w, want) then
      named[w.window_id] = want
      if w.label ~= want then
        rex.session.set_window_label{
          session_id = session_id, window_id = w.window_id, label = want,
        }
      end
    end
  end
end

-- A command changes the title and directory together, and focus changes
-- arrive as a burst of view changes, so refresh once per burst.
local pending = {}
local function schedule(ctx)
  local id = ctx.session_id
  if pending[id] then pending[id]:cancel() end
  pending[id] = rex.after(0.1, function()
    pending[id] = nil
    refresh(id)
  end)
end

rex.on("terminal.title_changed", schedule)
rex.on("terminal.pwd_changed", schedule)
rex.on("session_view_changed", schedule)
rex.on("window_closed", function(_, ev) named[ev.window_id] = nil end)

-- Name the tabs that already exist rather than waiting for each to change.
-- Session calls fail until --all has attached the script to every session,
-- which happens only after the top level returns, so wait for a timer.
rex.after(0, function()
  local list = rex.call("session.list")
  for _, s in ipairs(list and list.sessions or {}) do refresh(s.session_id) end
end)
