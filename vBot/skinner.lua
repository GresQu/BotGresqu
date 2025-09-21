-- Ustawienia domyślne
if not storage.useItemID then storage.useItemID = "24118" end
if not storage.corpseIDs then storage.corpseIDs = "4181" end
if not storage.corpseCheckRange then storage.corpseCheckRange = 1 end

local COOLDOWN_MS = 500
local lastUseTime = 0

-- UI: ID itemku (narzędzia np. nóż)
UI.TextEdit(storage.useItemID, function(widget, text)
  widget:setTooltip("ID itemka do użycia na zwłokach (np. 24118 = obsidian knife)")
  storage.useItemID = text
end)

-- UI: ID zwłok (corpse ID)
UI.TextEdit(storage.corpseIDs, function(widget, text)
  widget:setTooltip("ID zwłok oddzielone przecinkami (np. 4181,3058,3060)")
  storage.corpseIDs = text
end)

-- UI: Zasięg pola (CheckPOS)
UI.TextEdit(storage.corpseCheckRange, function(widget, text)
  widget:setTooltip("Zasięg sprawdzania w polach (np. 1 = 3x3 wokół postaci)")
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

-- Główne makro
macro(COOLDOWN_MS, "Corpse Skinner", function()
  local pos = player:getPosition()
  if not pos then return end

  if now < (lastUseTime + COOLDOWN_MS) then return end

  local useItemID = tonumber(storage.useItemID)
  local corpseIDs = parseIDs(storage.corpseIDs)
  local checkRange = tonumber(storage.corpseCheckRange) or 1

  local toolItem = findItemInContainers(useItemID)
  if not toolItem then return end

  for dx = -checkRange, checkRange do
    for dy = -checkRange, checkRange do
      local checkPos = { x = pos.x + dx, y = pos.y + dy, z = pos.z }
      local tile = g_map.getTile(checkPos)
      if tile then
        local items = tile:getItems() or {}
        for _, item in ipairs(items) do
          if table.find(corpseIDs, item:getId()) then
            useWith(toolItem, item)
            lastUseTime = now
            return
          end
        end
      end
    end
  end
end)
