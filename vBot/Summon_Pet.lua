-- Summon Setup Script
-- Author: GresQu
-- Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-27 18:02:55
-- Current User's Login: GresQu
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local panelName = "summonSetup"
local summonSetupWindow
local lastUses = {0, 0}

-- Główny makro dla summonów (deklaracja na początku)
local summonMacro

-- Konfiguracja domyślna
storage[panelName] = storage[panelName] or {}
storage[panelName].summons = storage[panelName].summons or {
    left = {name = "", itemId = "0", spell = "", delay = "2000", enabled = false},
    right = {name = "", itemId = "0", spell = "", delay = "2000", enabled = false}
}

local function loadSettings()
    if not summonSetupWindow then return end
    
    -- Left
    summonSetupWindow:recursiveGetChildById('leftPetName'):setText(storage[panelName].summons.left.name)
    summonSetupWindow:recursiveGetChildById('leftItemId'):setText(storage[panelName].summons.left.itemId)
    summonSetupWindow:recursiveGetChildById('leftSpell'):setText(storage[panelName].summons.left.spell)
    summonSetupWindow:recursiveGetChildById('leftDelay'):setText(storage[panelName].summons.left.delay)
    summonSetupWindow:recursiveGetChildById('leftEnabled'):setOn(storage[panelName].summons.left.enabled)
    
    -- Right
    summonSetupWindow:recursiveGetChildById('rightPetName'):setText(storage[panelName].summons.right.name)
    summonSetupWindow:recursiveGetChildById('rightItemId'):setText(storage[panelName].summons.right.itemId)
    summonSetupWindow:recursiveGetChildById('rightSpell'):setText(storage[panelName].summons.right.spell)
    summonSetupWindow:recursiveGetChildById('rightDelay'):setText(storage[panelName].summons.right.delay)
    summonSetupWindow:recursiveGetChildById('rightEnabled'):setOn(storage[panelName].summons.right.enabled)
end

local function saveSettings()
    if not summonSetupWindow then return end
    
    -- Left
    storage[panelName].summons.left.name = summonSetupWindow:recursiveGetChildById('leftPetName'):getText()
    storage[panelName].summons.left.itemId = summonSetupWindow:recursiveGetChildById('leftItemId'):getText()
    storage[panelName].summons.left.spell = summonSetupWindow:recursiveGetChildById('leftSpell'):getText()
    storage[panelName].summons.left.delay = summonSetupWindow:recursiveGetChildById('leftDelay'):getText()
    storage[panelName].summons.left.enabled = summonSetupWindow:recursiveGetChildById('leftEnabled'):isOn()
    
    -- Right
    storage[panelName].summons.right.name = summonSetupWindow:recursiveGetChildById('rightPetName'):getText()
    storage[panelName].summons.right.itemId = summonSetupWindow:recursiveGetChildById('rightItemId'):getText()
    storage[panelName].summons.right.spell = summonSetupWindow:recursiveGetChildById('rightSpell'):getText()
    storage[panelName].summons.right.delay = summonSetupWindow:recursiveGetChildById('rightDelay'):getText()
    storage[panelName].summons.right.enabled = summonSetupWindow:recursiveGetChildById('rightEnabled'):isOn()
end

local function toggleMacro()
    if summonMacro then
        local shouldBeEnabled = storage[panelName].summons.left.enabled or storage[panelName].summons.right.enabled
        summonMacro.setOn(shouldBeEnabled)
    end
end

local function initializeControls()
    if not summonSetupWindow then return end

    local leftSwitch = summonSetupWindow:recursiveGetChildById('leftEnabled')
    local rightSwitch = summonSetupWindow:recursiveGetChildById('rightEnabled')

    -- Dodajemy obsługę zdarzeń dla pól tekstowych
    local leftDelay = summonSetupWindow:recursiveGetChildById('leftDelay')
    local rightDelay = summonSetupWindow:recursiveGetChildById('rightDelay')

    if leftDelay then
        leftDelay.onTextChange = function(widget, text)
            storage[panelName].summons.left.delay = text
            saveSettings()
        end
    end

    if rightDelay then
        rightDelay.onTextChange = function(widget, text)
            storage[panelName].summons.right.delay = text
            saveSettings()
        end
    end

    if leftSwitch then
        leftSwitch:setOn(storage[panelName].summons.left.enabled)
        leftSwitch.onClick = function(widget)
            storage[panelName].summons.left.enabled = not storage[panelName].summons.left.enabled
            widget:setOn(storage[panelName].summons.left.enabled)
            saveSettings()
            toggleMacro()
        end
    end

    if rightSwitch then
        rightSwitch:setOn(storage[panelName].summons.right.enabled)
        rightSwitch.onClick = function(widget)
            storage[panelName].summons.right.enabled = not storage[panelName].summons.right.enabled
            widget:setOn(storage[panelName].summons.right.enabled)
            saveSettings()
            toggleMacro()
        end
    end
end

-- Tworzenie okna
rootWidget = g_ui.getRootWidget()
if rootWidget then
    summonSetupWindow = UI.createWindow('SummonSetupWindow', rootWidget)
    summonSetupWindow:hide()
    
    summonSetupWindow.onVisibilityChange = function(widget, visible)
        if visible then
            loadSettings()
            initializeControls()
        end
    end
    
    summonSetupWindow.onClose = function(widget)
        saveSettings()
        widget:hide()
    end
end

-- Główny makro dla summonów
summonMacro = macro(100, function()
    if not storage[panelName].summons.left.enabled and not storage[panelName].summons.right.enabled then
        return
    end

    local now = os.time() * 1000
    
    local function checkAndSummon(config, index)
        if not config.enabled or config.name == "" then return end
        
        local mobFound = false
        for _, creature in ipairs(getSpectators()) do
            if creature:getName():lower() == config.name:lower() then
                mobFound = true
                break
            end
        end
        
        if not mobFound and now > lastUses[index] + tonumber(config.delay or 2000) then
            if config.itemId and config.itemId ~= "0" and config.itemId ~= "" then
                local item = findItem(tonumber(config.itemId))
                if item then
                    g_game.use(item)
                    lastUses[index] = now
                end
            elseif config.spell and config.spell ~= "0" and config.spell ~= "" then
                say(config.spell)
                lastUses[index] = now
            end
        end
    end
    
    if storage[panelName].summons.left.enabled then
        checkAndSummon(storage[panelName].summons.left, 1)
    end
    
    if storage[panelName].summons.right.enabled then
        checkAndSummon(storage[panelName].summons.right, 2)
    end
end)

-- Dodaj przycisk w menu bota
local label = UI.Label("SUMMON SETUP")
label:setColor('yellow')
UI.Button("Configure", function()
    if summonSetupWindow:isVisible() then
        summonSetupWindow:hide()
    else
        summonSetupWindow:show()
        summonSetupWindow:raise()
        summonSetupWindow:focus()
    end
end)

-- Ustaw początkowy stan makra
toggleMacro()
