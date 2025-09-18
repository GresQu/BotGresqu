
setDefaultTab("HP")


local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
BuffLabel1= UI.Label("-- [[ Buff Basic ]] --")
BuffLabel1:setColor("green")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

local showFirstBuff = false
local showSecondBuff = false
local showSpeedUp = false

local lastBuffSpell = 0
local lastBuffSpell2 = 0

UI.Button("First Buff Show/Hide", function(widget)
  showFirstBuff = not showFirstBuff
  if showFirstBuff then
    firstBuffLabel:show()
    firstBuffTextEdit:show()
    firstBuffCDLabel:show()
    firstBuffCDTextEdit:show()
  else
    firstBuffLabel:hide()
    firstBuffTextEdit:hide()
    firstBuffCDLabel:hide()
    firstBuffCDTextEdit:hide()
  end
end)

firstBuffLabel = UI.Label("Buff Name:")
firstBuffLabel:hide()
firstBuffTextEdit = UI.TextEdit(storage.autoBuffText or "Power Down", function(widget, newText)
  storage.autoBuffText = newText
end)
firstBuffTextEdit:hide()
firstBuffCDLabel = UI.Label("Buff CD in Ms (1000/1s):")
firstBuffCDLabel:hide()
firstBuffCDTextEdit = UI.TextEdit(storage.buffSpellCD or "10000", function(widget, newText)
  storage.buffSpellCD = newText
end)
firstBuffCDTextEdit:hide()

macro(100, "First Buff", function()
  if not storage.autoBuffText then storage.autoBuffText = 'Your Buff Name' end
  if not storage.buffSpellCD then storage.buffSpellCD = '10000' end

  local buffCooldown = tonumber(storage.buffSpellCD)
  if now > lastBuffSpell + buffCooldown then
    if saySpell(storage.autoBuffText, 200) then
      lastBuffSpell = now
    end
  end
end)

UI.Separator()

UI.Button("Second Buff Show/Hide", function(widget)
  showSecondBuff = not showSecondBuff
  if showSecondBuff then
    secondBuffLabel:show()
    secondBuffTextEdit:show()
    secondBuffCDLabel:show()
    secondBuffCDTextEdit:show()
  else
    secondBuffLabel:hide()
    secondBuffTextEdit:hide()
    secondBuffCDLabel:hide()
    secondBuffCDTextEdit:hide()
  end
end)

secondBuffLabel = UI.Label("Buff Name:")
secondBuffLabel:hide()
secondBuffTextEdit = UI.TextEdit(storage.autoBuffText2 or "Power Down", function(widget, newText)
  storage.autoBuffText2 = newText
end)
secondBuffTextEdit:hide()
secondBuffCDLabel = UI.Label("Buff CD in Ms (1000/1s):")
secondBuffCDLabel:hide()
secondBuffCDTextEdit = UI.TextEdit(storage.buffSpellCD2 or "10000", function(widget, newText)
  storage.buffSpellCD2 = newText
end)
secondBuffCDTextEdit:hide()

macro(100, "Second Buff", function()
  if not storage.autoBuffText2 then storage.autoBuffText2 = 'Your Buff Name' end
  if not storage.buffSpellCD2 then storage.buffSpellCD2 = '10000' end

  local buffCooldown2 = tonumber(storage.buffSpellCD2)
  if now > lastBuffSpell2 + buffCooldown2 then
    if saySpell(storage.autoBuffText2, 200) then
      lastBuffSpell2 = now
    end
  end
end)
