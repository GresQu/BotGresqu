local HTTP = modules._G.HTTP

-- Poprawiona funkcja detect current config (jak w loaderze)
local function detectConfigName()
    -- Method 1: Pobierz z vBot interface (jak w loaderze)
    if modules.game_bot and modules.game_bot.contentsPanel and modules.game_bot.contentsPanel.config then
        local currentConfig = modules.game_bot.contentsPanel.config:getCurrentOption()
        if currentConfig and currentConfig.text then
            return currentConfig.text
        end
    end
    
    -- Fallback: szukaj folderów z vBot
    local configs = g_resources.listDirectoryFiles("bot", false, true)
    for _, config in ipairs(configs) do
        if g_resources.directoryExists("bot/" .. config .. "/vBot") then
            return config
        end
    end
    return "default"
end

local configName = detectConfigName()
warn("Using config: " .. configName) -- Debug info

-- Folders
local vBotFolder = "bot/" .. configName .. "/vBot"
local configFolder = "bot/" .. configName
local storageFolder = "bot/" .. configName .. "/storage"
local cavebotFolder = "bot/" .. configName .. "/cavebot"
local targetbotFolder = "bot/" .. configName .. "/targetbot"

-- Global variable for update status
local updateInProgress = false
local updateProgressEvent = nil

-- Progress message function
local function showUpdateProgress()
    if updateInProgress then
        warn("Updating...")
        updateProgressEvent = schedule(8000, showUpdateProgress)
    end
end

-- Stop progress messages (FIXED - bez removeEvent)
local function stopUpdateProgress()
    updateInProgress = false
    -- removeEvent może nie istnieć w tej wersji, więc używamy tylko flagi
end

-- Function to remove profile files from storage
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

-- Save function (BEZ normalizeContent - porównanie bezpośrednie)
local function saveFile(path, content)
    local folderPath = path:match("(.+)/[^/]+$")
    if folderPath and not g_resources.directoryExists(folderPath) then
        g_resources.makeDir(folderPath)
    end
    
    -- DEBUG dla _Loader.lua
    if path:find("_Loader.lua") then
        warn("=== SAVE DEBUG _Loader.lua ===")
        warn("Path: " .. path)
        warn("File exists: " .. tostring(g_resources.fileExists(path)))
    end
    
    if g_resources.fileExists(path) then
        local existingContent = g_resources.readFileContents(path)
        
        -- SZCZEGÓŁOWY DEBUG dla _Loader.lua
        if path:find("_Loader.lua") then
            warn("Comparison:")
            warn("  Existing length: " .. #existingContent)
            warn("  New length: " .. #content)
            warn("  Existing has v1.0: " .. tostring(existingContent:find("v1.0") ~= nil))
            warn("  New has v1.0: " .. tostring(content:find("v1.0") ~= nil))
            warn("  Files equal: " .. tostring(existingContent == content))
            
            -- Pokaż pierwsze różnice
            for i = 1, math.min(200, #existingContent, #content) do
                if existingContent:sub(i,i) ~= content:sub(i,i) then
                    warn("  First difference at char " .. i .. ": '" .. existingContent:sub(i,i) .. "' vs '" .. content:sub(i,i) .. "'")
                    break
                end
            end
        end
        
        -- POPRAWKA: porównanie bezpośrednie zamiast normalizeContent
        if existingContent == content then
            if path:find("_Loader.lua") then
                warn("_Loader.lua files are IDENTICAL")
            end
            return false
        end
    end
    
    local success = g_resources.writeFileContents(path, content)
    
    if path:find("_Loader.lua") then
        warn("Write result: " .. tostring(success))
    end
    
    return success
end

-- Sequential download z debugiem
local function downloadFilesSequential(fileList, urlBase, folder, updatedFiles, onComplete)
    local index = 1
    
    local function nextFile()
        if index > #fileList then
            warn("Group completed: " .. folder)
            if onComplete then onComplete() end
            return
        end
        
        local filename = fileList[index]
        local url = urlBase .. filename
        local localPath = folder .. "/" .. filename
        
        -- DODAJ DEBUG dla _Loader.lua
        if filename == "_Loader.lua" then
            warn("=== DEBUG _Loader.lua ===")
            warn("URL: " .. url)
            warn("Local path: " .. localPath)
            warn("Folder exists: " .. tostring(g_resources.directoryExists(folder)))
        end
        
        warn("Downloading " .. index .. "/" .. #fileList .. ": " .. filename)
        
        HTTP.get(url, function(content, err)
            -- DODAJ DEBUG dla response
            if filename == "_Loader.lua" then
                warn("HTTP Response:")
                warn("  Error: " .. tostring(err or "none"))
                warn("  Content length: " .. (content and #content or 0))
                if content then
                    warn("  Has v1.0: " .. tostring(content:find("v1.0") ~= nil))
                end
            end
            
            if not err and content and content ~= "" then
                if saveFile(localPath, content) then
                    table.insert(updatedFiles, filename)
                    if filename == "_Loader.lua" then
                        warn("_Loader.lua UPDATED!")
                    end
                else
                    if filename == "_Loader.lua" then
                        warn("_Loader.lua NOT CHANGED (identical)")
                    end
                end
            else
                if filename == "_Loader.lua" then
                    warn("_Loader.lua FAILED: " .. tostring(err))
                end
            end
            
            index = index + 1
            nextFile()
        end)
    end
    nextFile()
end

-- Update function z pełnym debugiem
local function runUpdate(fileGroups)
    local updatedFiles = {}
    local groupIndex = 1
    local totalGroups = #fileGroups
    
    warn("=== UPDATE START DEBUG ===")
    warn("Total groups: " .. totalGroups)
    for i, group in ipairs(fileGroups) do
        warn("Group " .. i .. ": " .. #group.list .. " files to " .. group.folder)
        if group.list[1] then
            warn("  First file: " .. group.list[1])
        end
        warn("  URL: " .. group.url)
    end
    
    -- Verify all folders exist
    for _, group in ipairs(fileGroups) do
        if not g_resources.directoryExists(group.folder) then
            g_resources.makeDir(group.folder)
            warn("Created folder: " .. group.folder)
        else
            warn("Folder exists: " .. group.folder)
        end
    end
    
    updateInProgress = true
    showUpdateProgress()
    
    local function processNextGroup()
        warn("=== PROCESSING GROUP " .. groupIndex .. "/" .. totalGroups .. " ===")
        
        if groupIndex > totalGroups then
            stopUpdateProgress()
            
            warn("=== UPDATE SUMMARY ===")
            warn("Updated files: " .. #updatedFiles)
            for _, file in ipairs(updatedFiles) do
                warn("  - " .. file)
            end
            
            if #updatedFiles > 0 then
                warn("Update done. Restart bot.")
            else
                warn("All files up to date.")
            end
            return
        end
        
        local group = fileGroups[groupIndex]
        warn("Processing group: " .. group.folder)
        warn("Files in group: " .. #group.list)
        warn("URL base: " .. group.url)
        
        groupIndex = groupIndex + 1
        
        downloadFilesSequential(group.list, group.url, group.folder, updatedFiles, processNextGroup)
    end
    
    warn("Starting update...")
    processNextGroup()
end

-- File lists
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
        warn("Update in progress")
        return
    end
    
    -- POPRAWIONE URL z /refs/heads/main/
    runUpdate({
        {list = vBotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/vBot/", folder = vBotFolder},
        {list = mainFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/", folder = configFolder},
        {list = cavebotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/cavebot/", folder = cavebotFolder},
        {list = targetbotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/targetbot/", folder = targetbotFolder}
    })
end)

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
