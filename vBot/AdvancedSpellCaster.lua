local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- vBot/AdvancedSpellCaster.lua
local mod = {
    name = "AdvancedSpellCaster",
    version = "1.7.1-Stable", -- Logika v1.7 + Stare UI
    author = "GresQu"
}

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
local closeWindowButton = nil
local controlPanel = nil
local spellCasterMacro = nil
local onScreenIcon = nil
local mainPanel = nil

local selectedSpellIndex = nil
local macroCooldownUntil = 0

-- Tryby i stan
local MODE_COMBO = "combo"
local MODE_NONCOMBO = "noncombo"
local lastCastMode = nil
local lastCastAt = 0
local lastCastDelayMs = 0

storage.advancedSpells = storage.advancedSpells or {}
storage.advancedSpells.spellList = storage.advancedSpells.spellList or {}

-- Funkcje pomocnicze
local function chebyshevDistance2D(pos1, pos2)
    if not pos1 or not pos2 or pos1.z ~= pos2.z then return math.huge end
    local dx = math.abs(pos1.x - pos2.x)
    local dy = math.abs(pos1.y - pos2.y)
    return math.max(dx, dy)
end

local function getSpellMode(spell)
    return spell.allowCombo and MODE_COMBO or MODE_NONCOMBO
end

local function canCastMode(targetMode, tnow)
    if lastCastMode and lastCastMode ~= targetMode then
        local gate = tonumber(lastCastDelayMs) or 0
        if tnow < (lastCastAt + gate) then return false end
    end
    return true
end

function mod:getMonsterCountInRange(range, playerPos, onScreenSpectators)
    if not playerPos then return 0 end
    local count = 0
    for _, creature in ipairs(onScreenSpectators) do
        if creature:isMonster() and creature:getId() ~= player:getId() then
            local mPos = creature:getPosition()
            if mPos and chebyshevDistance2D(playerPos, mPos) <= range then
                count = count + 1
            end
        end
    end
    return count
end

local function hasNonFriendOnScreen(spectators)
    if not spectators then return false end
    for _, spec in ipairs(spectators) do
        if spec:isPlayer() and spec:getName() ~= player:getName() then
            if not isFriend or not isFriend(spec) then return true end
        end
    end
    return false
end

-- LOGIKA GŁÓWNA (Poprawiona v1.7)
function mod:executeSpellLogic()
    if not storage.advancedSpells.macroEnabled then return end
    
    local currentTime = now
    if currentTime < macroCooldownUntil then return end

    local playerPos = player:getPosition()
    if not playerPos then return end
    
    local currentTarget = g_game.getAttackingCreature()
    local onScreenSpectators = g_map.getSpectators(playerPos, false) or {}
    local nonFriendOnScreen = hasNonFriendOnScreen(onScreenSpectators)

    local minMonsters = tonumber(storage.advancedSpells.minMonstersAoe) or 2
    local aoeRange = tonumber(storage.advancedSpells.aoeRange) or 3
    local monsterCount = mod:getMonsterCountInRange(aoeRange, playerPos, onScreenSpectators)

    -- Decyzja o trybie AoE
    local validAoECandidateExists = false
    if monsterCount >= minMonsters then
        for _, s in ipairs(storage.advancedSpells.spellList) do
            if s.aoe then
                local conditionsMet = true
                if s.onTargetOnly and not currentTarget then conditionsMet = false end
                if s.aoeSafe and nonFriendOnScreen then conditionsMet = false end
                if conditionsMet then
                    validAoECandidateExists = true
                    break
                end
            end
        end
    end

    local forceAoEMode = (monsterCount >= minMonsters) and validAoECandidateExists

    local function processSpellCategory(spellFilter)
        local comboHasStarted = false
        local casted = false
        for _, spell in ipairs(storage.advancedSpells.spellList) do
            local mode = getSpellMode(spell)
            if not canCastMode(mode, currentTime) then goto continue_loop end

            if spellFilter(spell) 
               and currentTime >= (spell.lastCast or 0) + spell.delay
               and not (spell.onTargetOnly and not currentTarget) then

                if not comboHasStarted then
                    say(spell.name)
                    spell.lastCast = currentTime
                    lastCastMode = mode
                    lastCastAt = currentTime
                    lastCastDelayMs = spell.delay
                    casted = true
                    if spell.allowCombo then comboHasStarted = true else return true end
                else
                    if spell.allowCombo then
                        say(spell.name)
                        spell.lastCast = currentTime
                        lastCastMode = mode
                        lastCastAt = currentTime
                        lastCastDelayMs = spell.delay
                    end
                end
            end
            ::continue_loop::
        end
        return casted
    end

    -- 1. PVP
    if currentTarget and currentTarget:isPlayer() then
        if processSpellCategory(function(s) return s.pvp end) then return end
    end

    -- 2. AOE
    if forceAoEMode then
        local aoeFilter = function(s)
            return s.aoe 
               and not (s.aoeSafe and nonFriendOnScreen)
               and (not s.onTargetOnly or currentTarget)
        end
        processSpellCategory(aoeFilter)
        return 
    end

    -- 3. PVE TARGET
    local pveFilter = function(s)
        return s.pve 
           and not s.aoe
           and (not s.onTargetOnly or currentTarget)
    end
    processSpellCategory(pveFilter)
