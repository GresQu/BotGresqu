local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

onScreenPw = macro(1000, "On screen PW", function()
  storage.onScreenPw_seen = storage.onScreenPw_seen or {}
  storage.onScreenPw_lastClear = storage.onScreenPw_lastClear or now

  local receiver = storage.onScreenPw_receiver or "xcxc"

  for _, spec in ipairs(getSpectators(posz())) do
    if spec ~= player and spec:isPlayer() then
      local nick = spec:getName()

      if not storage.onScreenPw_seen[nick] then
        talkPrivate(receiver, 'pojawil sie "' .. nick .. '"')
        storage.onScreenPw_seen[nick] = true
      end
    end
  end

  if now - storage.onScreenPw_lastClear >= 15000 then
    storage.onScreenPw_seen = {}
    storage.onScreenPw_lastClear = now
  end
end)

UI.TextEdit(storage.onScreenPw_receiver or "xcxc", function(widget, newText)
  storage.onScreenPw_receiver = newText
end)
