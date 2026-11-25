local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
-- Mirrors how Rex locates init.lua; the chunk name doesn't carry its path.
local config_dir = (os.getenv("REX_CONFIG") or ""):match("^(.*)/[^/]*$")
  or (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/rex"

-- The terminal reports its directory as a file:// URL that includes the
-- hostname (file://host/path), so drop the scheme and host to get the path.
local function block_dir(block_id)
  if block_id == nil then return nil end
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  if r == nil or r.pwd == nil then return nil end
  return r.pwd:match("^file://[^/]*(/.*)$")
end

local function focused_dir(ctx)
  return block_dir(ctx.block_id)
end

-- Queued client actions are all sent after an action returns, and the app
-- doesn't wait for one to finish before starting the next, so a select
-- followed by a move can move the wrong tab. Hand the sequence to a
-- detached script (tear_off.lua) that can wait between steps. Needs Remote
-- Control turned on in the app's settings.
--
-- Run from the CLI, ctx.client_id is that CLI's connection, which is gone
-- by the time the script starts, so fall back to the only connected app.
local function app_client(ctx)
  local list = rex.call("client.list")
  local apps = {}
  for _, c in ipairs(list and list.clients or {}) do
    if c.info and c.info.kind == "app" then
      if c.client_id == ctx.client_id then return c.client_id end
      table.insert(apps, c.client_id)
    end
  end
  if #apps == 1 then return apps[1] end
end

-- The server doesn't put rex on the PATH of commands it starts, but it is
-- their parent process, so look up the server's own executable. A detached
-- command is reparented, so its $PPID is no longer the server; look the path
-- up with a plain exec first. Linux's ps truncates comm to the bare name, so
-- prefer /proc there.
local function server_bin()
  local ps = rex.exec({ "sh", "-c", "readlink /proc/$PPID/exe 2>/dev/null || ps -o comm= -p $PPID" })
  if ps == nil or not ps.ok then return nil end
  return (ps.stdout:gsub("%s+$", ""))
end

local function tear_off(ctx, window_id)
  local client = app_client(ctx)
  if client == nil then return end
  local rex_bin = server_bin()
  if rex_bin == nil then return end
  rex.exec.start({
    rex_bin, "-C", client, "do", config_dir .. "/tear_off.lua",
    "-s", ctx.session_id, "window_id=" .. window_id,
  }, { detach = true })
end

-- Share of the window's width left of the claude sidebar, and of the editor
-- column's height given to hx above its shell.
local sidebar_ratio = 0.67
local editor_ratio = 0.75

-- Type the program into an interactive shell rather than passing it as
-- `command`: the command shell doesn't load .zshrc, so nix-installed
-- programs like hx aren't on its PATH. This also leaves a shell behind
-- when the program exits.
local function term(cwd, input)
  return rex.layout.block{
    flavor  = shell,
    options = { initial_input = input, cwd = cwd },
  }
end

local function editor(cwd)
  return rex.layout.vertical(editor_ratio, term(cwd, "hx\n"), term(cwd, nil))
end

-- Marks the pane claude_sidebar finds instead of opening a second one. Block
-- labels don't follow the terminal title, so the mark stays put, even after
-- claude exits and leaves its shell behind.
local claude_label = "claude"

local function label_claude(block_id)
  local _, err = rex.session.set_block_label{ block_id = block_id, label = claude_label }
  if err ~= nil then error(err, 0) end
end

local function open_window(ctx, layout)
  -- Leave focus alone so that tear_off.lua can see the app select the tab:
  -- if the new tab were already active, selecting it would change nothing.
  local w, err = rex.session.new_window{ focus = false, layout = layout }
  if err ~= nil then error(err, 0) end
  tear_off(ctx, w.window_id)
  return w
end

rex.action{
  name        = "editor_layout",
  title       = "Open Editor Layout",
  description = "hx on the left, a shell below it, and claude in a sidebar on the right, in a new window.",
  keywords    = "helix hx claude workspace",
  args        = { cwd = "string?" },
  run         = function(ctx, args)
    local cwd = args.cwd or focused_dir(ctx)
    local w = open_window(ctx, rex.layout.horizontal(sidebar_ratio,
      editor(cwd), term(cwd, "claude\n")))
    -- block_ids is in depth-first order, so the sidebar is last.
    label_claude(w.block_ids[#w.block_ids])
    return { window_id = w.window_id }
  end,
}

rex.bind("shift+cmd+l", "editor_layout")

rex.action{
  name        = "editor_only_layout",
  title       = "Open Editor Layout Without Claude",
  description = "hx with a shell below it, in a new window.",
  keywords    = "helix hx workspace",
  args        = { cwd = "string?" },
  run         = function(ctx, args)
    local w = open_window(ctx, editor(args.cwd or focused_dir(ctx)))
    return { window_id = w.window_id }
  end,
}

rex.bind("shift+cmd+o", "editor_only_layout")

local function first_leaf(node)
  while node.split ~= nil do node = node.split.before end
  return node.block_id
end

local function each_leaf(node, fn)
  if node.split == nil then return fn(node.block_id) end
  each_leaf(node.split.before, fn)
  each_leaf(node.split.after, fn)
end

-- Grow the block standing in for `node` back into `node`'s layout. Each
-- split's first leaf stands in for the whole split, so put the after half's
-- first leaf beside it and then expand both halves the same way.
local function rebuild(node)
  if node.split == nil then return end
  local s = node.split
  local _, err = rex.session.move_block{
    block_id        = first_leaf(s.after),
    anchor_block_id = first_leaf(s.before),
    direction       = s.direction,
    side            = "after",
    ratio           = s.ratio,
  }
  if err ~= nil then error(err, 0) end
  rebuild(s.before)
  rebuild(s.after)
end

local function tiled_layer(block_id)
  local view, err = rex.session.view{}
  if err ~= nil then error(err, 0) end
  for _, w in ipairs(view.windows) do
    for _, l in ipairs(w.layers) do
      if l.kind == "tiled" then
        local here = block_id == nil and w.window_id == view.active_window_id
        each_leaf(l.layout, function(id) here = here or id == block_id end)
        if here then return l end
      end
    end
  end
  error("no tiled layout holds the focused pane", 0)
end

-- Puts claude in a full-height sidebar on the right of the tab holding
-- block_id (the active tab when nil), or focuses the one already there. claude
-- starts in cwd, or in block_id's directory when cwd is nil.
local function claude_sidebar(block_id, cwd)
  local layer = tiled_layer(block_id)
  for _, b in ipairs(layer.blocks) do
    if b.label == claude_label then
      local _, err = rex.session.focus_block{ block_id = b.block_id }
      if err ~= nil then error(err, 0) end
      return { block_id = b.block_id }
    end
  end

  cwd = cwd or block_dir(block_id)
  -- new_split can only split one block, and the sidebar has to sit beside
  -- the whole layout. So split the first block and move every other block
  -- from where it is now into place around it. Each move collapses the
  -- split it leaves, so once the last block moves, the old layout is gone
  -- and the new one fills the window.
  --
  -- The app's automatic split balancing equalizes every split in a window
  -- it shows whenever a pane opens there, a moment after this returns, so
  -- the ratios only survive with that setting turned off.
  local root = layer.layout
  local keep = first_leaf(root)
  local r, err = rex.session.new_split{
    anchor_id       = keep,
    direction       = "horizontal",
    side            = "after",
    ratio           = sidebar_ratio,
    layout          = term(cwd, "claude\n"),
    focus           = true,
  }
  if err ~= nil then error(err, 0) end
  label_claude(r.block_ids[1])
  rebuild(root)
  return { block_id = r.block_ids[1] }
end

rex.action{
  name        = "claude_sidebar",
  title       = "Open Claude Sidebar",
  description = "claude in a full-height sidebar on the right of the current tab, or focus the one already there.",
  keywords    = "claude sidebar",
  run         = function(ctx) return claude_sidebar(ctx.block_id) end,
}

rex.bind("cmd+l", "claude_sidebar")

local home = os.getenv("HOME")

-- home-manager installs jj, but the server starts commands with only the
-- system PATH.
local jj_env = { PATH = home .. "/.nix-profile/bin:" .. (os.getenv("PATH") or "/usr/bin:/bin") }

local function jj(cwd, argv, timeout)
  local cmd = { "jj", "--no-pager", "--color=never" }
  for _, a in ipairs(argv) do table.insert(cmd, a) end
  local r, err = rex.exec(cmd, { cwd = cwd, env = jj_env, timeout = timeout or 10 })
  if r == nil then error("jj: " .. err, 0) end
  if not r.ok then error((r.stderr:gsub("%s+$", "")), 0) end
  return r.stdout
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- One tab-separated line per change. Long brackets keep the escapes for jj's
-- template language rather than Lua.
local change_template = [[change_id ++ "\t" ++ change_id.short(8) ++ "\t"
  ++ local_bookmarks.map(|b| b.name()).join(", ") ++ "\t"
  ++ description.first_line() ++ "\n"]]

-- The tip of each of my unmerged lines of work. jj leaves an empty,
-- undescribed working-copy commit on top of whatever was last edited, so drop
-- those first; otherwise a bookmarked branch's tip would be that blank commit
-- instead of the commit carrying the bookmark.
local tips_revset = [[heads((mutable() & mine()) ~ (empty() & description(exact:"")))]]

local function changes(root, revset)
  local out = jj(root, { "log", "--no-graph", "-r", revset, "-T", change_template })
  local list = {}
  for line in out:gmatch("[^\n]+") do
    local id, short, bookmarks, desc = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if id ~= nil then
      table.insert(list, { change_id = id, short = short, bookmarks = bookmarks, desc = desc })
    end
  end
  return list
end

local function resolve_change(root, rev)
  local list = changes(root, rev)
  if #list ~= 1 then
    error(("%q names %d changes, not one"):format(rev, #list), 0)
  end
  return list[1]
end

-- Cancelling a prompt ends the action quietly; anything else is an error.
local function check_prompt(why, detail)
  if why == "cancelled" then return end
  error("couldn't ask: " .. why .. (detail and (" (" .. detail .. ")") or ""), 0)
end

-- args let the action run from the CLI without prompts, e.g.
--   rex do jj_workspace rev=@- name=scratch
rex.action{
  name        = "jj_workspace",
  title       = "New jj Workspace…",
  description = "Create a jj workspace in ~/tmp from a branch tip or a pasted change, and open it in a new tab with claude beside it.",
  keywords    = "jj jujutsu workspace worktree branch bookmark change claude",
  args        = { rev = "string?", name = "string?", cwd = "string?" },
  run         = function(ctx, args)
    local cwd = args.cwd or focused_dir(ctx)
    if cwd == nil then error("can't tell which directory the focused pane is in", 0) end
    local root = trim(jj(cwd, { "root" }))

    local change
    if args.rev ~= nil then
      change = resolve_change(root, trim(args.rev))
    else
      -- Change IDs repeat when a change is divergent, so key the list by
      -- position instead.
      local tips = changes(root, tips_revset)
      local items = {}
      for i, t in ipairs(tips) do
        local desc = t.desc ~= "" and t.desc or "(no description)"
        items[i] = {
          id    = tostring(i),
          title = (t.bookmarks ~= "" and t.bookmarks or t.short) .. " " .. desc,
          icon  = t.bookmarks ~= "" and "branch" or "code",
        }
      end
      local picked, why, detail = rex.ui.pick{
        title       = "New jj workspace from",
        placeholder = "Filter branches, or paste a change ID",
        items       = items,
        allow_other = true,
      }
      if picked == nil then return check_prompt(why, detail) end
      if type(picked) == "table" then
        change = resolve_change(root, trim(picked.text))
      else
        change = tips[tonumber(picked)]
      end
    end

    local default = root:match("([^/]+)$") .. "-" .. change.short
    local name = args.name
    if name == nil then
      local why, detail
      name, why, detail = rex.ui.input{
        title       = "Directory in ~/tmp",
        placeholder = default,
        confirm     = "Create workspace",
      }
      if name == nil then return check_prompt(why, detail) end
    end
    name = trim(name)
    if name == "" then name = default end

    local dest = home .. "/tmp/" .. name
    local mk = rex.exec({ "mkdir", "-p", home .. "/tmp" })
    if mk == nil or not mk.ok then error("couldn't create ~/tmp", 0) end
    jj(root, { "workspace", "add", "-r", change.change_id, dest }, 25)

    local w, err = rex.session.new_window{ layout = term(dest, nil) }
    if err ~= nil then error(err, 0) end
    local sidebar = claude_sidebar(w.block_ids[1], dest)

    -- new_window makes the tab the server's active one, but each app keeps its
    -- own selection, so also ask the app that ran the action to show it. Run
    -- from the CLI there may be no app to ask, which isn't worth failing over.
    if ctx.session_id ~= nil then
      pcall(rex.client.queue, "session.select", { session_id = ctx.session_id, window_id = w.window_id })
    end
    return { window_id = w.window_id, path = dest, claude_block_id = sidebar.block_id }
  end,
}

-- A secondary workspace's .jj/repo is a file holding the path of the main
-- workspace's .jj/repo directory, relative to its own .jj directory. Returns
-- nil for a main workspace, where .jj/repo is the directory itself.
local function main_workspace_root(ws_root)
  local t = rex.exec({ "test", "-f", ws_root .. "/.jj/repo" })
  if t == nil or not t.ok then return nil end
  local f = io.open(ws_root .. "/.jj/repo")
  if f == nil then return nil end
  local repo = trim(f:read("*a"))
  f:close()
  if repo:sub(1, 1) ~= "/" then repo = ws_root .. "/.jj/" .. repo end
  return (repo:gsub("/%.jj/repo/?$", ""))
end

local function tilde(path)
  if path:sub(1, #home + 1) == home .. "/" then return "~" .. path:sub(#home + 1) end
  return path
end

-- args let the action run from the CLI, e.g.
--   rex do jj_workspace_remove cwd=~/tmp/scratch confirm=false
-- Given cwd, it leaves tabs alone, since the workspace needn't be in one.
rex.action{
  name        = "jj_workspace_remove",
  title       = "Remove jj Workspace…",
  description = "Remove the jj workspace the focused pane is in, delete its directory, and close its tab.",
  keywords    = "jj jujutsu workspace worktree remove delete forget cleanup",
  args        = { cwd = "string?", confirm = "boolean?" },
  run         = function(ctx, args)
    local cwd = args.cwd or focused_dir(ctx)
    if cwd == nil then error("can't tell which directory the focused pane is in", 0) end
    local ws_root = trim(jj(cwd, { "workspace", "root" }))
    local main = main_workspace_root(ws_root)
    if main == nil then
      error(tilde(ws_root) .. " is the repo's main workspace, not one added with jj workspace add", 0)
    end

    local name
    local list = jj(main, { "--ignore-working-copy", "workspace", "list",
      "-T", [[name ++ "\t" ++ root ++ "\n"]] })
    for line in list:gmatch("[^\n]+") do
      local n, root = line:match("^([^\t]*)\t(.*)$")
      if root == ws_root then name = n end
    end
    if name == nil then error("jj doesn't list a workspace at " .. tilde(ws_root), 0) end

    local window_id
    if args.cwd == nil and ctx.block_id ~= nil then
      local d = rex.session.describe_block{ block_id = ctx.block_id }
      window_id = d and d.block and d.block.window_id
    end

    if args.confirm ~= false then
      local ok, why, detail = rex.ui.pick{
        title = "Remove jj workspace " .. name .. "?",
        items = { {
          id    = "remove",
          title = "Delete " .. tilde(ws_root) .. (window_id and " and close this tab" or ""),
          icon  = "folder",
        } },
      }
      if ok == nil then return check_prompt(why, detail) end
    end

    -- Run from the main workspace rather than the one going away. jj first
    -- snapshots the removed workspace's files, including edits no jj command
    -- has seen yet, into a "SNAPSHOT OF REMOVED WORKSPACE" commit, so nothing
    -- tracked is lost; from inside, it would also warn that its own workspace
    -- no longer exists.
    jj(main, { "workspace", "remove", name }, 25)

    if window_id ~= nil then
      local _, err = rex.session.close_window{ window_id = window_id }
      if err ~= nil then error(err, 0) end
    end
    return { workspace = name, removed = ws_root }
  end,
}

-- term() types its input into a shell, so quote each argument for it.
local function shell_line(argv)
  local quoted = {}
  for i, a in ipairs(argv) do
    quoted[i] = "'" .. a:gsub("'", [['\'']]) .. "'"
  end
  return table.concat(quoted, " ") .. "\n"
end

-- Claude Code writes ~/.claude/sessions/PID.json for each running process,
-- naming the conversation it has open, so a pane's foreground pid leads
-- straight to it. Returns nil for any other program.
local function claude_fork(fg)
  local f = io.open(os.getenv("HOME") .. "/.claude/sessions/" .. fg.pid .. ".json")
  if f == nil then return nil end
  local s = rex.json.decode(f:read("*a"))
  f:close()

  -- Run the same claude as the original pane rather than whichever one the
  -- new shell finds first on its PATH.
  local cmd = { fg.invoked_path or fg.path, "--resume", s.sessionId, "--fork-session" }

  -- The transcript records the permission mode on each message, so this
  -- follows shift+tab changes made after launch, unlike the launch flags.
  local r = rex.exec({ "sh", "-c",
    [[grep -ho '"permissionMode":"[A-Za-z]*"' "$HOME"/.claude/projects/*/"$1".jsonl | tail -1]],
    "sh", s.sessionId })
  local mode = r and r.stdout and r.stdout:match('"permissionMode":"(%a+)"')
  if mode then
    table.insert(cmd, "--permission-mode")
    table.insert(cmd, mode)
  end

  if s.nameSource == "user" and s.name then
    table.insert(cmd, "--name")
    table.insert(cmd, s.name .. "-fork")
  end
  -- Resume looks the conversation up by the directory it started in.
  return cmd, s.cwd
end

local uuid = ("%x"):rep(8) .. "%-" .. ("%x"):rep(4) .. "%-" .. ("%x"):rep(4)
  .. "%-" .. ("%x"):rep(4) .. "%-" .. ("%x"):rep(12)

-- Nothing on disk ties a Codex TUI's pid to its thread: the shared
-- app-server daemon owns and writes every thread. The TUI only shows the
-- thread's ID when tui.status_line in ~/.codex/config.toml includes
-- "thread-id" (put it first so a narrow pane doesn't cut it off), so read it
-- from the footer, and otherwise leave the ID out so `codex fork` shows its
-- picker of this directory's threads.
local function codex_fork(block_id, fg)
  local cmd = { fg.invoked_path or fg.path, "fork" }
  local r = rex.block.call(terminal, "format", { block_id = block_id, trim = true })
  local lines = {}
  for line in ((r and r.content) or ""):gmatch("[^\n]+") do
    table.insert(lines, line)
  end
  -- Only search the footer: the transcript above it can hold other IDs.
  for i = #lines, math.max(1, #lines - 3), -1 do
    local id = lines[i]:match(uuid)
    if id then
      table.insert(cmd, id)
      break
    end
  end
  return cmd, fg.cwd
end

rex.action{
  name        = "fork_session",
  title       = "Fork Agent Session",
  description = "Fork the Claude Code or Codex conversation in the focused pane into a new pane on its right.",
  keywords    = "claude codex fork branch",
  run         = function(ctx)
    if ctx.block_id == nil then error("no pane is focused", 0) end
    local proc, err = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    if err ~= nil then error(err, 0) end
    local fg = proc and proc.foreground
    if fg == nil then error("nothing is running in the focused pane", 0) end

    local cmd, cwd
    if (fg.argv0 or fg.path or ""):match("([^/]*)$") == "codex" then
      cmd, cwd = codex_fork(ctx.block_id, fg)
    else
      cmd, cwd = claude_fork(fg)
    end
    if cmd == nil then error("the focused pane isn't running Claude Code or Codex", 0) end

    local r, err2 = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side      = "after",
      layout    = term(cwd, shell_line(cmd)),
    }
    if err2 ~= nil then error(err2, 0) end
    return { block_id = r.block_ids[1] }
  end,
}

rex.bind("shift+cmd+f", "fork_session")

-- Event handlers don't run in init.lua, so tab naming lives in a script
-- (tab_names.lua) that runs beside the server. The file loads again on every
-- reload and `rex config check`, so stop any copy already running, which also
-- picks up changes to the script on reload. Launching it from here rather
-- than launchd means it uses the rex that ships with whichever server
-- version is running. Its output goes to a file: once this load finishes
-- nothing reads the pipe it would otherwise get, and the first line it
-- prints kills it with SIGPIPE.
local tab_names = config_dir .. "/tab_names.lua"
local rex_bin = server_bin()
if rex_bin ~= nil then
  rex.exec({ "pkill", "-f", tab_names })
  rex.exec.start({
    "sh", "-c", 'exec "$0" do "$1" --all >"${TMPDIR:-/tmp}/rex-tab-names.log" 2>&1',
    rex_bin, tab_names,
  }, { detach = true })
end
