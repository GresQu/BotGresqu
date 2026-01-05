-- Script Manager & Loader
-- Author: GresQu
-- Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-05-02 08:15:12
-- Current User's Login: GresQu

-- Funkcja sprawdzająca dostęp
local function hasAccess()
    local ALLOWED_USERS = {
        ["GresQu"] = true,
        ["AdminName2"] = true,
        -- Dodaj więcej adminów tutaj
    }
    return true -- zamień return aby wlaczyc/wylaczyc access 
  -- return ALLOWED_USERS[g_game.getCharacterName()]
end

local scriptManager = {
    scripts = {},
    checkboxes = {},
    loadedScripts = {}
}

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
authorLabel = UI.Label("- Made By GresQu - v1.06")
authorLabel:setColor("yellow")
local sep1 = UI.Separator()
sep1:setHeight(4)
sep1:setBackgroundColor('#A0B0C0')
-- Upewnij się, że storage istnieje
storage.scriptManager = storage.scriptManager or {}

-- Definicja dostępnych skryptów -- hidden = true, status = "disable" 
-- disable ustawia status skryptu na off ale nie usuwa go calkowicie, uzytkownik dalej moze go wlaczyc jesli nie jest hidden 
scriptManager.availableScripts = {
    {name = "Warning System", id = "warning", file = "warning", hidden = true},
    {name = "Updater", id = "Updater", file = "updater", status = "disable"},
    {name = "profile_selector", id = "profile_selector", file = "profile_selector_ui", status = "disable"},
    {name = "FriendList", id = "myFriendList", file = "myFriendList", hidden = true},
    {name = "Alarms", id = "alarms", file = "alarms"},
    {name = "Auto Friend Party", id = "auto_friend_party", file = "auto_friend_party"},
    {name = "Ingame Editor", id = "ingame_editor", file = "ingame_editor"},
    {name = "BattleList Filters", id = "battleListFilters", file = "battleListFilters" , status = "disable"},
    {name = "NDBO_Chaos", id = "NDBO_Chaos", file = "NDBO_Chaos", status = "disable"},
    {name = "Friend_Healer", id = "Friend_Healer", file = "_x_friend_heal"},
    {name = "Advanced Spell Caster", id = "AdvancedSpellCaster", file = "AdvancedSpellCaster"},
    {name = "Attack Low", id = "smartertargeting", file = "smartertargeting"},
    {name = "Attack High", id = "AttackMonsterwithMoreHp", file = "AttackMonsterwithMoreHp"},
    {name = "Effect Avoider", id = "effect_avoider", file = "effect_avoider"},
    {name = "exp_gain", id = "exp_gain", file = "exp_gain", status = "disable"},
    {name = "Cast_Spell", id = "Cast_Spell", file = "_z_spell_cast", status = "disable"},
    {name = "Icon Cave-Target", id = "ToogleCaveTarg", file = "ToogleCaveTarg"},
    {name = "Containers", id = "Containers", file = "Containers"},
    {name = "Sense_last_target", id = "Sense_last_target", file = "Sense_last_target"},
    {name = "Auto Follow Name", id = "Auto Follow", file = "AutoFollowName"},
    {name = "auto_follow_attacker", id = "auto_follow_attacker", file = "auto_follow_attacker"},
    {name = "mana shield", id = "mana_shield", file = "mana_shield", status = "disable"},
    {name = "Hold_Target", id = "Hold_Target", file = "hold_target"},
	{name = "Bug_map", id = "Bug_map", file = "Bug_map"},
    {name = "TurnToTarget", id = "TurnToTarget", file = "TurnToTarget"},
    {name = "Attack_All", id = "Attack_All", file = "Attack_All"},
    {name = "Attack_Back", id = "Attack_Back", file = "Attack_Back"},
    {name = "Anty_push", id = "Anty_push", file = "Anty_push"},
    {name = "pick_up", id = "pick_up", file = "pick_up"},
    {name = "exchange_money", id = "exchange_money", file = "exchange_money"},
    {name = "Skinner", id = "Skinner", file = "skinner"},
    {name = "Healing Spell", id = "healing_setup", file = "healing_setup"},
    {name = "Wodbo_Healing", id = "Wodbo_Healing", file = "Wodbo_Healing", status = "disable"},
    {name = "Healing Items", id = "Healing_item", file = "Healing_item"},
    {name = "basic_buff", id = "basic_buff", file = "basic_buff", status = "disable"},
    {name = "Advanced Buffs", id = "AdvancedBuff", file = "AdvancedBuff"},
    {name = "Speed_Up", id = "Speed_Up", file = "Speed_up"},
    {name = "ManaTrain", id = "ManaTrain", file = "ManaTrain"},
    {name = "Eat Food", id = "eat_food", file = "eat_food"},
    {name = "CaveBot", id = "cavebot", file = "cavebot"},
    {name = "Analyzer", id = "analyzer", file = "analyzer", status = "disable"},
    {name = "Spy Level", id = "spy_level", file = "spy_level"},
    {name = "bless", id = "bless", file = "bless", status = "disable"},
    {name = "Stack Items", id = "StackItems", file = "StackItems", status = "disable"},
    {name = "Summon_Pet", id = "Summon_Pet", file = "Summon_Pet", status = "disable"},
    {name = "Auto Energy", id = "AutoEnergy", file = "AutoEnergy", status = "disable", status = "disable"},
    {name = "Fast_Move", id = "Fast_Move", file = "MoveEW", status = "disable", status = "disable"},
    {name = "trade_message", id = "trade_message", file = "trade_message", status = "disable"},
    {name = "afkmsgreply", id = "afkmsgreply", file = "afkmsgreply", status = "disable"},
    {name = "NPC Talk", id = "npc_talk", file = "npc_talk", hidden = false, status = "disable"},
	{name = "Auto_traveler", id = "Auto_traveler", file = "Auto_traveler"}

}

