-- Advanced Buffs Script
-- Author: GresQu
-- Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-27 11:58:17
-- Current User's Login: GresQu
local panelName = "advancedBuffs"

local mainPanel = setupUI([[
Panel
  id: mainBuffPanel
  height: 45
  width: 200
  draggable: true
  focusable: true
  moveable: true
  phantom: false
  margin-bottom: 5
  margin-right: 5
  background-color: #00000066

  UIWidget
    id: dragHandler
    height: 15
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    background-color: #00000033
    !text: tr('Buff Timers')
    text-align: center
    phantom: false
    cursor: move

OutlineLabel < Label
  height: 12
  text-auto-resize: true
  font: verdana-11px-rounded
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.top: prev.bottom
  margin-left: 5
  text-wrap: false
  phantom: true
  $first:
    anchors.top: dragHandler.bottom
    margin-top: 3
]], g_ui.getRootWidget())  -- Zmiana na g_ui.getRootWidget()

-- Ustawianie domyślnej pozycji jeśli nie ma zapisanej
if not storage.buffTimerPosition then
    storage.buffTimerPosition = {x = 500, y = 100}  -- domyślna pozycja
end

-- Wczytywanie zapisanej pozycji
mainPanel:setPosition(storage.buffTimerPosition)

-- Dodajemy zmienną do śledzenia stanu przeciągania
local isDragging = false
local dragStart = {x = 0, y = 0}

-- Obsługa przeciągania
local dragHandler = mainPanel:getChildById('dragHandler')

dragHandler.onMousePress = function(widget, mousePos)
    isDragging = true
    dragStart = {x = mousePos.x - mainPanel:getX(), y = mousePos.y - mainPanel:getY()}
    mainPanel:raise()
    mainPanel:setBackgroundColor('#000000AA')
end

dragHandler.onMouseMove = function(widget, mousePos, mouseMoved)
    if isDragging then
        -- Obliczanie nowej pozycji
        local newX = mousePos.x - dragStart.x
        local newY = mousePos.y - dragStart.y
        
        -- Ograniczenie pozycji do granic ekranu
        local parentWidth = g_ui.getRootWidget():getWidth()
        local parentHeight = g_ui.getRootWidget():getHeight()
        local panelWidth = mainPanel:getWidth()
        local panelHeight = mainPanel:getHeight()
        
        -- Zapobieganie wyjściu poza ekran
        newX = math.max(0, math.min(newX, parentWidth - panelWidth))
        newY = math.max(0, math.min(newY, parentHeight - panelHeight))
        
        mainPanel:setPosition({x = newX, y = newY})
    end
end

dragHandler.onMouseRelease = function(widget, mousePos)
    isDragging = false
    mainPanel:setBackgroundColor('#00000066')
    -- Zapisywanie pozycji
    storage.buffTimerPosition = {x = mainPanel:getX(), y = mainPanel:getY()}
end

local buffPanel = mainPanel

setDefaultTab("HP")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
AdvancedBuffs1 = UI.Label("- ADVANCED BUFFS -")

AdvancedBuffs1:setColor("green")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- Inicjalizacja buffów
rageBuff = {
    spellName = storage.rageBuff_spellName or 'Spell_Name',
    cooldown = storage.rageBuff_cooldown or 75,
    healthBellow = storage.rageBuff_healthBellow or 0,
    manaBellow = storage.rageBuff_manaBellow or 0,
    castInPz = true,
    requireTarget = storage.rageBuff_requireTarget or false
}

powerUpBuff = {
    spellName = storage.powerUpBuff_spellName or 'Spell_Name',
    cooldown = storage.powerUpBuff_cooldown or 60,
    healthBellow = storage.powerUpBuff_healthBellow or 0,
    manaBellow = storage.powerUpBuff_manaBellow or 0,
    castInPz = true,
    requireTarget = storage.powerUpBuff_requireTarget or false
}

GodBuff = {
    spellName = storage.GodBuff_spellName or 'Spell_Name',
    cooldown = storage.GodBuff_cooldown or 75,
    healthBellow = storage.GodBuff_healthBellow or 0,
    manaBellow = storage.GodBuff_manaBellow or 0,
    castInPz = true,
    requireTarget = storage.GodBuff_requireTarget or false
}

