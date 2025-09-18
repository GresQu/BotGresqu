-- Configuration
local USE_ITEM_ID        = 24118                    -- ID of the item in your inventory (e.g. obsidian knife)
local DEAD_BODY_IDS      = { 4181 }                -- Add more corpse IDs here, e.g. 3058, 3060
local COOLDOWN_MS        = 500                   -- milliseconds between each scan+use cycle
local DANGER_THRESHOLD   = 2                      -- max allowed dangerous monsters nearby
local MONSTERS_TO_AVOID  = { "Spirit of Chaos", "Chaos Abomination" }
local CHECK_RANGE        = 1                      -- how many tiles out to scan
local RELATIVE_POSITIONS = {
    { x =  0, y =  0},
    { x = -1, y = -1}, { x = 0, y = -1}, { x = 1, y = -1},
    { x = -1, y =  0},                   { x = 1, y =  0},
    { x = -1, y =  1}, { x = 0, y =  1}, { x = 1, y =  1}
}

-- Count how many of the named monsters are within CHECK_RANGE of the player
local function countDangerousMonsters()
    local pos = player:getPosition()
    if not pos then return 0 end

    local spectators = g_map.getSpectators(pos, CHECK_RANGE, CHECK_RANGE, false)
    if not spectators then return 0 end

    local count = 0
    for _, creature in ipairs(spectators) do
        if creature:isMonster() then
            local name = creature:getName()
            for _, badName in ipairs(MONSTERS_TO_AVOID) do
                if name == badName then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

-- Main macro: every COOLDOWN_MS milliseconds
macro(COOLDOWN_MS, "UseOnCorpse", function()
    -- If too many dangerous monsters are nearby, skip this cycle
    if countDangerousMonsters() >= DANGER_THRESHOLD then
        return
    end

    local playerPos = player:getPosition()
    if not playerPos then return end

    -- Scan each relative tile for a corpse
    for _, offset in ipairs(RELATIVE_POSITIONS) do
        local checkPos = {
            x = playerPos.x + offset.x,
            y = playerPos.y + offset.y,
            z = playerPos.z
        }
        local tile = g_map.getTile(checkPos)
        if tile then
            local items = tile:getItems() or {}
            for _, groundItem in ipairs(items) do
                local id = groundItem:getId()
                -- Is this one of the corpse IDs?
                for _, corpseId in ipairs(DEAD_BODY_IDS) do
                    if id == corpseId then
                        -- Do we have our tool in inventory?
                        local invItem = findItem(USE_ITEM_ID)
                        if invItem then
                            useWith(invItem, groundItem)
                            return   -- used on one corpse this cycle, exit
                        end
                        -- otherwise keep scanning
                    end
                end
            end
        end
    end
end)

macro(100, "Spell on Low HP", function()
    local target = g_game.getAttackingCreature()
    if not target or not target:isPlayer() then return end

    local targetHP = target:getHealthPercent()
    local currentTime = os.time()

    if targetHP <= 20 and currentTime >= (buffCooldowns[GodBuff.spellName] or 0) then
        say(GodBuff.spellName)
        buffCooldowns[GodBuff.spellName] = currentTime + (GodBuff.cooldown or 0)
    end
end)

macro(500, "Auto Accept Task", function()
  local taskIdsString = "12,13,14" -- <- ID tasków do akceptacji, oddzielone przecinkami
  local scrollValue = 4000       -- <- wartość suwaka (np. ilość zabójstw)

  local root = g_ui.getRootWidget()
  if not root then return end

  -- Funkcja do podziału stringa na tabelę
  local function splitString(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
  end

  local taskIdsTable = splitString(taskIdsString, ",")

  for _, currentTaskId in ipairs(taskIdsTable) do
    -- Sprawdź, czy task już aktywny
    local tasksTracker = root:recursiveGetChildById("tasksTracker")
    if tasksTracker and tasksTracker:recursiveGetChildById(currentTaskId) then
      -- print("Task " .. currentTaskId .. " is already active.") -- Opcjonalny log
      goto next_task -- Przejdź do następnego taska w pętli
    end

    -- Znajdź tasksList
    local tasksList = root:recursiveGetChildById("tasksList")
    if not tasksList then return end -- Jeśli nie ma listy tasków, zakończ całe makro

    -- Szukaj nadrzędnego okna zawierającego scroll i startButton
    -- To trzeba robić w każdej iteracji, bo kontekst UI może się zmienić
    local taskWindow = tasksList:getParent()
    local scroll = nil
    local startButton = nil

    while taskWindow do
      scroll = taskWindow:recursiveGetChildById("scroll")
      startButton = taskWindow:recursiveGetChildById("start")
      if scroll and startButton then
        break -- znaleźliśmy właściwe okno
      end
      taskWindow = taskWindow:getParent()
    end

    if not taskWindow or not scroll or not startButton then
      -- print("Could not find task window elements for task " .. currentTaskId) -- Opcjonalny log
      goto next_task -- Przejdź do następnego taska, jeśli UI nie jest gotowe
    end

    -- Wyszukaj task o wskazanym ID
    local selectedTask = nil
    for _, child in ipairs(tasksList:getChildren()) do
      if child:getId() == currentTaskId then
        selectedTask = child
        break
      end
    end

    if not selectedTask then
      -- print("Task " .. currentTaskId .. " not found in the list.") -- Opcjonalny log
      goto next_task -- Przejdź do następnego taska
    end

    -- Wybierz task i ustaw wartość scrolla
    tasksList:focusChild(selectedTask)
    scroll:setValue(scrollValue)

    -- Kliknij start
    startButton:onClick()
    -- print("Attempted to start task " .. currentTaskId) -- Opcjonalny log
    -- Można dodać małe opóźnienie, jeśli UI potrzebuje czasu na reakcję
    -- vBot.sleep(100) -- Wymagałoby to dodania vBot.sleep jeśli nie istnieje

    ::next_task::
  end
end)



-- Makro co 2000ms
macro(2000, "Start Frost Cave if in area", function()
  -- Pozycja gracza
  local pos = pos()
  if not pos or pos.x < 819 or pos.x > 828 or pos.y < 814 or pos.y > 820 or pos.z ~= 5 then
    return
  end

  local root = g_ui.getRootWidget()
  if not root then return end

  local dungeonWindow = root:recursiveGetChildById("soloDungeonWindow")
  if not dungeonWindow then return end

  local tabBar = dungeonWindow:recursiveGetChildById("solodungeonTabBar")
  if not tabBar then return end

  local buttonsPanel = tabBar:recursiveGetChildById("buttonsPanel")
  if not buttonsPanel then return end

  local tabs = buttonsPanel:getChildren()
  if not tabs or #tabs < 3 then return end

  -- Kliknij 3. przycisk (Frost Cave), tylko raz
  if not storage._frostCaveTabClicked then
    local frostCaveTab = tabs[3]
    if frostCaveTab and frostCaveTab:getClassName() == "UIButton" then
      frostCaveTab:onClick()
      storage._frostCaveTabClicked = true
      return
    end
  end

  -- Znajdź widżet frostCave
  local frostCave = dungeonWindow:recursiveGetChildById("frostCave")
  if not frostCave then return end

  -- Szukamy przycisku "Start" w frostCave jako ostatniego UIButtona
  local buttons = frostCave:recursiveGetChildren()
  local startBtn = nil
  for _, widget in ipairs(buttons) do
    if widget:getClassName() == "UIButton" then
      startBtn = widget -- przypisuje ostatni znaleziony
    end
  end

  if startBtn then
    startBtn:onClick()
    storage._frostCaveTabClicked = false
  end
end)


