local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- Konfiguracja domyślna
if not storage.useItemID then
  storage.useItemID = "24118"
end
if not storage.corpseIDs then
  storage.corpseIDs = "4181"
end

local COOLDOWN_MS = 500 -- jak często sprawdzać w ms

-- UI: pole do wpisania ID przedmiotu do użycia (np. obsidian knife)
UI.TextEdit(storage.useItemID, function(widget, text)
  widget:setTooltip("ID itemka do użycia na zwłokach\nnp: 24118")
  storage.useItemID = text
end)

-- UI: pole do wpisania ID zwłok (po przecinku)
UI.TextEdit(storage.corpseIDs, function(widget, text)
  widget:setTooltip("ID zwłok, oddzielone przecinkami\nnp: 4181,3058,3060")
  storage.corpseIDs = text
end)

-- Parser tekstu: "4181,3058" → {4181, 3058}
local function parseIDs(text)
  local list = {}
  for id in string.gmatch(text, "[0-9]+") do
    table.insert(list, tonumber(id))
  end
  return list
end

-- Pozycje do sprawdzania (1 sqm)
local RELATIVE_POSITIONS = {
    { x =  0, y =  0},
    { x = -1, y =  0},
    { x =  1, y =  0},
    { x =  0, y = -1},
    { x =  0, y =  1}
}

-- Główne makro
macro(COOLDOWN_MS, "Use on Corpse [UI]", function()
  local playerPos = player:getPosition()
  if not playerPos then return end

  local useItemID = tonumber(storage.useItemID)
  local corpseIDs = parseIDs(storage.corpseIDs)
  if not useItemID or #corpseIDs == 0 then return end

  local tool = findItem(useItemID)
  if not tool then return end

  for _, offset in ipairs(RELATIVE_POSITIONS) do
    local checkPos = {
      x = playerPos.x + offset.x,
      y = playerPos.y + offset.y,
      z = playerPos.z
    }
    local tile = g_map.getTile(checkPos)
    if tile then
      local items = tile:getItems() or {}
      for _, item in ipairs(items) do
        if table.find(corpseIDs, item:getId()) then
          useWith(tool, item)
          return -- użyto na jednej zwłoce
        end
      end
    end
  end
end)