buffCooldowns = {
    [rageBuff.spellName] = 0,
    [powerUpBuff.spellName] = 0,
    [GodBuff.spellName] = 0
}

-- Cached table of all buff objects
local allConfiguredBuffs = {rageBuff, powerUpBuff, GodBuff}
-- Map for lowercase spell name to buff object for faster lookups in onTalk
local lowercaseSpellMap = {}

-- Function to rebuild the lowercase spell map
-- This should be called whenever a spell name might change
local function rebuildLowercaseSpellMap()
    lowercaseSpellMap = {} -- Clear previous map
    for _, buff in ipairs(allConfiguredBuffs) do
        if buff and buff.spellName then
            lowercaseSpellMap[buff.spellName:lower()] = buff
        end
    end
end

rebuildLowercaseSpellMap() -- Initial build

local function createCooldownLabel(spellName, id)
    local label = UI.createWidget("OutlineLabel", buffPanel)
    label:setId(id)
    return label
end

local function updateCooldownDisplay(label, spellName)
    local remaining = (buffCooldowns[spellName] or 0) - os.time()
    if remaining < 0 or remaining > 1000 then
        label:setColoredText({'~ '..spellName..': ', 'white', 'ready', 'green'})
    else
        label:setColoredText({'~ '..spellName..': ', 'white', math.floor(remaining)..'s', 'red'})
    end
end

ui = setupUI([[
Panel
  id: advancedBuffPanel
  height: 60
  margin-top: 2

  BotSwitch
    id: firstBuffTargetMode
    text: First Buff    - IsAttacking
    anchors.top: parent.top
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2

  BotSwitch
    id: secondBuffTargetMode
    text: Second Buff - IsAttacking
    anchors.top: prev.bottom
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2

  BotSwitch
    id: thirdBuffTargetMode
    text: Third Buff   - IsAttacking
    anchors.top: prev.bottom
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
]])

ui.firstBuffTargetMode.onClick = function(widget)
    rageBuff.requireTarget = not rageBuff.requireTarget
	storage.rageBuff_requireTarget = rageBuff.requireTarget
    widget:setOn(rageBuff.requireTarget)
end

ui.secondBuffTargetMode.onClick = function(widget)
    powerUpBuff.requireTarget = not powerUpBuff.requireTarget
	storage.powerUpBuff_requireTarget = powerUpBuff.requireTarget
    widget:setOn(powerUpBuff.requireTarget)
end

ui.thirdBuffTargetMode.onClick = function(widget)
    GodBuff.requireTarget = not GodBuff.requireTarget
	storage.GodBuff_requireTarget = GodBuff.requireTarget
    widget:setOn(GodBuff.requireTarget)
end

ui.firstBuffTargetMode:setOn(rageBuff.requireTarget)
ui.secondBuffTargetMode:setOn(powerUpBuff.requireTarget)
ui.thirdBuffTargetMode:setOn(GodBuff.requireTarget)

