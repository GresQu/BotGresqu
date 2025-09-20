-- Corrected Item Healing Script with safe widget checks and PvE/PvP separation

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local panelName = "itemHealing"
local itemHealingWindow
local ui
local setupUI = setupUI or setup

local function deepCopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == 'table' then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

if not storage[panelName] then
    local defaultConfig = {
        hp1enabled = false, hp2enabled = false, hp3enabled = false,
        mana1enabled = false, mana2enabled = false, mana3enabled = false,
        minHp1 = 0, maxHp1 = 90,
        minHp2 = 0, maxHp2 = 90,
        minHp3 = 0, maxHp3 = 90,
        minMana1 = 0, maxMana1 = 90,
        minMana2 = 0, maxMana2 = 90,
        minMana3 = 0, maxMana3 = 90,
        hpItem1 = 0, hpItem2 = 0, hpItem3 = 0,
        manaItem1 = 0, manaItem2 = 0, manaItem3 = 0
    }
    storage[panelName] = {
        currentMode = "pve",
        pve = deepCopy(defaultConfig),
        pvp = deepCopy(defaultConfig)
    }
end

local lastUseHp1, lastUseHp2, lastUseHp3 = 0, 0, 0
local lastUseMp1, lastUseMp2, lastUseMp3 = 0, 0, 0
local PVP_COOLDOWN, PVE_COOLDOWN = 10, 20

local function getCooldown()
    return storage[panelName].currentMode == "pvp" and PVP_COOLDOWN or PVE_COOLDOWN
end

local function getActiveConfig()
    return storage[panelName][storage[panelName].currentMode]
end

local function useItemDependingOnType(itemId)
    if not itemId or itemId == 0 then return end
    local itemType = g_things.getThingType(itemId, ThingCategoryItem)
    local isMultiUse = itemType and itemType:isMultiUse() or true
    if isMultiUse then
        g_game.useInventoryItemWith(itemId, player)
    else
        g_game.useInventoryItem(itemId)
    end
end

local function findChildById(widget, id)
    if not widget then return nil end
    if widget:getId() == id then return widget end
    for _, child in ipairs(widget:getChildren()) do
        local found = findChildById(child, id)
        if found then return found end
    end
    return nil
end

local healingmacro1 = macro(300, function()
    --print("[DEBUG] Running healingmacro1")
    local cfg = getActiveConfig()
    if not cfg or not cfg.hp1enabled then 
        --print("[DEBUG] HP1 macro disabled") 
        return 
    end
    if now - lastUseHp1 < getCooldown() then 
        --print("[DEBUG] HP1 cooldown not ready") 
        return 
    end
    local hp = player:getHealthPercent()
    --print(string.format("[DEBUG] HP: %d, Range: %d - %d", hp, cfg.minHp1, cfg.maxHp1))
    if hp >= cfg.minHp1 and hp <= cfg.maxHp1 and cfg.hpItem1 ~= 0 then
        --print("[DEBUG] Using HP item", cfg.hpItem1)
        useItemDependingOnType(cfg.hpItem1)
        lastUseHp1 = now
    end
end)

