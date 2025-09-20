local HTTP = modules._G.HTTP

-- Pobierz aktualny config tak jak w loaderze
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
warn("Using config: " .. configName)

-- Folders
local vBotFolder = "bot/" .. configName .. "/vBot"
local configFolder = "bot/" .. configName
local storageFolder = "bot/" .. configName .. "/storage"
local cavebotFolder = "bot/" .. configName .. "/cavebot"
local targetbotFolder = "bot/" .. configName .. "/targetbot"

-- Global variables
local updateInProgress = false
local updateProgressEvent = nil

-- Progress functions BEZ removeEvent
local function showUpdateProgress()
    if updateInProgress then
        warn("Updating...")
        updateProgressEvent = schedule(8000, showUpdateProgress)
    end
end

local function stopUpdateProgress()
    updateInProgress = false
    -- Nie usuwamy eventu, po prostu zmieniamy flagę
end

-- HTTP BEZ removeEvent - używamy flagi
local function safeHTTPGet(url, callback, timeout)
    timeout = timeout or 15000
    local completed = false
    
    -- Timeout przez flagę zamiast removeEvent
    scheduleEvent(function()
        if not completed then
            completed = true
            warn("TIMEOUT: " .. url:match("[^/]+$"))
            callback(nil, "Timeout")
        end
    end, timeout)
    
    HTTP.get(url, function(content, err)
        if completed then return end
        completed = true
        callback(content, err)
    end)
end

