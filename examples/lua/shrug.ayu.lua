-- ==AyuPlugin==
-- @id shrug-lua
-- @name Shrug (Lua)
-- @author AyuGramm team
-- @version 1.0
-- @description ".shrug" in a message becomes ¯\_(ツ)_/¯; a toast when the plugin starts.
-- @permissions overlay
-- ==/AyuPlugin==

ayu.hooks.before(ayu.points.outgoing_text, function(text, ctx)
  if text == ".shrug" then return "¯\\_(ツ)_/¯" end
  return nil -- nil keeps the text unchanged
end)

ayu.on("load", function()
  ayu.toast("Shrug is ready")
  -- Any API from API.md is reachable through ayu.api / ayu.call:
  ayu.api("ui.overlay.addText")({ id = "shrug", text = "¯\\_(ツ)_/¯", anchor = "topRight" })
end)
