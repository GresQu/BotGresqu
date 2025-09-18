local HTTP = modules._G.HTTP

-- Detect current config
local function detectConfigName()
    local configs = g_resources.listDirectoryFiles("bot", false, true)
    for _, config in ipairs(configs) do
        if g_resources.directoryExists("bot/" .. config .. "/vBot") then
            return config
        end
    end
    return nil
end

local configName = detectConfigName() or "default"

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
        warn("Update in progress... please wait")
        updateProgressEvent = schedule(8000, showUpdateProgress)
    end
end

-- Stop progress messages
local function stopUpdateProgress()
    updateInProgress = false
    if updateProgressEvent then
        removeEvent(updateProgressEvent)
        updateProgressEvent = nil
    end
end

-- Function to remove profile files from storage
local function removeProfileFiles()
    local removedFiles = {}
    local profileFiles = {"profile_1.json", "profile_2.json", "profile_3.json", "profile_4.json", "profile_5.json"}
    
    print("=== REMOVING PROFILE FILES ===")
    
    for _, filename in ipairs(profileFiles) do
        local profilePath = storageFolder .. "/" .. filename
        if g_resources.fileExists(profilePath) then
            local success = g_resources.deleteFile(profilePath)
            if success then
                print("REMOVED: " .. filename)
                table.insert(removedFiles, "REMOVED: storage/" .. filename)
            else
                print("ERROR removing: " .. filename)
            end
        else
            print("NOT FOUND: " .. filename)
        end
    end
    
    if #removedFiles > 0 then
        print("Removed " .. #removedFiles .. " profile files - they will be recreated with defaults")
    else
        print("No profile files found to remove")
    end
    print("")
    
    return removedFiles
end

-- Normalize content for better comparison
local function normalizeContent(content)
    if not content then return nil end
    -- Replace Windows/Mac line endings with Unix
    content = content:gsub('\r\n', '\n')
    content = content:gsub('\r', '\n')
    -- Remove trailing whitespace
    content = content:gsub('%s+$', '')
    return content
end

-- Enhanced save function with detailed logging
local function saveFile(path, content, filename)
    local folderPath = path:match("(.+)/[^/]+$")
    if folderPath and not g_resources.directoryExists(folderPath) then
        print("Creating folder: " .. folderPath)
        g_resources.makeDir(folderPath)
    end
    
    if g_resources.fileExists(path) then
        local existingContent = g_resources.readFileContents(path)
        if normalizeContent(existingContent) == normalizeContent(content) then
            print("SKIPPED (up to date): " .. filename)
            return false
        end
    end
    
    local success = g_resources.writeFileContents(path, content)
    if success then
        print("UPDATED: " .. filename)
        return true
    else
        print("ERROR writing file: " .. filename)
        return false
    end
end

-- Enhanced sequential download with detailed logging
local function downloadFilesSequential(fileList, urlBase, folder, updatedFiles, onComplete, folderName)
    local index = 1
    local folderUpdated = 0
    local folderSkipped = 0
    local folderErrors = 0
    
    print("=== Starting folder: " .. folderName .. " (" .. #fileList .. " files) ===")
    
    local function nextFile()
        if index > #fileList then
            print("=== Finished folder: " .. folderName .. " ===")
            print("Updated: " .. folderUpdated .. ", Skipped: " .. folderSkipped .. ", Errors: " .. folderErrors)
            print("")
            if onComplete then onComplete() end
            return
        end
        
        local filename = fileList[index]
        local url = urlBase .. filename
        local localPath = folder .. "/" .. filename
        
        print("Downloading: " .. filename .. " (" .. index .. "/" .. #fileList .. ")")
        
        HTTP.get(url, function(content, err)
            if err then
                print("DOWNLOAD ERROR: " .. filename .. " - " .. err)
                folderErrors = folderErrors + 1
            elseif not content or content == "" then
                print("EMPTY CONTENT: " .. filename)
                folderErrors = folderErrors + 1
            else
                if saveFile(localPath, content, filename) then
                    table.insert(updatedFiles, folderName .. "/" .. filename)
                    folderUpdated = folderUpdated + 1
                else
                    folderSkipped = folderSkipped + 1
                end
            end
            index = index + 1
            nextFile()
        end)
    end
    nextFile()
end

-- Enhanced update function with profile removal
local function runUpdate(fileGroups, removeProfiles)
    local updatedFiles = {}
    local groupIndex = 1
    local totalGroups = #fileGroups
    
    -- Remove profile files if requested
    if removeProfiles then
        local removedFiles = removeProfileFiles()
        for _, file in ipairs(removedFiles) do
            table.insert(updatedFiles, file)
        end
    end
    
    -- Verify all folders exist
    print("=== FOLDER VERIFICATION ===")
    for _, group in ipairs(fileGroups) do
        if not g_resources.directoryExists(group.folder) then
            print("Creating missing folder: " .. group.folder)
            g_resources.makeDir(group.folder)
        else
            print("Folder exists: " .. group.folder)
        end
    end
    print("")
    
    updateInProgress = true
    showUpdateProgress()
    
    local function processNextGroup()
        if groupIndex > totalGroups then
            stopUpdateProgress()
            
            local totalExpected = 0
            for _, group in ipairs(fileGroups) do
                totalExpected = totalExpected + #group.list
            end
            
            print("=== UPDATE SUMMARY ===")
            print("Expected files: " .. totalExpected)
            print("Updated/Removed files: " .. #updatedFiles)
            print("")
            
            if #updatedFiles > 0 then
                print("Updated/Removed files list:")
                for _, file in ipairs(updatedFiles) do
                    print("- " .. file)
                end
                warn("Update completed! Updated " .. #updatedFiles .. " files.\n\nPlease restart the bot to apply changes.")
            else
                warn("Update completed! All " .. totalExpected .. " files are up to date.\n\nPlease restart the bot.")
            end
            return
        end
        
        local group = fileGroups[groupIndex]
        local folderName = group.folder:match(".*/(.+)$") or group.folder
        groupIndex = groupIndex + 1
        
        downloadFilesSequential(group.list, group.url, group.folder, updatedFiles, processNextGroup, folderName)
    end
    
    print("=== STARTING UPDATE PROCESS ===")
    warn("Starting update...")
    processNextGroup()
end

-- File lists
local vBotFiles = {
  "AdvancedBuff.lua", "AdvancedSpellCaster.lua", "AdvancedSpellCaster.otui", "Anty_push.lua",
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
  "_Loader.otui", "updater.lua"
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

-- Enhanced buttons with profile removal option
UI.Button("Update All + Reset Profiles", function()
    if updateInProgress then
        warn("Update already in progress, please wait...")
        return
    end
    
    print("vBot files count: " .. #vBotFiles)
    print("Main files count: " .. #mainFiles)
    print("Cavebot files count: " .. #cavebotFiles)
    print("Targetbot files count: " .. #targetbotFiles)
    print("Total expected: " .. (#vBotFiles + #mainFiles + #cavebotFiles + #targetbotFiles))
    print("Profile removal: ENABLED")
    print("")
    
    runUpdate({
        {list = vBotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/vBot/", folder = vBotFolder},
        {list = mainFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/", folder = configFolder},
        {list = cavebotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/cavebot/", folder = cavebotFolder},
        {list = targetbotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/main/targetbot/", folder = targetbotFolder}
    }, true) -- true = remove profiles
end)

UI.Button("Only Remove Profiles", function()
    if updateInProgress then
        warn("Update already in progress, please wait...")
        return
    end
    
    print("=== PROFILE REMOVAL ONLY ===")
    local removedFiles = removeProfileFiles()
    
    if #removedFiles > 0 then
        warn("Profile removal completed! Removed " .. #removedFiles .. " files.\n\nPlease restart the bot to recreate defaults.")
    else
        warn("Profile removal completed! No profile files found.")
    end
end)
