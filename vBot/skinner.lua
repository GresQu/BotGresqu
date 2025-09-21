-- Ustawienia domyślne
if not storage.useItemID then storage.useItemID = "127" end
if not storage.corpseIDs then storage.corpseIDs = "3994" end
if not storage.corpseCheckRange then storage.corpseCheckRange = 1 end

local COOLDOWN_MS = 500
local lastUseTime = 0

-- UI: ID itemku (narzędzia np. nóż)
UI.TextEdit(storage.useItemID, function(widget, text)
	widget:setTooltip("ID of the item to use on corpses (e.g., 24118 = obsidian knife)")
	storage.useItemID = text
end)

-- UI: ID zwłok (corpse ID)
UI.TextEdit(storage.corpseIDs, function(widget, text)
	widget:setTooltip("IDs of corpses, separated by commas (e.g., 4181,3058,3060)")
	storage.corpseIDs = text
end)

-- UI: Zasięg pola (CheckPOS)
UI.TextEdit(storage.corpseCheckRange, function(widget, text)
	widget:setTooltip("Check range in tiles around the player (e.g., 1 = 3x3 area)")
	local value = tonumber(text)
	if value then storage.corpseCheckRange = value end
end)

-- Pomocnicza funkcja do parsowania ID z tekstu
local function parseIDs(text)
  local list = {}
  for id in string.gmatch(text, "[0-9]+") do
    table.insert(list, tonumber(id))
  end
  return list
end

-- Pomocnicza funkcja do znalezienia itemu w plecaku jako obiekt Item
local function findItemInContainers(id)
  for _, container in pairs(getContainers()) do
    for __, item in ipairs(container:getItems()) do
      if item:getId() == id then
        return item
      end
    end
  end
  return nil
end

-- Główne makro z debugami
macro(COOLDOWN_MS, "Corpse Skinner", function()
  local pos = player:getPosition()
  if not pos then return end

  -- Odczekaj między użyciami (cooldown)
  if now < (lastUseTime + COOLDOWN_MS) then return end

  local useItemID = tonumber(storage.useItemID)
  local corpseIDs = parseIDs(storage.corpseIDs)
  local checkRange = tonumber(storage.corpseCheckRange) or 1

  -- Znajdź narzędzie w plecaku
  local toolItem = findItemInContainers(useItemID)
  if not toolItem then
  --  print("[CorpseSkinner] Nie znaleziono itemu o ID:", useItemID)
    return
  end

--  print(string.format("[CorpseSkinner] Znaleziono item: ID=%d, pos=%s", toolItem:getId(), posx() .. "," .. posy() .. "," .. posz()))

  -- Przeszukiwanie terenu wokół gracza
  for dx = -checkRange, checkRange do
    for dy = -checkRange, checkRange do
      local checkPos = { x = pos.x + dx, y = pos.y + dy, z = pos.z }
      local tile = g_map.getTile(checkPos)
      if tile then
        local items = tile:getItems() or {}
        if #items > 0 then
       --   print(string.format("[CorpseSkinner] Skanuję pozycję: %d,%d,%d - %d itemów", checkPos.x, checkPos.y, checkPos.z, #items))
        end
        for _, item in ipairs(items) do
          local itemId = item:getId()
          if table.find(corpseIDs, itemId) then
         --   print(string.format("[CorpseSkinner] Znaleziono zwłoki: ID=%d na pozycji %d,%d,%d", itemId, checkPos.x, checkPos.y, checkPos.z))
           -- print(string.format("[CorpseSkinner] Używam itemu ID=%d na zwłokach ID=%d", toolItem:getId(), itemId))
            useWith(toolItem, item)
            lastUseTime = now
            return
          end
        end
      end
    end
  end

  -- Jeśli nie znalazło zwłok
  -- print("[CorpseSkinner] Nie znaleziono zwłok do użycia itemu.")
end)
