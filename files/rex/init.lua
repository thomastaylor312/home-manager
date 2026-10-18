local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
-- Mirrors how Rex locates init.lua; the chunk name doesn't carry its path.
local config_dir = (os.getenv("REX_CONFIG") or ""):match("^(.*)/[^/]*$")
  or (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/rex"

-- The terminal reports its directory as a file:// URL that includes the
-- hostname (file://host/path), so drop the scheme and host to get the path.
local function focused_dir(ctx)
  if ctx.block_id == nil then return nil end
  local r = rex.block.call(terminal, "pwd", { block_id = ctx.block_id })
  if r == nil or r.pwd == nil then return nil end
  return r.pwd:match("^file://[^/]*(/.*)$")
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

local function tiled_layer(ctx)
  local view, err = rex.session.view{}
  if err ~= nil then error(err, 0) end
  for _, w in ipairs(view.windows) do
    for _, l in ipairs(w.layers) do
      if l.kind == "tiled" then
        local here = ctx.block_id == nil and w.window_id == view.active_window_id
        each_leaf(l.layout, function(id) here = here or id == ctx.block_id end)
        if here then return l end
      end
    end
  end
  error("no tiled layout holds the focused pane", 0)
end

rex.action{
  name        = "claude_sidebar",
  title       = "Open Claude Sidebar",
  description = "claude in a full-height sidebar on the right of the current tab, or focus the one already there.",
  keywords    = "claude sidebar",
  run         = function(ctx)
    local layer = tiled_layer(ctx)
    for _, b in ipairs(layer.blocks) do
      if b.label == claude_label then
        local _, err = rex.session.focus_block{ block_id = b.block_id }
        if err ~= nil then error(err, 0) end
        return { block_id = b.block_id }
      end
    end

    local cwd = focused_dir(ctx)
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
      anchor_block_id = keep,
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
  end,
}

rex.bind("cmd+l", "claude_sidebar")

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
