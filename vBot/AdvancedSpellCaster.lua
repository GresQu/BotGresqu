local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- vBot/AdvancedSpellCaster.lua
local mod = { name = "AdvancedSpellCaster", version = "1.0.0", author = "GresQu" }

-- UI Elements
local window = nil
local spellNameInput = nil
local spellDelayInput = nil
local addSpellButton = nil
local spellListPanel = nil
local minMonstersAoeInput = nil
local aoeRangeInput = nil
local toggleMacroButton = nil
local moveSpellUpButton = nil
local moveSpellDownButton = nil
local controlPanel = nil
local spellCasterMacro = nil
local onScreenIcon = nil
local notComboSwitch = nil
local selectedSpellIndex = nil -- To store the index of the selected spell in the list

-- Storage initialization
storage.advancedSpells = storage.advancedSpells or {}

-- Helper function to calculate distance between two position tables {x,y,z}
local function calculateDistanceBetween(pos1, pos2)
  if not pos1 or not pos2
     or type(pos1.x) ~= "number" or type(pos1.y) ~= "number" or type(pos1.z) ~= "number"
     or type(pos2.x) ~= "number" or type(pos2.y) ~= "number" or type(pos2.z) ~= "number" then
    return math.huge -- Return a very large number if positions are invalid
  end
  local dx = pos1.x - pos2.x
  local dy = pos1.y - pos2.y
  local dz = pos1.z - pos2.z
  return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Funkcja czasu - używamy os.clock() dla precyzji, cooldown w ms przeliczany na sekundy
local function now()
  return os.clock() or 0
end

function mod:addSpell()
  local name = spellNameInput:getText()
  local delayStr = spellDelayInput:getText()
  if name == "" or delayStr == "" then return end
  local delay = tonumber(delayStr)
  if not delay or delay < 10 then return end -- minimalnie 10 ms
  table.insert(storage.advancedSpells.spellList, {
    name = name,
    delay = delay,   -- delay w ms
    pve = false,
    pvp = false,
    aoe = false,
    aoeSafe = false,
    lastCast = 0
  })
  spellNameInput:setText("")
  spellDelayInput:setText("")
  self:renderSpellList()
end

function mod:renderSpellList()
  if not spellListPanel or not window then return end
  spellListPanel:destroyChildren()
  if #storage.advancedSpells.spellList == 0 then return end
  for i, spellData in ipairs(storage.advancedSpells.spellList) do
    local spellEntryWidget = UI.createWidget("SpellEntryWidget", spellListPanel)
    if not spellEntryWidget then goto continue_loop end
    spellEntryWidget.onClick = function(widget)
      selectedSpellIndex = i
      mod:renderSpellList()
    end
    if selectedSpellIndex == i then
      spellEntryWidget:setBackgroundColor(nil)
    else
      spellEntryWidget:setBackgroundColor('#555555AA')
    end
    local nameLabel = spellEntryWidget:getChildById('spellNameLabel')
    local pveSwitch = spellEntryWidget:getChildById('pveSwitch')
    local pvpSwitch = spellEntryWidget:getChildById('pvpSwitch')
    local aoeSwitch = spellEntryWidget:getChildById('aoeSwitch')
    local aoeSafeSwitch = spellEntryWidget:getChildById('aoeSafeSwitch')
    local removeButton = spellEntryWidget:getChildById('removeButton')
    if nameLabel then
      nameLabel:setText(string.format("%s (%dms)", spellData.name, spellData.delay))
    end
    if pveSwitch then
      pveSwitch:setOn(spellData.pve)
      pveSwitch.onClick = function(widget)
        local newValue = not spellData.pve
        spellData.pve = newValue
        widget:setOn(newValue)
      end
    end
    if pvpSwitch then
      pvpSwitch:setOn(spellData.pvp)
      pvpSwitch.onClick = function(widget)
        local newValue = not spellData.pvp
        spellData.pvp = newValue
        widget:setOn(newValue)
      end
    end
    if aoeSwitch then
      aoeSwitch:setOn(spellData.aoe)
      aoeSwitch.onClick = function(widget)
        local newValue = not spellData.aoe
        spellData.aoe = newValue
        widget:setOn(newValue)
      end
    end
    if aoeSafeSwitch then
      aoeSafeSwitch:setOn(spellData.aoeSafe)
      aoeSafeSwitch.onClick = function(widget)
        local newValue = not spellData.aoeSafe
        spellData.aoeSafe = newValue
        widget:setOn(newValue)
      end
    end
    if removeButton then
      removeButton.onClick = function()
        table.remove(storage.advancedSpells.spellList, i)
        mod:renderSpellList()
      end
    end
    ::continue_loop::
  end
end

