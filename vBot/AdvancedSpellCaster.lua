local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
-- vBot/AdvancedSpellCaster.lua
local mod = {
    name = "AdvancedSpellCaster",
    version = "1.3.2", -- Updated version
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
local controlPanel = nil
local spellCasterMacro = nil
local onScreenIcon = nil

local selectedSpellIndex = nil
local macroCooldownUntil = 0

-- Storage initialization
storage.advancedSpells = storage.advancedSpells or {}
storage.advancedSpells.spellList = storage.advancedSpells.spellList or {}

-- Helper function to calculate distance
local function calculateDistanceBetween(pos1, pos2)
    if not pos1 or not pos2 or type(pos1.x) ~= "number" or type(pos1.y) ~= "number" or type(pos1.z) ~= "number" or type(pos2.x) ~= "number" or type(pos2.y) ~= "number" or type(pos2.z) ~= "number" then
        return math.huge
    end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function mod:addSpell()
    local name = spellNameInput:getText()
    local delayStr = spellDelayInput:getText()
    if name == "" or delayStr == "" then return end
    local delay = tonumber(delayStr)
    if not delay or delay < 10 then return end

    table.insert(storage.advancedSpells.spellList, {
        name = name,
        delay = delay,
        pve = false,
        pvp = false,
        aoe = false,
        aoeSafe = false,
        onTargetOnly = false,
        allowCombo = false,
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
        local onTargetSwitch = spellEntryWidget:getChildById('onTargetSwitch')
        local comboSwitch = spellEntryWidget:getChildById('comboSwitch')
        local removeButton = spellEntryWidget:getChildById('removeButton')

        if nameLabel then nameLabel:setText(string.format("%s (%dms)", spellData.name, spellData.delay)) end

        if pveSwitch then
            pveSwitch:setOn(spellData.pve)
            pveSwitch.onClick = function(widget) spellData.pve = not spellData.pve; widget:setOn(spellData.pve) end
        end
        if pvpSwitch then
            pvpSwitch:setOn(spellData.pvp)
            pvpSwitch.onClick = function(widget) spellData.pvp = not spellData.pvp; widget:setOn(spellData.pvp) end
        end
        if aoeSwitch then
            aoeSwitch:setOn(spellData.aoe)
            aoeSwitch.onClick = function(widget) spellData.aoe = not spellData.aoe; widget:setOn(spellData.aoe) end
        end
        if aoeSafeSwitch then
            aoeSafeSwitch:setOn(spellData.aoeSafe)
            aoeSafeSwitch.onClick = function(widget) spellData.aoeSafe = not spellData.aoeSafe; widget:setOn(spellData.aoeSafe) end
        end
        if onTargetSwitch then
            onTargetSwitch:setOn(spellData.onTargetOnly)
            onTargetSwitch.onClick = function(widget) spellData.onTargetOnly = not spellData.onTargetOnly; widget:setOn(spellData.onTargetOnly) end
        end
        if comboSwitch then
            comboSwitch:setOn(spellData.allowCombo)
            comboSwitch.onClick = function(widget) spellData.allowCombo = not spellData.allowCombo; widget:setOn(spellData.allowCombo) end
        end
        if removeButton then
            removeButton.onClick = function() table.remove(storage.advancedSpells.spellList, i); mod:renderSpellList() end
        end

        ::continue_loop::
    end
end

function mod:getPlayersInRange(range, playerPos, onScreenSpectators)
    if not playerPos or type(playerPos.x) ~= "number" then return {} end
    if not onScreenSpectators or type(onScreenSpectators) ~= "table" then return {} end
    local players = {}
    for _, spec in ipairs(onScreenSpectators) do
        if spec and spec:isPlayer() and spec ~= player then
            local specPos = spec:getPosition()
            if specPos and calculateDistanceBetween(playerPos, specPos) <= range then
                table.insert(players, spec)
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
        if creature:isMonster() then
            local monsterPos = creature:getPosition()
            if monsterPos and calculateDistanceBetween(playerPos, monsterPos) <= range then
                count = count + 1
            end
        end
    end
    return count
end

function mod:executeSpellLogic()
    if not storage.advancedSpells.macroEnabled then return end

    local currentTime = now
    if currentTime < macroCooldownUntil then
        return
    end

    local playerPos = player:getPosition()
    if not playerPos then return end

    local currentTarget = g_game.getAttackingCreature()
    local onScreenSpectators = g_map.getSpectators(playerPos, false) or {}

    local function processSpellCategory(spellFilter)
        local comboHasStarted = false
        local spellCastedInThisTick = false

        for i, spell in ipairs(storage.advancedSpells.spellList) do
            if spellFilter(spell) and currentTime >= (spell.lastCast or 0) + spell.delay and not (spell.onTargetOnly and not currentTarget) then
                if not comboHasStarted then
                    -- This is the first valid spell we've found in this cycle.
                    say(spell.name)
                    spell.lastCast = currentTime
                    spellCastedInThisTick = true

                    if spell.allowCombo then
                        -- The first spell allows combo, so we start the chain.
                        comboHasStarted = true
                    else
                        -- The first spell does NOT allow combo. Set global CD and stop all processing.
                        macroCooldownUntil = currentTime + spell.delay
                        return true -- A spell was cast, and it breaks any potential chain.
                    end
                else
                    -- A combo is already in progress from a previous spell.
                    if spell.allowCombo then
                        -- This spell continues the combo. Cast it.
                        say(spell.name)
                        spell.lastCast = currentTime
                    else
                        -- This spell BREAKS the combo chain. Set global CD and stop all processing.
                        macroCooldownUntil = currentTime + spell.delay
                        return true -- A spell was cast, so we signal success and exit.
                    end
                end
            end
        end
        return spellCastedInThisTick
    end

    -- Priority #1: PvP
    if currentTarget and currentTarget:isPlayer() then
        if processSpellCategory(function(spell) return spell.pvp end) then
            return -- Stop processing other categories if a spell was cast
        end
    end

    -- Priority #2: AoE
    local minMonsters = tonumber(storage.advancedSpells.minMonstersAoe) or 3
    local aoeRange = tonumber(storage.advancedSpells.aoeRange) or 5
    local monsterCount = self:getMonsterCountInRange(aoeRange, playerPos, onScreenSpectators)
    local playersNearby = #self:getPlayersInRange(7, playerPos, onScreenSpectators) > 0

    if monsterCount >= minMonsters then
        if processSpellCategory(function(spell) return spell.aoe and not (spell.aoeSafe and playersNearby) end) then
            return -- Stop processing other categories if a spell was cast
        end
    end

    -- Priority #3: PvE
    if currentTarget and currentTarget:isMonster() then
        if processSpellCategory(function(spell) return spell.pve end) then
            return -- Stop processing other categories if a spell was cast
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
            if onScreenIcon.setOn then
                onScreenIcon:setOn()
            end
        else
            if onScreenIcon.text and onScreenIcon.text.setColoredText then
                onScreenIcon.text:setColoredText({"AdvSpells", "white"})
            end
            if onScreenIcon.setOff then
                onScreenIcon:setOff()
            end
        end
    end
end

function mod:toggleMacro()
    storage.advancedSpells.macroEnabled = not storage.advancedSpells.macroEnabled
    if spellCasterMacro then
        if storage.advancedSpells.macroEnabled then spellCasterMacro:setOn() else spellCasterMacro:setOff() end
    end
    self:updateToggleButtonText()
    self:updateIconState()
end

function mod:showWindow()
    if window then window:show(); window:raise(); window:focus(); storage.advancedSpells.windowVisible = true end
end
function mod:hideWindow()
    if window then window:hide(); storage.advancedSpells.windowVisible = false end
end
function mod:onWindowClose()
    storage.advancedSpells.windowVisible = false
end

function mod:moveSpellUp()
    if selectedSpellIndex and selectedSpellIndex > 1 then
        local spells = storage.advancedSpells.spellList
        spells[selectedSpellIndex], spells[selectedSpellIndex - 1] = spells[selectedSpellIndex - 1], spells[selectedSpellIndex]
        selectedSpellIndex = selectedSpellIndex - 1
        self:renderSpellList()
    end
end

function mod:moveSpellDown()
    if selectedSpellIndex and selectedSpellIndex < #storage.advancedSpells.spellList then
        local spells = storage.advancedSpells.spellList
        spells[selectedSpellIndex], spells[selectedSpellIndex + 1] = spells[selectedSpellIndex + 1], spells[selectedSpellIndex]
        selectedSpellIndex = selectedSpellIndex + 1
        self:renderSpellList()
    end
end

function mod:initialize()
    storage.advancedSpells.spellList = storage.advancedSpells.spellList or {}

    for _, spellData in ipairs(storage.advancedSpells.spellList) do
        spellData.lastCast = 0
        spellData.pve = spellData.pve == true
        spellData.pvp = spellData.pvp == true
        spellData.aoe = spellData.aoe == true
        spellData.aoeSafe = spellData.aoeSafe == true
        spellData.onTargetOnly = spellData.onTargetOnly == true
        spellData.allowCombo = spellData.allowCombo == true
        spellData.delay = tonumber(spellData.delay) or 1000
        spellData.name = tostring(spellData.name or "Unnamed")
    end

    storage.advancedSpells.minMonstersAoe = storage.advancedSpells.minMonstersAoe or "3"
    storage.advancedSpells.aoeRange = storage.advancedSpells.aoeRange or "5"
    if storage.advancedSpells.macroEnabled == nil then storage.advancedSpells.macroEnabled = true end
    if storage.advancedSpells.windowVisible == nil then storage.advancedSpells.windowVisible = false end

    window = UI.createWindow('AdvancedSpellCasterWindow', g_ui.getRootWidget())
    if not window then return end

    mainPanel = window:recursiveGetChildById('mainPanel')
    spellNameInput = mainPanel:recursiveGetChildById('spellNameInput')
    spellDelayInput = mainPanel:recursiveGetChildById('spellDelayInput')
    addSpellButton = mainPanel:recursiveGetChildById('addSpellButton')
    spellListPanel = mainPanel:recursiveGetChildById('spellListPanel')
    minMonstersAoeInput = mainPanel:recursiveGetChildById('minMonstersAoeInput')
    aoeRangeInput = mainPanel:recursiveGetChildById('aoeRangeInput')
    toggleMacroButton = mainPanel:recursiveGetChildById('toggleMacroButton')
    moveSpellUpButton = mainPanel:recursiveGetChildById('moveSpellUpButton')
    moveSpellDownButton = mainPanel:recursiveGetChildById('moveSpellDownButton')
    closeWindowButton = mainPanel:recursiveGetChildById('closeWindowButton')

    minMonstersAoeInput:setText(storage.advancedSpells.minMonstersAoe)
    aoeRangeInput:setText(storage.advancedSpells.aoeRange)

    addSpellButton.onClick = function() mod:addSpell() end
    minMonstersAoeInput.onTextChange = function(_, newText) storage.advancedSpells.minMonstersAoe = newText end
    aoeRangeInput.onTextChange = function(_, newText) storage.advancedSpells.aoeRange = newText end
    if toggleMacroButton then toggleMacroButton.onClick = function() mod:toggleMacro() end end
    if moveSpellUpButton then moveSpellUpButton.onClick = function() mod:moveSpellUp() end end
    if moveSpellDownButton then moveSpellDownButton.onClick = function() mod:moveSpellDown() end end
    if closeWindowButton then closeWindowButton.onClick = function() mod:hideWindow() end end

    mod:renderSpellList()
    mod:updateToggleButtonText()
    if not storage.advancedSpells.windowVisible then mod:hideWindow() end

    spellCasterMacro = macro(100, function() mod:executeSpellLogic() end)
    if storage.advancedSpells.macroEnabled then spellCasterMacro:setOn() else spellCasterMacro:setOff() end

    onScreenIcon = addIcon("AdvSpellsIcon", {text = "", movable = true}, function(iconWidget, isOn)
        storage.advancedSpells.macroEnabled = isOn
        if spellCasterMacro then if isOn then spellCasterMacro:setOn() else spellCasterMacro:setOff() end end
        mod:updateIconState()
        mod:updateToggleButtonText()
    end)

    if onScreenIcon then
        onScreenIcon:setSize({height = 30, width = 70})
        mod:updateIconState()
    end

    controlPanel = setupUI([[
Panel
  id: advancedSpellCasterControlPanel
  height: 25
  margin-top: 2
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
    if controlPanel then
        controlPanel:getChildById('openAdvSpellWindowButton').onClick = function()
            if window:isVisible() then mod:hideWindow() else mod:showWindow() end
        end
    end

    if not modules then modules = {} end
    if not modules.vBot then modules.vBot = {} end
    modules.vBot.AdvancedSpellCaster = mod
end

function mod:cleanup()
    if spellCasterMacro then spellCasterMacro:setOff(); spellCasterMacro = nil end
    if window then window:destroy(); window = nil end
    if onScreenIcon then onScreenIcon:destroy(); onScreenIcon = nil end
    if controlPanel then controlPanel:destroy(); controlPanel = nil end
end

mod.initialize()