end

-- UI FUNCTIONS
function mod:addSpell()
    local name = spellNameInput:getText()
    local delayStr = spellDelayInput:getText()
    if name == "" or delayStr == "" then return end
    local delay = tonumber(delayStr) or 1000
    table.insert(storage.advancedSpells.spellList, {
        name = name, delay = delay,
        pve = false, pvp = false, aoe = false, aoeSafe = false,
        onTargetOnly = false, allowCombo = false, lastCast = 0
    })
    mod:renderSpellList()
end

function mod:renderSpellList()
    if not spellListPanel then return end
    spellListPanel:destroyChildren()
    for i, spell in ipairs(storage.advancedSpells.spellList) do
        local w = UI.createWidget("SpellEntryWidget", spellListPanel)
        if not w then break end
        w.onClick = function() selectedSpellIndex = i; mod:renderSpellList() end
        w:setBackgroundColor(selectedSpellIndex == i and nil or '#555555AA')
        w:getChildById('spellNameLabel'):setText(spell.name.." ("..spell.delay.."ms)")
        
        local function bind(id, f) 
            local el = w:getChildById(id)
            if el then el:setOn(spell[f]); el.onClick = function(x) spell[f]=not spell[f]; x:setOn(spell[f]) end end
        end
        bind('pveSwitch', 'pve')
        bind('pvpSwitch', 'pvp')
        bind('aoeSwitch', 'aoe')
        bind('aoeSafeSwitch', 'aoeSafe')
        bind('onTargetSwitch', 'onTargetOnly')
        bind('comboSwitch', 'allowCombo')

        w:getChildById('removeButton').onClick = function()
            table.remove(storage.advancedSpells.spellList, i)
            mod:renderSpellList()
        end
    end
end

function mod:moveSpellUp()
    if not selectedSpellIndex or selectedSpellIndex <= 1 then return end
    local t = storage.advancedSpells.spellList
    t[selectedSpellIndex], t[selectedSpellIndex-1] = t[selectedSpellIndex-1], t[selectedSpellIndex]
    selectedSpellIndex = selectedSpellIndex - 1
    mod:renderSpellList()
end

function mod:moveSpellDown()
    if not selectedSpellIndex or selectedSpellIndex >= #storage.advancedSpells.spellList then return end
    local t = storage.advancedSpells.spellList
    t[selectedSpellIndex], t[selectedSpellIndex+1] = t[selectedSpellIndex+1], t[selectedSpellIndex]
    selectedSpellIndex = selectedSpellIndex + 1
    mod:renderSpellList()
end

function mod:showWindow() if window then window:show(); window:raise(); window:focus() end end
function mod:hideWindow() if window then window:hide() end end
function mod:toggleMacro()
    storage.advancedSpells.macroEnabled = not storage.advancedSpells.macroEnabled
    if spellCasterMacro then 
        if storage.advancedSpells.macroEnabled then spellCasterMacro:setOn() else spellCasterMacro:setOff() end
    end
    mod:updateToggleButtonText()
    mod:updateIconState()
end
function mod:updateToggleButtonText()
    if not toggleMacroButton then return end
    toggleMacroButton:setText(storage.advancedSpells.macroEnabled and "Disable Spell Caster" or "Enable Spell Caster")
    toggleMacroButton:setColor(storage.advancedSpells.macroEnabled and "#90EE90" or "#FF6347")
