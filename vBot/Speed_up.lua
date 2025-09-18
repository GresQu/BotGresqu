setDefaultTab("HP")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
UtilityLabel1 = UI.Label("-- [[ Others ]] --")
UtilityLabel1:setColor("green")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

UI.Button("Speed Up Show/Hide", function(widget)
  showSpeedUp = not showSpeedUp
  if showSpeedUp then
    speedUpLabel:show()
    speedUpTextEdit:show()
  else
    speedUpLabel:hide()
    speedUpTextEdit:hide()
  end
end)

speedUpLabel = UI.Label("Spell Name:")
speedUpLabel:hide()
speedUpTextEdit = UI.TextEdit(storage.hasteSpell or "Speed Up", function(widget, newText)
  storage.hasteSpell = newText
end)
speedUpTextEdit:hide()

macro(500, "Speed Up", function() 
  if hasHaste() then return end
  if not storage.hasteSpell then storage.hasteSpell = 'Speed Up' end
  say(storage.hasteSpell)
end)