function mod:getPlayersInRange(range, playerPos, onScreenSpectators)
  if not playerPos or type(playerPos.x) ~= "number" then return {} end
  if not onScreenSpectators or type(onScreenSpectators) ~= "table" then return {} end
  local players = {}
  for i = 1, #onScreenSpectators do
    local spec = onScreenSpectators[i]
    if spec and spec:isPlayer() and spec ~= player then
      local specPos = spec:getPosition()
      if specPos and type(specPos.x) == "number" and type(specPos.y) == "number" and type(specPos.z) == "number" then
        local dist = calculateDistanceBetween(playerPos, specPos)
        if dist <= range then
          table.insert(players, spec)
        end
      end
    end
  end
  return players
end

function mod:getMonsterCountInRange(range, playerPos, onScreenSpectators)
  if not playerPos or type(playerPos.x) ~= "number" then return 0 end
  if not onScreenSpectators or type(onScreenSpectators) ~= "table" then return 0 end
  local count = 0
  for _, creature in ipairs(onScreenSpectators) do
    if creature:isMonster() and not creature:isPlayer() then
      local monsterPos = creature:getPosition()
      if monsterPos and type(monsterPos.x) == "number" then
        if calculateDistanceBetween(playerPos, monsterPos) <= range then
          count = count + 1
        end
      end
    end
  end
  return count
end

function mod:executeSpellLogic()
  if not storage.advancedSpells.macroEnabled then return end

  -- zakładam, że `player` istnieje globalnie jak w Twoim kodzie
  if not player then
    if g_game and g_game.getLocalPlayer then
      player = g_game.getLocalPlayer()
    else
      return
    end
  end

  local playerPos = player:getPosition()
  if not playerPos or type(playerPos.x) ~= "number"
     or type(playerPos.y) ~= "number" or type(playerPos.z) ~= "number" then
    return
  end

  local onScreenSpectators = g_map.getSpectators(playerPos, false) or {}
  local currentTarget = g_game.getAttackingCreature and g_game.getAttackingCreature()
  local currentTime = now()  -- w sekundach z ułamkami
  local playersNearby = #self:getPlayersInRange(7, playerPos, onScreenSpectators) > 0
  local isPlayerTargeted = currentTarget and currentTarget:isPlayer()

  -- PRIORYTET #1: PvP jeśli target jest graczem
  if isPlayerTargeted then
    for i, spell in ipairs(storage.advancedSpells.spellList) do
      local last = tonumber(spell.lastCast) or 0
      local delay = (tonumber(spell.delay) or 0) / 1000  -- delay ms -> sekundy
      if currentTime >= last + delay and spell.pvp then
        say(spell.name)
        spell.lastCast = currentTime
        if storage.advancedSpells.notComboEnabled then
          return
        end
      end
    end
    return
  end

  -- PRIORYTET #2: AoE first
  local minMonsters = tonumber(storage.advancedSpells.minMonstersAoe) or 3
  local currentAoeRange = tonumber(storage.advancedSpells.aoeRange) or 5
  for i, spell in ipairs(storage.advancedSpells.spellList) do
    if spell.aoe then
      local last = tonumber(spell.lastCast) or 0
      local delay = (tonumber(spell.delay) or 0) / 1000
      if currentTime >= last + delay then
        if spell.aoeSafe and playersNearby then
          -- pomijamy jeśli safe i gracze w pobliżu
        else
          local monsterCount = self:getMonsterCountInRange(currentAoeRange, playerPos, onScreenSpectators)
          if monsterCount >= minMonsters then
            say(spell.name)
            spell.lastCast = currentTime
            return -- zakończ AoE
          end
        end
      end
    end
  end

  -- PRIORYTET #3: PvE
  if currentTarget and currentTarget:isMonster() then
    for i, spell in ipairs(storage.advancedSpells.spellList) do
      if not spell.aoe and spell.pve then
        local last = tonumber(spell.lastCast) or 0
        local delay = (tonumber(spell.delay) or 0) / 1000
        if currentTime >= last + delay then
          say(spell.name)
          spell.lastCast = currentTime
          if storage.advancedSpells.notComboEnabled then
            return
          end
        end
      end
    end
  end
end

function mod:updateToggleButtonText()
  if toggleMacroButton then
    if storage.advancedSpells.macroEnabled then
      toggleMacroButton:setText("Disable Spell Caster")
      if toggleMacroButton.setColor then toggleMacroButton:setColor("#90EE90") end
    else
      toggleMacroButton:setText("Enable Spell Caster")
      if toggleMacroButton.setColor then toggleMacroButton:setColor("#FF6347") end
    end
  end
end