local function createBuffSection(buff, storagePrefix, label, labelId)
    local show = false
    local UID = {}
    local macroName = label.."_Buff"
    
    -- Sekcja UI
    local sep = UI.Separator()
    sep:setHeight(4)
    sep:setBackgroundColor('#A0B0C0')
    UI.Button("Show/Hide "..label, function()
        show = not show
        for _, widget in pairs(UID) do
            widget[show and "show" or "hide"](widget)
        end
    end)

    UID.spellName = UI.Label(label.." Spell Name") UID.spellName:hide()
    UID.spellNameEdit = UI.TextEdit(buff.spellName, function(widget, newText)
        local oldName = buff.spellName
        buff.spellName = newText
        storage[storagePrefix.."_spellName"] = newText
        
        buffCooldowns[newText] = 0 -- Use the new (potentially mixed-case) name as key
        if oldName ~= newText then -- Only remove old if it's different
            buffCooldowns[oldName] = nil
        end
        rebuildLowercaseSpellMap() -- Update the map after a spell name changes
    end) UID.spellNameEdit:hide()

    UID.cooldown = UI.Label(label.." Cooldown (sec)") UID.cooldown:hide()
    UID.cooldownEdit = UI.TextEdit(tostring(buff.cooldown), function(widget, newText)
        buff.cooldown = tonumber(newText) or 0
        storage[storagePrefix.."_cooldown"] = buff.cooldown
    end) UID.cooldownEdit:hide()

    UID.healthBelow = UI.Label(label.." HP Below (%)") UID.healthBelow:hide()
    UID.healthBelowEdit = UI.TextEdit(tostring(buff.healthBellow), function(widget, newText)
        buff.healthBellow = tonumber(newText) or 0
        storage[storagePrefix.."_healthBellow"] = buff.healthBellow
		widget:setTooltip("Set 0 if you want to disable this condition")
    end) UID.healthBelowEdit:hide()

    UID.manaBelow = UI.Label(label.." Mana Below (%)") UID.manaBelow:hide()
    UID.manaBelowEdit = UI.TextEdit(tostring(buff.manaBellow), function(widget, newText)
        buff.manaBellow = tonumber(newText) or 0
        storage[storagePrefix.."_manaBellow"] = buff.manaBellow
		widget:setTooltip("Set 0 if you want to disable this condition")
    end) UID.manaBelowEdit:hide()

    table.insert(UID, UID.spellName)
    table.insert(UID, UID.spellNameEdit)
    table.insert(UID, UID.cooldown)
    table.insert(UID, UID.cooldownEdit)
    table.insert(UID, UID.healthBelow)
    table.insert(UID, UID.healthBelowEdit)
    table.insert(UID, UID.manaBelow)
    table.insert(UID, UID.manaBelowEdit)

    -- Makro (działające w tle)
    macro(200, macroName, function()
        local timeNow = os.time()
        local hpOK = (buff.healthBellow or 0) == 0 or hppercent() <= (buff.healthBellow or 100)
        local manaOK = (buff.manaBellow or 0) == 0 or manapercent() <= (buff.manaBellow or 100)
        local cooldown = buffCooldowns[buff.spellName] or 0
        
        if buff.requireTarget then
            -- BotSwitch ON - cast only when attacking
            if g_game.isAttacking() and hpOK and manaOK and timeNow >= cooldown then
                say(buff.spellName)
            end
        else
            -- BotSwitch OFF - cast without checking target
            if hpOK and manaOK and timeNow >= cooldown then
                say(buff.spellName)
            end
        end
    end)
end

-- Tworzenie labeli dla każdego buffa
local rageLabel = createCooldownLabel(rageBuff.spellName, "rage")
local powerLabel = createCooldownLabel(powerUpBuff.spellName, "power")
local godLabel = createCooldownLabel(GodBuff.spellName, "god")

-- Tworzenie sekcji dla każdego buffa
createBuffSection(rageBuff, "rageBuff", "First", "rage")
createBuffSection(powerUpBuff, "powerUpBuff", "Second", "power")
createBuffSection(GodBuff, "GodBuff", "Third", "god")

-- Aktualizacja wysokości panelu
buffPanel:setHeight(buffPanel:getChildCount() * 13)

-- Aktualizacja cooldownów
onTalk(function(name, level, mode, text, channelId, pos)
    -- Strict check: only process if the speaker is the local player
    if name ~= player:getName() then return end
    
    text = text:lower() -- Lowercase the spoken text once

    -- Use the pre-built map for O(1) average lookup
    local matchedBuff = lowercaseSpellMap[text]
    if matchedBuff then
        -- Use the original (case-sensitive) spellName for buffCooldowns keys
        buffCooldowns[matchedBuff.spellName] = os.time() + (matchedBuff.cooldown or 0)
    end
end)

macro(200, function()
    updateCooldownDisplay(buffPanel:getChildById("rage"), rageBuff.spellName)
    updateCooldownDisplay(buffPanel:getChildById("power"), powerUpBuff.spellName)
    updateCooldownDisplay(buffPanel:getChildById("god"), GodBuff.spellName)
end)