local healingmacro2 = macro(300, function()
    --print("[DEBUG] Running healingmacro2")
    local cfg = getActiveConfig()
    if not cfg or not cfg.hp2enabled then --print("[DEBUG] HP2 macro disabled") return end
    if now - lastUseHp2 < getCooldown() then --print("[DEBUG] HP2 cooldown not ready") return end
    local hp = player:getHealthPercent()
    --print(string.format("[DEBUG] HP: %d, Range: %d - %d", hp, cfg.minHp2, cfg.maxHp2))
    if hp >= cfg.minHp2 and hp <= cfg.maxHp2 and cfg.hpItem2 ~= 0 then
        --print("[DEBUG] Using HP item", cfg.hpItem2)
	end
    local cfg = getActiveConfig()
    if not cfg or not cfg.hp2enabled then return end
    if now - lastUseHp2 < getCooldown() then return end
    local hp = player:getHealthPercent()
    if hp >= cfg.minHp2 and hp <= cfg.maxHp2 and cfg.hpItem2 ~= 0 then
        useItemDependingOnType(cfg.hpItem2)
        lastUseHp2 = now
    end
end)
local healingmacro3 = macro(300, function()
    --print("[DEBUG] Running healingmacro3")
    local cfg = getActiveConfig()
    if not cfg or not cfg.hp3enabled then --print("[DEBUG] HP3 macro disabled") return end
    if now - lastUseHp3 < getCooldown() then --print("[DEBUG] HP3 cooldown not ready") return end
    local hp = player:getHealthPercent()
    --print(string.format("[DEBUG] HP: %d, Range: %d - %d", hp, cfg.minHp3, cfg.maxHp3))
    if hp >= cfg.minHp3 and hp <= cfg.maxHp3 and cfg.hpItem3 ~= 0 then
        --print("[DEBUG] Using HP item", cfg.hpItem3)
	end
    local cfg = getActiveConfig()
    if not cfg or not cfg.hp3enabled then return end
    if now - lastUseHp3 < getCooldown() then return end
    local hp = player:getHealthPercent()
    if hp >= cfg.minHp3 and hp <= cfg.maxHp3 and cfg.hpItem3 ~= 0 then
        useItemDependingOnType(cfg.hpItem3)
        lastUseHp3 = now
    end
end)
local manamacro1 = macro(300, function()
    --print("[DEBUG] Running manamacro1")
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana1enabled then --print("[DEBUG] Mana1 macro disabled") return end
    if now - lastUseMp1 < getCooldown() then --print("[DEBUG] Mana1 cooldown not ready") return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    --print(string.format("[DEBUG] MP: %d, Range: %d - %d", mp, cfg.minMana1, cfg.maxMana1))
    if mp >= cfg.minMana1 and mp <= cfg.maxMana1 and cfg.manaItem1 ~= 0 then
        --print("[DEBUG] Using Mana item", cfg.manaItem1)
	end
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana1enabled then return end
    if now - lastUseMp1 < getCooldown() then return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if mp >= cfg.minMana1 and mp <= cfg.maxMana1 and cfg.manaItem1 ~= 0 then
        useItemDependingOnType(cfg.manaItem1)
        lastUseMp1 = now
    end
end)
local manamacro2 = macro(300, function()
    --print("[DEBUG] Running manamacro2")
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana2enabled then --print("[DEBUG] Mana2 macro disabled") return end
    if now - lastUseMp2 < getCooldown() then --print("[DEBUG] Mana2 cooldown not ready") return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    --print(string.format("[DEBUG] MP: %d, Range: %d - %d", mp, cfg.minMana2, cfg.maxMana2))
    if mp >= cfg.minMana2 and mp <= cfg.maxMana2 and cfg.manaItem2 ~= 0 then
        --print("[DEBUG] Using Mana item", cfg.manaItem2)
	end
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana2enabled then return end
    if now - lastUseMp2 < getCooldown() then return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if mp >= cfg.minMana2 and mp <= cfg.maxMana2 and cfg.manaItem2 ~= 0 then
        useItemDependingOnType(cfg.manaItem2)
        lastUseMp2 = now
    end
end)
local manamacro3 = macro(300, function()
    --print("[DEBUG] Running manamacro3")
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana3enabled then --print("[DEBUG] Mana3 macro disabled") return end
    if now - lastUseMp3 < getCooldown() then --print("[DEBUG] Mana3 cooldown not ready") return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    --print(string.format("[DEBUG] MP: %d, Range: %d - %d", mp, cfg.minMana3, cfg.maxMana3))
    if mp >= cfg.minMana3 and mp <= cfg.maxMana3 and cfg.manaItem3 ~= 0 then
        --print("[DEBUG] Using Mana item", cfg.manaItem3)
	end
    local cfg = getActiveConfig()
    if not cfg or not cfg.mana3enabled then return end
    if now - lastUseMp3 < getCooldown() then return end
    local mp = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if mp >= cfg.minMana3 and mp <= cfg.maxMana3 and cfg.manaItem3 ~= 0 then
        useItemDependingOnType(cfg.manaItem3)
        lastUseMp3 = now
    end
end)