function mod:updateIconState()
  if onScreenIcon then
    if storage.advancedSpells.macroEnabled then
      if onScreenIcon.text and onScreenIcon.text.setColoredText then
        onScreenIcon.text:setColoredText({"AdvSpells", "green"})
      end
      if onScreenIcon.setOn then onScreenIcon:setOn() end
    else
      if onScreenIcon.text and onScreenIcon.text.setColoredText then
        onScreenIcon.text:setColoredText({"AdvSpells", "white"})
      end
      if onScreenIcon.setOff then onScreenIcon:setOff() end
    end
  end
end

function mod:toggleMacro()
  storage.advancedSpells.macroEnabled = not storage.advancedSpells.macroEnabled
  if spellCasterMacro then
    if storage.advancedSpells.macroEnabled then
      spellCasterMacro:setOn()
    else
      spellCasterMacro:setOff()
    end
  end
  mod:updateToggleButtonText()
  mod:updateIconState()
end

function mod:showWindow()
  if window then
    window:show()
    window:raise()
    window:focus()
    storage.advancedSpells.windowVisible = true
  end
end

function mod:hideWindow()
  if window then
    window:hide()
    storage.advancedSpells.windowVisible = false
  end
end

function mod:onWindowClose()
  storage.advancedSpells.windowVisible = false
end

function mod:moveSpellUp()
  if selectedSpellIndex and selectedSpellIndex > 1 then
    local spell = storage.advancedSpells.spellList[selectedSpellIndex]
    table.remove(storage.advancedSpells.spellList, selectedSpellIndex)
    table.insert(storage.advancedSpells.spellList, selectedSpellIndex - 1, spell)
    selectedSpellIndex = selectedSpellIndex - 1
    self:renderSpellList()
  end
end

function mod:moveSpellDown()
  if selectedSpellIndex and selectedSpellIndex < #storage.advancedSpells.spellList then
    local spell = storage.advancedSpells.spellList[selectedSpellIndex]
    table.remove(storage.advancedSpells.spellList, selectedSpellIndex)
    table.insert(storage.advancedSpells.spellList, selectedSpellIndex + 1, spell)
    selectedSpellIndex = selectedSpellIndex + 1
    self:renderSpellList()
  end
end