end
function mod:updateIconState()
    if not onScreenIcon then return end
    onScreenIcon.text:setColoredText({"AdvSpells", storage.advancedSpells.macroEnabled and "green" or "white"})
end

function mod:initialize()
    if window then window:destroy() end
    if onScreenIcon then onScreenIcon:destroy() end
    if controlPanel then controlPanel:destroy() end
    if spellCasterMacro then spellCasterMacro:setOff() end

    storage.advancedSpells.spellList = storage.advancedSpells.spellList or {}
    storage.advancedSpells.minMonstersAoe = storage.advancedSpells.minMonstersAoe or "3"
    storage.advancedSpells.aoeRange = storage.advancedSpells.aoeRange or "5"
    if storage.advancedSpells.macroEnabled == nil then storage.advancedSpells.macroEnabled = true end

    window = UI.createWindow('AdvancedSpellCasterWindow', g_ui.getRootWidget())
    mainPanel = window:recursiveGetChildById('mainPanel')
    
    spellNameInput = mainPanel:recursiveGetChildById('spellNameInput')
    spellDelayInput = mainPanel:recursiveGetChildById('spellDelayInput')
    spellListPanel = mainPanel:recursiveGetChildById('spellListPanel')
    minMonstersAoeInput = mainPanel:recursiveGetChildById('minMonstersAoeInput')
    aoeRangeInput = mainPanel:recursiveGetChildById('aoeRangeInput')
    toggleMacroButton = mainPanel:recursiveGetChildById('toggleMacroButton')
    
    mainPanel:recursiveGetChildById('addSpellButton').onClick = function() mod:addSpell() end
    mainPanel:recursiveGetChildById('moveSpellUpButton').onClick = function() mod:moveSpellUp() end
    mainPanel:recursiveGetChildById('moveSpellDownButton').onClick = function() mod:moveSpellDown() end
    mainPanel:recursiveGetChildById('closeWindowButton').onClick = function() mod:hideWindow() end
    
    minMonstersAoeInput:setText(storage.advancedSpells.minMonstersAoe)
    minMonstersAoeInput.onTextChange = function(_, txt) storage.advancedSpells.minMonstersAoe = txt end
    aoeRangeInput:setText(storage.advancedSpells.aoeRange)
    aoeRangeInput.onTextChange = function(_, txt) storage.advancedSpells.aoeRange = txt end
    toggleMacroButton.onClick = function() mod:toggleMacro() end

    mod:renderSpellList()
    mod:updateToggleButtonText()
    mod:hideWindow() -- Ukryj na starcie
    
    -- STARY, PROSTY PANEL (BEZ DEBUGA, BEZ BLĘDÓW)
    controlPanel = setupUI([[
Panel
  id: advancedSpellCasterControlPanel
  height: 25
  margin-top: 2
  layout: anchor

  Button
    id: openAdvSpellWindowButton
    text: Adv. Spells Setup
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    margin-top: 2
    color: orange
  ]])
  
    controlPanel:getChildById('openAdvSpellWindowButton').onClick = function()
        if window:isVisible() then mod:hideWindow() else mod:showWindow() end
    end

    spellCasterMacro = macro(100, function() mod:executeSpellLogic() end)
    if storage.advancedSpells.macroEnabled then spellCasterMacro:setOn() end

    onScreenIcon = addIcon("AdvSpellsIcon", {text = "", movable = true}, function(_, isOn)
        storage.advancedSpells.macroEnabled = isOn
        if isOn then spellCasterMacro:setOn() else spellCasterMacro:setOff() end
        mod:updateIconState()
        mod:updateToggleButtonText()
    end)
    onScreenIcon:setSize({height = 30, width = 70})
    mod:updateIconState()

    modules.vBot = modules.vBot or {}
    modules.vBot.AdvancedSpellCaster = mod
end

function mod:cleanup()
    if spellCasterMacro then spellCasterMacro:setOff() end
    if window then window:destroy() end
    if controlPanel then controlPanel:destroy() end
    if onScreenIcon then onScreenIcon:destroy() end
end

-- POPRAWIONE WYWOŁANIE (dwukropek zamiast kropki)
mod:initialize()

g_game.talk("AdvSpells v1.7.1 Loaded")