local function setupSwitch(switchId, configKey, minScrollId, maxScrollId, type, itemId, macro)
    local switch = findChildById(itemHealingWindow, switchId)
    local minScroll = findChildById(itemHealingWindow, minScrollId)
    local maxScroll = findChildById(itemHealingWindow, maxScrollId)
    local itemWidget = findChildById(itemHealingWindow, itemId)

    local function getMode()
        return storage[panelName].currentMode
    end

    if itemWidget and itemWidget.setItemId then
        itemWidget:setItemId(storage[panelName][getMode()][itemId] or 0)
        itemWidget.onItemChange = function(widget)
            local mode = getMode()
            storage[panelName][mode][itemId] = widget:getItemId() or 0
            if macro and macro.setOn then
                macro.setOn(storage[panelName][mode][configKey])
            end
        end
    end

    if switch and switch.setOn then
        switch:setOn(storage[panelName][getMode()][configKey])

        local function updateSwitchText()
            if minScroll and maxScroll then
                local minVal = minScroll:getValue()
                local maxVal = maxScroll:getValue()
                switch:setText(minVal .. "% <= " .. type .. "% <= " .. maxVal .. "%")
            end
        end

        if minScroll and maxScroll then
            local minKey = type == 'HP' and 'minHp' .. switchId:sub(-1) or 'minMana' .. switchId:sub(-1)
            local maxKey = type == 'HP' and 'maxHp' .. switchId:sub(-1) or 'maxMana' .. switchId:sub(-1)

            minScroll:setValue(storage[panelName][getMode()][minKey] or 0)
            maxScroll:setValue(storage[panelName][getMode()][maxKey] or 90)
            updateSwitchText()

            minScroll.onValueChange = function(widget, value)
                local mode = getMode()
                storage[panelName][mode][minKey] = value
                updateSwitchText()
            end
            maxScroll.onValueChange = function(widget, value)
                local mode = getMode()
                storage[panelName][mode][maxKey] = value
                updateSwitchText()
            end
        end

        switch.onClick = function(widget)
            local mode = getMode()
            storage[panelName][mode][configKey] = not storage[panelName][mode][configKey]
            widget:setOn(storage[panelName][mode][configKey])
            if macro and macro.setOn then
                macro.setOn(storage[panelName][mode][configKey])
            end
        end
    end
end

local function initializeControls()
    -- HP slots
    setupSwitch('enableHp1', 'hp1enabled', 'minHp1Scroll', 'maxHp1Scroll', 'HP', 'hpItem1', healingmacro1)
    setupSwitch('enableHp2', 'hp2enabled', 'minHp2Scroll', 'maxHp2Scroll', 'HP', 'hpItem2', healingmacro2)
    setupSwitch('enableHp3', 'hp3enabled', 'minHp3Scroll', 'maxHp3Scroll', 'HP', 'hpItem3', healingmacro3)

    -- Mana slots
    setupSwitch('enableMana1', 'mana1enabled', 'minMana1Scroll', 'maxMana1Scroll', 'MP', 'manaItem1', manamacro1)
    setupSwitch('enableMana2', 'mana2enabled', 'minMana2Scroll', 'maxMana2Scroll', 'MP', 'manaItem2', manamacro2)
    setupSwitch('enableMana3', 'mana3enabled', 'minMana3Scroll', 'maxMana3Scroll', 'MP', 'manaItem3', manamacro3)
end


local function updateControls()
    if not itemHealingWindow then return end
    local currentConfig = getActiveConfig()
    if not currentConfig then return end
    for i = 1, 3 do
        local hpSwitch = findChildById(itemHealingWindow, 'enableHp' .. i)
        local manaSwitch = findChildById(itemHealingWindow, 'enableMana' .. i)
        if hpSwitch and hpSwitch.setOn then
            local minHp = currentConfig['minHp' .. i] or 0
            local maxHp = currentConfig['maxHp' .. i] or 90
            hpSwitch:setText(minHp .. "% <= HP% <= " .. maxHp .. "%")
            hpSwitch:setOn(currentConfig['hp' .. i .. 'enabled'])
        end
        if manaSwitch and manaSwitch.setOn then
            local minMana = currentConfig['minMana' .. i] or 0
            local maxMana = currentConfig['maxMana' .. i] or 90
            manaSwitch:setText(minMana .. "% <= MP% <= " .. maxMana .. "%")
            manaSwitch:setOn(currentConfig['mana' .. i .. 'enabled'])
        end
    end
