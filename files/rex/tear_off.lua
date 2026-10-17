-- Moves a tab into its own app window: rex -C CLIENT do tear_off.lua -s SESSION window_id=WINDOW
--
-- The app's "Move Tab to New Window" acts on the tab the app has selected,
-- which isn't necessarily the server's active tab. So select the tab first,
-- and move it only once the app reports the selection. The app drops a
-- select for a tab it hasn't heard about yet, so keep asking until it lands.
local id = rex.args.window_id
if id == nil then error("window_id is required", 0) end

local function is_target(ev) return ev.window_id == id end

for _ = 1, 20 do
  rex.client.queue("session.select", { session_id = rex.session_id, window_id = id })
  if rex.wait("active_window_changed", is_target, 0.25) then
    rex.client.queue("client.tab.move_to_new_window")
    return
  end
end

-- Moving now could take whatever tab the app has selected instead.
error("the app never selected " .. id .. "; leaving it as a tab", 0)
