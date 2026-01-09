local HTTP = modules._G.HTTP
local updateInProgress = false

-- Funkcja wykrywająca aktualny config (działa też gdy bot OFF)
local function detectConfigName()
  -- 1) z g_settings (najpewniejsze, bo bot zapisuje tam config)
  if g_settings and g_settings.getNode then
    local settings = g_settings.getNode('bot')
    if type(settings) == "table" then
      for _, s in ipairs(settings) do
        if type(s) == "table" and s.enabled and type(s.config) == "string" and s.config ~= "" then
          return s.config
        end
      end
      -- jeśli żaden nie jest enabled, weź pierwszy sensowny config
      for _, s in ipairs(settings) do
        if type(s) == "table" and type(s.config) == "string" and s.config ~= "" then
          return s.config
        end
      end
    end
  end

  -- 2) z UI bota (jak jest dostępne)
  if modules.game_bot and modules.game_bot.contentsPanel and modules.game_bot.contentsPanel.config then
    local currentConfig = modules.game_bot.contentsPanel.config:getCurrentOption()
    if currentConfig and currentConfig.text then
      return currentConfig.text
    end
  end

  -- 3) fallback: skan katalogu /bot
  local configs = g_resources.listDirectoryFiles("bot", false, true)
  for _, config in ipairs(configs) do
    if g_resources.directoryExists("bot/" .. config .. "/vBot") then
      return config
    end
  end

  return "default"
end

local configName = detectConfigName()
--warn("Using config: " .. configName)

-- Foldery
local vBotFolder     = "bot/" .. configName .. "/vBot"
local configFolder   = "bot/" .. configName
local storageFolder  = "bot/" .. configName .. "/storage"
local cavebotFolder  = "bot/" .. configName .. "/cavebot"
local targetbotFolder= "bot/" .. configName .. "/targetbot"
local updaterFolder  = configFolder -- file_lists.lua w tym folderze

-- Usuwanie profili + storage.json
local function removeProfileFiles()
  local removedCount = 0

  -- 0) wyczyść runtime storage skryptów, żeby po chwili nie “wróciło”
  storage = {}

  -- 1) standardowe profile w /storage/
  local profileFiles = {"profile_1.json","profile_2.json","profile_3.json","profile_4.json","profile_5.json"}
  for _, filename in ipairs(profileFiles) do
    local profilePath = storageFolder .. "/" .. filename
    if g_resources.fileExists(profilePath) then
      -- nadpisanie pustym jest pewniejsze niż delete (bot/klient potrafi odtworzyć plik)
      if g_resources.writeFileContents(profilePath, "{}") then
        removedCount = removedCount + 1
        warn("Wiped: " .. profilePath)
      end
    end
  end

  -- 2) alternatywny zapis: bot/<configName>/storage.json
  local altStorage = configFolder .. "/storage.json"
  if g_resources.fileExists(altStorage) then
    if g_resources.writeFileContents(altStorage, "{}") then
      removedCount = removedCount + 1
      warn("Wiped: " .. altStorage)
    end
  end

  return removedCount
end

-- Zapis pliku
local function saveFile(path, content)
    local folderPath = path:match("(.+)/[^/]+$")
    if folderPath and not g_resources.directoryExists(folderPath) then
        g_resources.makeDir(folderPath)
    end
    return g_resources.writeFileContents(path, content)
end

-- Pobieranie plików sekwencyjnie
local function downloadFilesSequential(fileList, urlBase, folder, updatedFiles, onComplete)
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
        
        HTTP.get(url, function(content, err)
            if not err and content and content ~= "" then
                if saveFile(localPath, content) then
                    table.insert(updatedFiles, filename)
                end
            end
            
            index = index + 1
            nextFile()
        end)
    end
    nextFile()
end

-- Funkcja aktualizacji wszystkich grup po pobraniu file_lists.lua
local function runSequentialUpdate(fileLists)
    local updatedFiles = {}
    local fileGroups = {
        {list = fileLists.vBotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/vBot/", folder = vBotFolder},
        {list = fileLists.mainFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/", folder = configFolder},
        {list = fileLists.cavebotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/cavebot/", folder = cavebotFolder},
        {list = fileLists.targetbotFiles, url = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/targetbot/", folder = targetbotFolder}
    }

    -- Tworzenie brakujących folderów
    for _, group in ipairs(fileGroups) do
        if not g_resources.directoryExists(group.folder) then
            g_resources.makeDir(group.folder)
        end
    end

    local groupIndex = 1
    local totalGroups = #fileGroups

    local function processNextGroup()
        if groupIndex > totalGroups then
            updateInProgress = false
            if #updatedFiles > 0 then
                warn("Update done. Files updated: " .. #updatedFiles)
                warn("Restart bot to apply changes.")
            else
                warn("All files up to date.")
            end
            return
        end

        local group = fileGroups[groupIndex]
        local groupName = group.folder:match("[^/]+$")
        warn("Processing: " .. groupName .. " (" .. #group.list .. " files)")

        groupIndex = groupIndex + 1
        downloadFilesSequential(group.list, group.url, group.folder, updatedFiles, processNextGroup)
    end

    warn("Starting update...")
    processNextGroup()
end

-- Główna funkcja updater
local function runUpdateAll()
    if updateInProgress then
        warn("Update in progress!")
        return
    end

    updateInProgress = true
    local fileListsPath = updaterFolder .. "/file_lists.lua"
    local fileListsUrl  = "https://raw.githubusercontent.com/GresQu/BotGresqu/refs/heads/main/file_lists.lua"

    warn("Downloading latest file_lists.lua...")
    HTTP.get(fileListsUrl, function(content, err)
        if err or not content or content == "" then
            warn("Failed to download file_lists.lua: " .. tostring(err))
            updateInProgress = false
            return
        end

        saveFile(fileListsPath, content)
        warn("file_lists.lua updated")

        -- Wczytanie dynamiczne przez loadstring
        local f, errLoad = loadstring(content)
        if not f then
            warn("Failed to load file_lists.lua: " .. tostring(errLoad))
            updateInProgress = false
            return
        end

        local ok, fileLists = pcall(f)
        if not ok or type(fileLists) ~= "table" then
            warn("file_lists.lua did not return a table")
            updateInProgress = false
            return
        end

        -- Uruchomienie update wszystkich plików
        runSequentialUpdate(fileLists)
    end)
end

-- UI Buttons
UI.Button("Update All", runUpdateAll)

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