local function initialize()
  -- Ensure sub‑tables and default values are set up from storage,
  -- and sanitize spell list.
  storage.advancedSpells.spellList = storage.advancedSpells.spellList or {}
  for _, spellData in ipairs(storage.advancedSpells.spellList) do
    spellData.lastCast = 0
    spellData.pve = spellData.pve == true
    spellData.pvp = spellData.pvp == true
    spellData.aoe = spellData.aoe == true
    spellData.aoeSafe = spellData.aoeSafe == true
    spellData.delay = tonumber(spellData.delay)
    if not spellData.delay or spellData.delay < 10 then
      spellData.delay = 1000 -- Domyślnie 1000ms jeśli za małe lub niepoprawne
    end
    spellData.name = tostring(spellData.name or "Unnamed Spell")
  end
  storage.advancedSpells.minMonstersAoe = storage.advancedSpells.minMonstersAoe or "3"
  storage.advancedSpells.aoeRange = storage.advancedSpells.aoeRange or "5"
  if storage.advancedSpells.macroEnabled == nil then storage.advancedSpells.macroEnabled = true end
  if storage.advancedSpells.windowVisible == nil then storage.advancedSpells.windowVisible = false end
  if storage.advancedSpells.notComboEnabled == nil then storage.advancedSpells.notComboEnabled = false end

  window = UI.createWindow('AdvancedSpellCasterWindow', g_ui.getRootWidget())
  if not window then return end

  local mainPanel = window:recursiveGetChildById('mainPanel')
  if not mainPanel then return end
  local bottomSectionPanel = mainPanel:recursiveGetChildById('bottomSectionPanel')
  if not bottomSectionPanel then return end
  local addSpellControlsPanel = mainPanel:recursiveGetChildById('addSpellControlsPanel')
  if not addSpellControlsPanel then return end
  local spellNameInputPanel = addSpellControlsPanel:recursiveGetChildById('spellNameInputPanel')
  if not spellNameInputPanel then return end
  spellNameInput = spellNameInputPanel:recursiveGetChildById('spellNameInput')
  if not spellNameInput then return end
  local spellDelayInputPanel = addSpellControlsPanel:recursiveGetChildById('spellDelayInputPanel')
  if not spellDelayInputPanel then return end
  spellDelayInput = spellDelayInputPanel:recursiveGetChildById('spellDelayInput')
  if not spellDelayInput then return end
  addSpellButton = addSpellControlsPanel:recursiveGetChildById('addSpellButton')
  if not addSpellButton then return end
  spellListPanel = mainPanel:recursiveGetChildById('spellListPanel')
  if not spellListPanel then return end
  local aoeSettingsPanel = bottomSectionPanel:recursiveGetChildById('aoeSettingsPanel')
  if not aoeSettingsPanel then return end
  local minMonstersPanel = aoeSettingsPanel:recursiveGetChildById('minMonstersPanel')
  if not minMonstersPanel then return end
  minMonstersAoeInput = minMonstersPanel:recursiveGetChildById('minMonstersAoeInput')
  local aoeRangePanel = aoeSettingsPanel:recursiveGetChildById('aoeRangePanel')
  if not aoeRangePanel then return end
  aoeRangeInput = aoeRangePanel:recursiveGetChildById('aoeRangeInput')
  toggleMacroButton = bottomSectionPanel:recursiveGetChildById('toggleMacroButton')
  local spellOrderControlsPanel = bottomSectionPanel:recursiveGetChildById('spellOrderControlsPanel')
  if spellOrderControlsPanel then
    local buttonContainer = spellOrderControlsPanel:recursiveGetChildById('buttonContainer')
    if buttonContainer then
      moveSpellUpButton = buttonContainer:recursiveGetChildById('moveSpellUpButton')
      moveSpellDownButton = buttonContainer:recursiveGetChildById('moveSpellDownButton')
      notComboSwitch = buttonContainer:recursiveGetChildById('notComboSwitch')
    end
  end

  if not moveSpellUpButton then end
  if not moveSpellDownButton then end
  if not notComboSwitch then end

  local closeWindowButton = mainPanel:recursiveGetChildById('closeWindowButton')
  if closeWindowButton then
    closeWindowButton.onClick = function() mod:hideWindow() end
  end

  minMonstersAoeInput:setText(storage.advancedSpells.minMonstersAoe)
  aoeRangeInput:setText(storage.advancedSpells.aoeRange)

  addSpellButton.onClick = function() mod:addSpell() end
  minMonstersAoeInput.onTextChange = function(widget, newText) storage.advancedSpells.minMonstersAoe = newText end
  aoeRangeInput.onTextChange = function(widget, newText) storage.advancedSpells.aoeRange = newText end
  if toggleMacroButton then
    toggleMacroButton.onClick = function() mod:toggleMacro() end
  end
  if moveSpellUpButton then
    moveSpellUpButton.onClick = function() mod:moveSpellUp() end
  end
  if moveSpellDownButton then
    moveSpellDownButton.onClick = function() mod:moveSpellDown() end
  end
  if notComboSwitch then
    notComboSwitch:setOn(storage.advancedSpells.notComboEnabled)
    notComboSwitch.onClick = function(widget)
      storage.advancedSpells.notComboEnabled = not storage.advancedSpells.notComboEnabled
      notComboSwitch:setOn(storage.advancedSpells.notComboEnabled)
    end
  end

  mod:renderSpellList()
  mod:updateToggleButtonText()
  mod:hideWindow()

  spellCasterMacro = macro(100, function() mod:executeSpellLogic() end)
  if spellCasterMacro then
    if storage.advancedSpells.macroEnabled then
      spellCasterMacro:setOn()
    else
      spellCasterMacro:setOff()
    end
  end

  onScreenIcon = addIcon("AdvSpellsIcon", {text = "", movable = true}, function(iconWidget, isOn)
    storage.advancedSpells.macroEnabled = isOn
    if spellCasterMacro then
      if isOn then
        spellCasterMacro:setOn()
      else
        spellCasterMacro:setOff()
      end
    end
    if iconWidget then
      if isOn then
        if iconWidget.text and iconWidget.text.setColoredText then
          iconWidget.text:setColoredText({"AdvSpells", "green"})
        end
        if iconWidget.setOn then
          iconWidget:setOn()
        end
      else
        if iconWidget.text and iconWidget.text.setColoredText then
          iconWidget.text:setColoredText({"AdvSpells", "white"})
        end
        if iconWidget.setOff then
          iconWidget:setOff()
        end
      end
    end
    mod:updateToggleButtonText()
  end)

  if onScreenIcon then
    onScreenIcon:setSize({height = 30, width = 70})
    mod:updateIconState()
  end

  controlPanel = setupUI([[ Panel id: advancedSpellCasterControlPanel height: 25 margin-top: 2 Button id: openAdvSpellWindowButton text: Adv.Spells Setup anchors.top: parent.top anchors.left: parent.left anchors.right: parent.right height: 20 margin-top: 2 color: orange ]])

  if controlPanel and controlPanel:getChildById('openAdvSpellWindowButton') then
    controlPanel:getChildById('openAdvSpellWindowButton').onClick = function()
      if window:isVisible() then
        mod:hideWindow()
      else
        mod:showWindow()
      end
    end
  end

  if not modules then modules = {} end
  if not modules.vBot then modules.vBot = {} end
  modules.vBot.AdvancedSpellCaster = mod
end

initialize()