end

local function switchMode(newMode)
    healingmacro1.setOn(false)
    healingmacro2.setOn(false)
    healingmacro3.setOn(false)
    manamacro1.setOn(false)
    manamacro2.setOn(false)
    manamacro3.setOn(false)
    storage[panelName].currentMode = newMode

    if itemHealingWindow and itemHealingWindow:isVisible() then
    updateControls()
        for i = 1, 3 do
            local hpItem = findChildById(itemHealingWindow, 'hpItem' .. i)
            local manaItem = findChildById(itemHealingWindow, 'manaItem' .. i)
            if hpItem and hpItem.setItemId then
                hpItem:setItemId(storage[panelName][newMode]['hpItem' .. i] or 0)
            end
            if manaItem and manaItem.setItemId then
                manaItem:setItemId(storage[panelName][newMode]['manaItem' .. i] or 0)
            end
        end
        initializeControls()
    end

    local newConfig = storage[panelName][newMode]
    healingmacro1.setOn(newConfig.hp1enabled or false)
    healingmacro2.setOn(newConfig.hp2enabled or false)
    healingmacro3.setOn(newConfig.hp3enabled or false)
    manamacro1.setOn(newConfig.mana1enabled or false)
    manamacro2.setOn(newConfig.mana2enabled or false)
    manamacro3.setOn(newConfig.mana3enabled or false)

    if ui.pvpMode and ui.pvpMode.setOn and ui.pvpMode.setText then
        ui.pvpMode:setOn(newMode == "pvp")
        ui.pvpMode:setText(newMode == "pvp" and "PvP Mode" or "PvE Mode")
    end
end

ui = setupUI([[
Panel
  id: itemHealingPanel
  height: 45
  margin-top: 2
  Button
    id: open
    text: Item Healing Setup
    anchors.top: parent.top
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
    color: yellow
  BotSwitch
    id: pvpMode
    text: PvE Mode
    anchors.top: prev.bottom
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
]])
ui:setId(panelName)
if ui.pvpMode and ui.pvpMode.setOn and ui.pvpMode.setText then
    ui.pvpMode:setOn(storage[panelName].currentMode == "pvp")
    ui.pvpMode:setText(storage[panelName].currentMode == "pvp" and "PvP Mode" or "PvE Mode")

    ui.pvpMode.onClick = function(widget)
        local currentMode = storage[panelName].currentMode
        local newMode = currentMode == "pvp" and "pve" or "pvp"
        widget:setText(newMode == "pvp" and "PvP Mode" or "PvE Mode")
        switchMode(newMode)
    end
end

local rootWidget = g_ui.getRootWidget()
if rootWidget then
    itemHealingWindow = UI.createWindow('ItemHealingWindow', rootWidget)
    itemHealingWindow:hide()
    itemHealingWindow.onVisibilityChange = function(widget, visible)
    if visible then updateControls() end
        if visible then
            initializeControls()
        end
    end
end

ui.open.onClick = function()
    if itemHealingWindow then
        itemHealingWindow:show()
        itemHealingWindow:raise()
        itemHealingWindow:focus()
    end
end

local currentConfig = getActiveConfig()
if currentConfig then
    healingmacro1.setOn(currentConfig.hp1enabled)
    healingmacro2.setOn(currentConfig.hp2enabled)
    healingmacro3.setOn(currentConfig.hp3enabled)
    manamacro1.setOn(currentConfig.mana1enabled)
    manamacro2.setOn(currentConfig.mana2enabled)
    manamacro3.setOn(currentConfig.mana3enabled)
end