-- Inicjalizacja stanu skryptów z storage (ZMIENIONE)
for _, script in ipairs(scriptManager.availableScripts) do
    if storage.scriptManager[script.id] == nil then
        storage.scriptManager[script.id] = (script.status ~= "disable")
    end
    script.enabled = storage.scriptManager[script.id]
    script.hidden = script.hidden or false
end

-- Podstawowe skrypty, które zawsze są załadowane
local coreScripts = {
    "items",
    "vlib",
    "new_cavebot_lib",
    "configs",
    "extras",
    "profile_changer",
}

setDefaultTab("Main")

if hasAccess() then
    managerUi = setupUI([[
Panel
  id: scriptManagerPanel
  height: 20
  margin-top: 2

  Button
    id: toggleManager
    text: Script Manager
    anchors.top: prev.bottom
    anchors.left: parent.left
    width: 175
    height: 20
    margin-top: 2
]])
end


-- Funkcja do ładowania plików .otui i .ui
local function loadOTUIFiles(configName)
    local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
    for i, file in ipairs(configFiles) do
        local ext = file:split(".")
        if ext[#ext]:lower() == "otui" or ext[#ext]:lower() == "ui" then
            g_ui.importStyle(file)
        end
    end
end

-- Funkcja do ładowania skryptów Lua
local function loadScript(name)
    return dofile("/vBot/" .. name .. ".lua")
end

-- Funkcja ładowania wszystkich skryptów (ZMIENIONE)
local function loadAllScripts()
    -- Załaduj najpierw wszystkie pliki .otui i .ui
    loadOTUIFiles(modules.game_bot.contentsPanel.config:getCurrentOption().text)

    -- Najpierw załaduj podstawowe skrypty
    for _, script in ipairs(coreScripts) do
        loadScript(script)
    end

    -- Następnie załaduj wybrane skrypty
    for _, script in ipairs(scriptManager.availableScripts) do
        if storage.scriptManager[script.id] then
            loadScript(script.file)
        end
    end
end

-- Wywołaj funkcję ładującą
loadAllScripts()

if hasAccess() then
    -- Tworzenie interfejsu użytkownika
    local ui = UI.createWindow('ScriptManagerWindow', rootWidget)
    local scriptList = ui:recursiveGetChildById('scriptList')

    -- Funkcja zapisująca stan skryptu
    function scriptManager.saveScriptState(scriptId, enabled)
        storage.scriptManager[scriptId] = enabled
    end

    -- Funkcja tworząca checkbox dla skryptu (ZMIENIONE)
    function scriptManager.createScriptCheckBox(script)
        -- Jeśli skrypt jest ukryty, nie twórz dla niego checkboxa
        if script.hidden then return end
        
        local checkbox = g_ui.createWidget('CheckBox', scriptList)
        checkbox:setText(script.name)
        checkbox:setChecked(storage.scriptManager[script.id])
        
        checkbox.onCheckChange = function(widget, checked)
            scriptManager.saveScriptState(script.id, checked)
            
            -- Informacja o zmianie
            modules.game_textmessage.displayGameMessage(string.format(
                'Script %s will be %s after restart', 
                script.name, 
                checked and 'enabled' or 'disabled'
            ))
        end
        
        scriptManager.checkboxes[script.id] = checkbox
        return checkbox
    end

    -- Inicjalizacja checkboxów
    for _, script in ipairs(scriptManager.availableScripts) do
        scriptManager.createScriptCheckBox(script)
    end

    -- Obsługa przycisków
    local selectAllButton = ui:recursiveGetChildById('selectAllButton')
    local unselectAllButton = ui:recursiveGetChildById('unselectAllButton')
    local applyButton = ui:recursiveGetChildById('applyButton')

    if selectAllButton then
        selectAllButton.onClick = function()
            for _, script in ipairs(scriptManager.availableScripts) do
                if not script.hidden and scriptManager.checkboxes[script.id] then
                    scriptManager.checkboxes[script.id]:setChecked(true)
                end
            end
        end
    end

    if unselectAllButton then
        unselectAllButton.onClick = function()
            for _, script in ipairs(scriptManager.availableScripts) do
                if not script.hidden and scriptManager.checkboxes[script.id] then
                    scriptManager.checkboxes[script.id]:setChecked(false)
                end
            end
        end
    end

    if applyButton then
        applyButton.onClick = function()
            modules.game_textmessage.displayGameMessage('Restarting bot to apply changes...')
            reload()
            ui:hide()
        end
    end

    managerUi.toggleManager.onClick = function()
        if ui:isVisible() then
            ui:hide()
        else
            ui:show()
            ui:raise()
            ui:focus()
        end
    end

    -- Ukryj okno na starcie
    ui:hide()
end

return scriptManager
