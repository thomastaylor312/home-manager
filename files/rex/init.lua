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
-- detached script (tear_off.lua) that can wait between steps. The server
-- doesn't put rex on the PATH of commands it starts, but it is their parent
-- process, so look up the server's own executable. Needs Remote Control
-- turned on in the app's settings.
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

local function tear_off(ctx, window_id)
  local client = app_client(ctx)
  if client == nil then return end
  -- A detached command is reparented, so its $PPID is no longer the server.
  -- Look the path up with a plain exec first. Linux's ps truncates comm to
  -- the bare name, so prefer /proc there.
  local ps = rex.exec({ "sh", "-c", "readlink /proc/$PPID/exe 2>/dev/null || ps -o comm= -p $PPID" })
  if ps == nil or not ps.ok then return end
  local rex_bin = ps.stdout:gsub("%s+$", "")
  rex.exec.start({
    rex_bin, "-C", client, "do", config_dir .. "/tear_off.lua",
    "-s", ctx.session_id, "window_id=" .. window_id,
  }, { detach = true })
end

rex.action{
  name        = "editor_layout",
  title       = "Open Editor Layout",
  description = "hx on the left, a shell below it, and claude in a sidebar on the right, in a new window.",
  keywords    = "helix hx claude workspace",
  args        = { cwd = "string?" },
  run         = function(ctx, args)
    local cwd = args.cwd or focused_dir(ctx)
    -- Type the program into an interactive shell rather than passing it as
    -- `command`: the command shell doesn't load .zshrc, so nix-installed
    -- programs like hx aren't on its PATH. This also leaves a shell behind
    -- when the program exits.
    local function term(input)
      return rex.layout.block{
        flavor  = shell,
        options = { initial_input = input, cwd = cwd },
      }
    end

    -- Leave focus alone so that tear_off.lua can see the app select the tab:
    -- if the new tab were already active, selecting it would change nothing.
    local w, err = rex.session.new_window{
      focus  = false,
      layout = rex.layout.horizontal(0.67,
        rex.layout.vertical(0.75, term("hx\n"), term(nil)),
        term("claude\n")),
    }
    if err ~= nil then error(err, 0) end
    tear_off(ctx, w.window_id)
    return { window_id = w.window_id }
  end,
}

rex.bind("shift+cmd+l", "editor_layout")
