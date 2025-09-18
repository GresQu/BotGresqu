-- Wodbo Healing Script v1.5
-- Added MP and Soul support
setDefaultTab("HP")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local panelName = "wodboHealing"
local wodboHealingWindow
local ui
local setupUI = setupUI or setup

-- Stałe ID przedmiotów
local SENZU_ID = 7440       -- Senzu Bean
local RED_SENZU_ID = 7439   -- Red Senzu Bean
local ULTIMATE_POTION_ID = 266 -- Ultimate Healing Potion

-- Cooldown system
local lastUsed = {
    Senzu = 0,
    RedSenzu = 0,
    UltimatePotion = 0
}
local lastUsedGlobal = 0
local senzuCooldown = 2000    -- 2 seconds
local ultimatePotionCooldown = 1000 -- 1 second

-- Funkcja sprawdzająca czy można użyć przedmiotu
local function canUseItem(itemName)
    local currentTime = now
    local globalCD = storage[panelName].globalCooldown or 150
    local lastGlobal = currentTime - lastUsedGlobal
    
    if itemName == "Senzu" then
        return (currentTime - lastUsed.Senzu) >= senzuCooldown and lastGlobal >= globalCD
    elseif itemName == "RedSenzu" then
        return (currentTime - lastUsed.RedSenzu) >= senzuCooldown and lastGlobal >= globalCD
    elseif itemName == "UltimatePotion" then
        return (currentTime - lastUsed.UltimatePotion) >= ultimatePotionCooldown and lastGlobal >= globalCD
    end
    return false
end

-- Get current config based on mode (MOVED UP)
local function getActiveConfig()
    return storage[panelName][storage[panelName].currentMode]
end

-- Voice command triggers
onTalk(function(name, level, mode, text, channelId, pos)
    local currentConfig = getActiveConfig() -- Now getActiveConfig is in scope
    if not currentConfig then return end -- Safety check

    -- If none of the healing options are enabled in the current mode, return early.
    if not (currentConfig.enableSenzu or
            currentConfig.enableRedSenzu or
            currentConfig.enableUltimatePotion or
            currentConfig.enableMana or
            currentConfig.enableRage) then
        return
    end

    if name ~= player:getName() then return end

    if text:lower() == "i feel the best!" and canUseItem("Senzu") then
        lastUsed.Senzu = now
        lastUsedGlobal = now
    elseif text:lower() == "i feel extreme!" and canUseItem("RedSenzu") then
        lastUsed.RedSenzu = now
        lastUsedGlobal = now
    elseif text:lower() == "omg! yeah" and canUseItem("UltimatePotion") then
        lastUsed.UltimatePotion = now
        lastUsedGlobal = now
    end
end)

-- Initialize storage if not exists
if not storage[panelName] then
    local defaultConfig = {
        senzuPercent = 60,
        redSenzuPercent = 30,
        ultimatePotionPercent = 80,
        manaPercent = 50,
        rageValue = 100,
        enableSenzu = false,
        enableRedSenzu = false,
        enableUltimatePotion = false,
        enableMana = false,
        enableRage = false
    }

    storage[panelName] = {
        currentMode = "pve",
        pve = defaultConfig,
        pvp = {
            senzuPercent = 80,
            redSenzuPercent = 80,
            ultimatePotionPercent = 80,
            manaPercent = 70,
            rageValue = 150,
            enableSenzu = false,
            enableRedSenzu = false,
            enableUltimatePotion = false,
            enableMana = false,
            enableRage = false
        },
        globalCooldown = 150
    }
end

-- Find UI widget by ID
local function findChildById(widget, id)
    if widget:getId() == id then return widget end
    for _, child in ipairs(widget:getChildren()) do
        local found = findChildById(child, id)
        if found then return found end
    end
    return nil
end