-- Download function (bez zmian)
local function downloadFilesSequential(fileList, urlBase, folder, results, onComplete)
    local index = 1
    
    local function nextFile()
        if index > #fileList then
            if onComplete then onComplete() end
            return
        end
        
        local filename = fileList[index]
        local url = urlBase .. filename
        local localPath = folder .. "/" .. filename
        
        warn("Downloading " .. index .. "/" .. #fileList .. ": " .. filename)
        
        safeHTTPGet(url, function(content, err)
            if err then
                warn("ERROR: " .. filename .. " - " .. tostring(err))
                results.errors = results.errors + 1
            elseif not content or content == "" or content:find("404") then
                warn("FAILED: " .. filename)
                results.errors = results.errors + 1
            else
                -- Check if file is different
                local saveResult = "new"
                if g_resources.fileExists(localPath) then
                    local existing = g_resources.readFileContents(localPath)
                    if existing == content then
                        warn("IDENTICAL: " .. filename)
                        results.identical = results.identical + 1
                        saveResult = "identical"
                    end
                end
                
                -- Save if different
                if saveResult ~= "identical" then
                    local folderPath = localPath:match("(.+)/[^/]+$")
                    if folderPath and not g_resources.directoryExists(folderPath) then
                        g_resources.makeDir(folderPath)
                    end
                    
                    local success = g_resources.writeFileContents(localPath, content)
                    if success then
                        warn("UPDATED: " .. filename)
                        results.updated = results.updated + 1
                    else
                        warn("SAVE FAILED: " .. filename)
                        results.errors = results.errors + 1
                    end
                end
            end
            
            index = index + 1
            scheduleEvent(nextFile, 300) -- 300ms delay
        end)
    end
    
    nextFile()
end

-- Main update function (bez zmian)
local function runUpdate(fileGroups)
    local results = {
        updated = 0, identical = 0, errors = 0
    }
    
    local groupIndex = 1
    local totalGroups = #fileGroups
    
    updateInProgress = true
    showUpdateProgress()
    
    local function processNextGroup()
        if groupIndex > totalGroups then
            stopUpdateProgress()
            warn("=== UPDATE SUMMARY ===")
            warn("Updated: " .. results.updated)
            warn("Identical: " .. results.identical) 
            warn("Errors: " .. results.errors)
            
            if results.updated > 0 then
                warn("RESTART BOT!")
            else
                warn("All files up to date.")
            end
            return
        end
        
        local group = fileGroups[groupIndex]
        warn("Processing: " .. group.folder:match("[^/]+$"))
        groupIndex = groupIndex + 1
        
        downloadFilesSequential(group.list, group.url, group.folder, results, processNextGroup)
    end
    
    warn("Starting update...")
    processNextGroup()
end

-- File lists (twoje listy bez zmian)
local vBotFiles = {
  "updater.lua", "AdvancedBuff.lua", "AdvancedSpellCaster.lua", "AdvancedSpellCaster.otui", "Anty_push.lua",
  "AttackMonsterwithMoreHp.lua", "Attack_All.lua", "Attack_Back.lua", "AutoEnergy.lua",
  "AutoFollowName.lua", "Auto_traveler.lua", "Bug_map.lua", "Containers.lua", "Healing_item.lua",
  "Healing_item.otui", "ManaTrain.lua", "MoveEW.lua", "NDBO_Chaos.lua", "Sense_last_target.lua",
  "Speed_up.lua", "StackItems.lua", "Summon_Pet.lua", "Summon_Pet.otui", "ToogleCaveTarg.lua",
  "TurnToTarget.lua", "Wodbo_Healing.lua", "Wodbo_Healing.otui", "_x_friend_heal.lua",
  "_z_spell_cast.lua", "afkmsgreply.lua", "alarms.lua", "alarms.otui", "analyzer.lua", "analyzer.otui",
  "auto_follow_attacker.lua", "auto_friend_party.lua", "basic_buff.lua", "battleListFilters.lua",
  "bless.lua", "cavebot.lua", "configs.lua", "depositer_config.lua", "depositer_config.otui",
  "eat_food.lua", "effect_avoider.lua", "equip.lua", "exchange_money.lua", "exeta.lua", "exp_gain.lua",
  "extras.lua", "extras.otui", "healing_setup.lua", "healing_setup.otui", "hold_target.lua",
  "ingame_editor.lua", "items.lua", "myFriendList.lua", "new_cavebot_lib.lua", "npc_talk.lua",
  "pick_up.lua", "profile_changer.lua", "profile_selector_ui.lua", "smartertargeting.lua",
  "spy_level.lua", "trade_message.lua", "version.txt", "vlib.lua", "warning.lua", "xeno_menu.lua",
  "_Loader.otui"
}
local mainFiles = { "_Loader.lua" }
local cavebotFiles = {
  "actions.lua", "cavebot.lua", "cavebot.otui", "clear_tile.lua",
  "config.lua", "config.otui", "doors.lua", "editor.lua",
  "editor.otui", "example_functions.lua", "extension_template.lua",
  "lure.lua", "minimap.lua", "pos_check.lua", "recorder.lua",
  "stand_lure.lua", "travel.lua", "walking.lua"
}
local targetbotFiles = {
  "creature.lua", "creature_attack.lua", "creature_editor.lua", "creature_editor.otui",
  "creature_priority.lua", "looting.lua", "looting.otui", "target.lua", "target.otui", "walking.lua"
}

-- Buttons
UI.Button("Update All", function()
    if updateInProgress then
        warn("Update in progress!")
        return
    end
    
    runUpdate({
        {list = vBotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/vBot/", folder = vBotFolder},
        {list = mainFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/", folder = configFolder},
        {list = cavebotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/cavebot/", folder = cavebotFolder},
        {list = targetbotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/targetbot/", folder = targetbotFolder}
    })
end)

-- Profile fix button
local function removeProfileFiles()
    local removedCount = 0
    local profileFiles = {"profile_1.json", "profile_2.json", "profile_3.json", "profile_4.json", "profile_5.json"}
    
    for _, filename in ipairs(profileFiles) do
        local profilePath = storageFolder .. "/" .. filename
        if g_resources.fileExists(profilePath) then
            local success = g_resources.deleteFile(profilePath)
            if success then
                removedCount = removedCount + 1
                warn("Removed: " .. filename)
            end
        end
    end
    
    return removedCount
end

UI.Button("Fix After Update", function()
    if updateInProgress then
        warn("Wait for update")
        return
    end
    
    local removedCount = removeProfileFiles()
    
    if removedCount > 0 then
        warn("Profiles fixed. Restart bot.")
    else
        warn("No profiles to fix.")
    end
end)
