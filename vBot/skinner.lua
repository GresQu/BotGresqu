setDefaultTab("Tools")

-- Domyślne wartości
if not storage.useItemID then storage.useItemID = "24118" end
if not storage.corpseIDs then storage.corpseIDs = "4181" end
if not storage.corpseCheckRange then storage.corpseCheckRange = 1 end

local COOLDOWN_MS = 500

-- UI: ID itemka
UI.TextEdit(storage.useItemID, function(widget, text)
  widget:setTooltip("ID itemka do użycia na zwłokach\nnp: 24118")
  storage.useItemID = text
end)

-- UI: ID zwłok
UI.TextEdit(storage.corpseIDs, function(widget, text)
  widget:setTooltip("ID zwłok, oddzielone przecinkami\nnp: 4181,3058,3060")
  storage.corpseIDs = text
end)

-- UI: Zasięg (CheckPOS)
UI.TextEdit(storage.corpseCheckRange, function(widget, text)
  widget:setTooltip("Zasięg sprawdzania zwłok (w polach SQM wokół postaci)\nnp: 1 = 3x3, 2 = 5x5")
  local value = tonumber(text)
  if value then storage.corpseCheckRange = value end
end)

-- Parser tekstu
local function parseIDs(text)
  local list = {}
  for id in string.gmatch(text, "[0-9]+") do
    table.insert(list, tonumber(id))
  end
  return list
end

-- Główne makro
macro(COOLDOWN_MS, "Use on Corpses [dynamic range]", function()
  local pos = player:getPosition()
  if not pos then return end

  local useItemID = tonumber(storage.useItemID)
  local corpseIDs = parseIDs(storage.corpseIDs)
  local checkRange = tonumber(storage.corpseCheckRange) or 1

  if not useItemID or #corpseIDs == 0 then
    print("[CorpseMacro] Błędne ID itemka lub zwłok")
    return
  end

  -- Przeszukaj wszystkie pola w zakresie -checkRange do +checkRange
  for dx = -checkRange, checkRange do
    for dy = -checkRange, checkRange do
      if dx ~= 0 or dy ~= 0 then -- pomiń pole postaci
        local checkPos = {
          x = pos.x + dx,
          y = pos.y + dy,
          z = pos.z
        }

        local tile = g_map.getTile(checkPos)
        if tile then
          local items = tile:getItems() or {}
          for _, item in ipairs(items) do
            if table.find(corpseIDs, item:getId()) then
              print(string.format("[CorpseMacro] Skórowanie ID %d @ (%d,%d)", item:getId(), checkPos.x, checkPos.y))
              useOnGroundItem(useItemID, checkPos)
              return -- tylko jedno użycie na cykl
            end
          end
        end
      end
    end
  end
end)