-- Update UI controls
local function updateControls()
    if not wodboHealingWindow then return end
    local currentConfig = getActiveConfig()
    if not currentConfig then return end

    local controls = {
        {switch = 'enableSenzu', scroll = 'senzuScroll', value = currentConfig.senzuPercent, text = "% HP"},
        {switch = 'enableRedSenzu', scroll = 'redSenzuScroll', value = currentConfig.redSenzuPercent, text = "% HP"},
        {switch = 'enableUltimatePotion', scroll = 'ultimatePotionScroll', value = currentConfig.ultimatePotionPercent, text = "% HP"},
        {switch = 'enableMana', scroll = 'manaScroll', value = currentConfig.manaPercent, text = "% MP"},
        {switch = 'enableRage', scroll = 'rageScroll', value = currentConfig.rageValue, text = " Soul"}
    }

    for _, control in ipairs(controls) do
        local sw = findChildById(wodboHealingWindow, control.switch)
        local sc = findChildById(wodboHealingWindow, control.scroll)
        if sw then
            sw:setText(control.value .. control.text)
            sw:setOn(currentConfig[control.switch])
        end
        if sc then
            sc:setValue(control.value)
        end
    end
end

-- Healing macros
local senzuMacro = macro(50, function()
    local currentConfig = getActiveConfig()
    if not currentConfig or not currentConfig.enableSenzu then return end
    
    if player:getHealthPercent() <= currentConfig.senzuPercent and canUseItem("Senzu") then
        g_game.useInventoryItem(SENZU_ID)
        lastUsed.Senzu = now
        lastUsedGlobal = now
    end
end)

local redSenzuMacro = macro(50, function()
    local currentConfig = getActiveConfig()
    if not currentConfig or not currentConfig.enableRedSenzu then return end
    
    if player:getHealthPercent() <= currentConfig.redSenzuPercent and canUseItem("RedSenzu") then
        g_game.useInventoryItem(RED_SENZU_ID)
        lastUsed.RedSenzu = now
        lastUsedGlobal = now
    end
end)

local ultimatePotionMacro = macro(50, function()
    local currentConfig = getActiveConfig()
    if not currentConfig or not currentConfig.enableUltimatePotion then return end
    
    if player:getHealthPercent() <= currentConfig.ultimatePotionPercent and canUseItem("UltimatePotion") then
        g_game.useInventoryItem(ULTIMATE_POTION_ID)
        lastUsed.UltimatePotion = now
        lastUsedGlobal = now
    end
end)

-- Makra dla many i soul
local manaMacro = macro(50, function()
    local currentConfig = getActiveConfig()
    if not currentConfig or not currentConfig.enableMana then return end
    
    local maxMana = player:getMaxMana()
    if maxMana == 0 then return end
    local mpPercent = math.floor((player:getMana() / maxMana) * 100)
    
    if mpPercent <= currentConfig.manaPercent and canUseItem("Senzu") then
        g_game.useInventoryItem(SENZU_ID)
        lastUsed.Senzu = now
        lastUsedGlobal = now
    end
end)

local rageMacro = macro(50, function()
    local currentConfig = getActiveConfig()
    if not currentConfig or not currentConfig.enableRage then return end
    
    if player:getSoul() <= currentConfig.rageValue and canUseItem("RedSenzu") then
        g_game.useInventoryItem(RED_SENZU_ID)
        lastUsed.RedSenzu = now
        lastUsedGlobal = now
    end
end)

-- Initialize UI controls
local function initializeControls()
    local currentConfig = getActiveConfig()
    if not currentConfig then return end
    
    local function setupControl(switchId, configKey, percentKey, scrollId, macro)
        local switch = findChildById(wodboHealingWindow, switchId)
        local scroll = findChildById(wodboHealingWindow, scrollId)
        
        if scroll then
            scroll:setValue(currentConfig[percentKey])
            scroll.onValueChange = function(_, value)
                local mode = storage[panelName].currentMode
                storage[panelName][mode][percentKey] = value
                if switch then
                    switch:setText(value .. (percentKey == "rageValue" and " Soul" or percentKey == "manaPercent" and "% MP" or "% HP"))
                end
            end
        end
        
        if switch then
            switch:setOn(currentConfig[configKey])
            switch:setText(currentConfig[percentKey] .. (percentKey == "rageValue" and " Soul" or percentKey == "manaPercent" and "% MP" or "% HP"))
            switch.onClick = function(widget)
                local mode = storage[panelName].currentMode
                storage[panelName][mode][configKey] = not storage[panelName][mode][configKey]
                widget:setOn(storage[panelName][mode][configKey])
                macro.setOn(storage[panelName][mode][configKey])
            end
        end
    end

    setupControl('enableSenzu', 'enableSenzu', 'senzuPercent', 'senzuScroll', senzuMacro)
    setupControl('enableRedSenzu', 'enableRedSenzu', 'redSenzuPercent', 'redSenzuScroll', redSenzuMacro)
    setupControl('enableUltimatePotion', 'enableUltimatePotion', 'ultimatePotionPercent', 'ultimatePotionScroll', ultimatePotionMacro)
    setupControl('enableMana', 'enableMana', 'manaPercent', 'manaScroll', manaMacro)
    setupControl('enableRage', 'enableRage', 'rageValue', 'rageScroll', rageMacro)

    local globalCooldownEdit = findChildById(wodboHealingWindow, 'globalCooldownEdit')
    if globalCooldownEdit then
        globalCooldownEdit:setText(tostring(storage[panelName].globalCooldown))
        globalCooldownEdit.onTextChange = function(_, text)
            local cooldown = tonumber(text)
            if cooldown and cooldown >= 0 then
                storage[panelName].globalCooldown = cooldown
            else
                globalCooldownEdit:setText("150")
                storage[panelName].globalCooldown = 150
            end
        end
    end
    
    updateControls()
