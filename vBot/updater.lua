local HTTP = modules._G.HTTP
-- Funkcja wykrywająca aktualny config
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
-- Foldery docelowe
local vBotFolder = "bot/" .. configName .. "/vBot"
local configFolder = "bot/" .. configName
local storageFolder = "bot/" .. configName .. "/storage"
local cavebotFolder = "bot/" .. configName .. "/cavebot"
local targetbotFolder = "bot/" .. configName .. "/targetbot"
-- Funkcja zapisująca plik tylko jeśli zawartość się różni
local function saveFile(path, content)
  local folderPath = path:match("(.+)/[^/]+$") -- ścieżka bez nazwy pliku
  if folderPath and not g_resources.directoryExists(folderPath) then
    g_resources.makeDir(folderPath)
  end
  if g_resources.fileExists(path) then
    local existingContent = g_resources.readFileContents(path)
    if existingContent == content then
      print("ℹ️ File is already up to date: " .. path)
      return
    end
  end
  local success = g_resources.writeFileContents(path, content)
  if success then
    print("✅ Saved: " .. path)
  else
    print("❌ Save error: " .. path)
  end
end
-- Lista plików vBot
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

-- Lista plików do głównego folderu configu
local mainFiles = { "_Loader.lua" }

-- Lista plików storage
local storageFiles = { "profile_1.json" }

-- Lista plików cavebot
local cavebotFiles = {
  "actions.lua", "cavebot.lua", "cavebot.otui", "clear_tile.lua",
  "config.lua", "config.otui", "doors.lua", "editor.lua",
  "editor.otui", "example_functions.lua", "extension_template.lua",
  "lure.lua", "minimap.lua", "pos_check.lua", "recorder.lua",
  "stand_lure.lua", "travel.lua", "walking.lua"
}

-- Lista plików targetbot
local targetbotFiles = {
  "creature.lua", "creature_attack.lua", "creature_editor.lua", "creature_editor.otui",
  "creature_priority.lua", "looting.lua", "looting.otui", "target.lua", "target.otui", "walking.lua"
}
-- Funkcja pobierająca pliki
local function downloadFiles(fileList, urlBase, folder)
  for _, filename in ipairs(fileList) do
    local url = urlBase .. filename
    local localPath = folder .. "/" .. filename
    HTTP.get(url, function(content, err)
      if err then
        print("❌ Download error " .. filename .. ": " .. err)
      else
        saveFile(localPath, content)
      end
    end)
  end
end
-- Funkcje aktualizacji
local function updateAll()
  downloadFiles(vBotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/vBot/", vBotFolder)
  downloadFiles(mainFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/", configFolder)
  downloadFiles(storageFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/storage/", storageFolder)
  downloadFiles(cavebotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/cavebot/", cavebotFolder)
  downloadFiles(targetbotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/targetbot/", targetbotFolder)
end

local function updateWithoutStorage()
  downloadFiles(vBotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/vBot/", vBotFolder)
  downloadFiles(mainFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/", configFolder)
  -- skipping storageFiles
  downloadFiles(cavebotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/cavebot/", cavebotFolder)
  downloadFiles(targetbotFiles, "https://raw.githubusercontent.com/GresQu/BotGresqu/main/targetbot/", targetbotFolder)
end
-- Adding buttons with English labels
UI.Button("Update All", function()
  updateAll()
end)

UI.Button("Update Without Settings", function()
  updateWithoutStorage()
end)