end

-- Switch between PvE/PvP modes
local function switchMode(newMode)
    senzuMacro.setOn(false)
    redSenzuMacro.setOn(false)
    ultimatePotionMacro.setOn(false)
    manaMacro.setOn(false)
    rageMacro.setOn(false)
    
    storage[panelName].currentMode = newMode
    local newConfig = storage[panelName][newMode]
    
    if wodboHealingWindow and wodboHealingWindow:isVisible() then
        initializeControls()
    end
    
    senzuMacro.setOn(newConfig.enableSenzu)
    redSenzuMacro.setOn(newConfig.enableRedSenzu)
    ultimatePotionMacro.setOn(newConfig.enableUltimatePotion)
    manaMacro.setOn(newConfig.enableMana)
    rageMacro.setOn(newConfig.enableRage)
    
    updateControls()
    
    if ui.modeSwitch then
        ui.modeSwitch:setOn(newMode == "pvp")
        ui.modeSwitch:setText(newMode == "pvp" and "PvP Mode" or "PvE Mode")
    end
end

-- Create main UI panel
ui = setupUI([[
Panel
  id: wodboHealingPanel
  height: 45
  margin-top: 2

  Button
    id: open
    text: Wodbo Healing Setup
    anchors.top: parent.top
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
    color: yellow

  BotSwitch
    id: modeSwitch
    text: PvE Mode
    anchors.top: prev.bottom
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
]])

ui:setId(panelName)

-- Setup mode switch
if ui.modeSwitch then
    ui.modeSwitch:setOn(storage[panelName].currentMode == "pvp")
    ui.modeSwitch:setText(storage[panelName].currentMode == "pvp" and "PvP Mode" or "PvE Mode")
    
    ui.modeSwitch.onClick = function(widget)
        local currentMode = storage[panelName].currentMode
        local newMode = currentMode == "pvp" and "pve" or "pvp"
        widget:setText(newMode == "pvp" and "PvP Mode" or "PvE Mode")
        switchMode(newMode)
    end
end

-- Create configuration window
rootWidget = g_ui.getRootWidget()
if rootWidget then
    wodboHealingWindow = UI.createWindow('WodboHealingWindow', rootWidget)
    wodboHealingWindow:hide()
    
    wodboHealingWindow.onVisibilityChange = function(widget, visible)
        if visible then
            initializeControls()
        end
    end
end

-- Open window button
ui.open.onClick = function()
    if wodboHealingWindow then
        wodboHealingWindow:show()
        wodboHealingWindow:raise()
        wodboHealingWindow:focus()
    end
end

-- Initialize macros with current settings
local currentConfig = getActiveConfig()
if currentConfig then
    senzuMacro.setOn(currentConfig.enableSenzu)
    redSenzuMacro.setOn(currentConfig.enableRedSenzu)
    ultimatePotionMacro.setOn(currentConfig.enableUltimatePotion)
    manaMacro.setOn(currentConfig.enableMana)
    rageMacro.setOn(currentConfig.enableRage)
end