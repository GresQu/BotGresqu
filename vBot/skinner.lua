-- Ustawienia
if not storage.useItemID then storage.useItemID = "127" end
if not storage.corpseIDs then storage.corpseIDs = "3994" end  
if not storage.corpseRange then storage.corpseRange = 1 end

local COOLDOWN_MS = 500
local lastUseTime = 0

-- UI z tooltipami
UI.TextEdit(storage.useItemID, function(widget, text)
    widget:setTooltip("ID of the tool item (e.g., 24118 = obsidian knife)")
    storage.useItemID = text
end)

UI.TextEdit(storage.corpseIDs, function(widget, text)
    widget:setTooltip("Corpse IDs separated by commas (e.g., 4181,3058,3060)")
    storage.corpseIDs = text
end)

UI.TextEdit(storage.corpseRange, function(widget, text)
    widget:setTooltip("Search range in tiles around player (1 = 3x3 area)")
    local value = tonumber(text)
    if value then storage.corpseRange = value end
end)

-- Znajdź item w plecaku
local function findItem(id)
    for _, container in pairs(getContainers()) do
        for __, item in ipairs(container:getItems()) do
            if item:getId() == id then
                return item
            end
        end
    end
    return nil
end

-- Parsuj IDs
local function parseIDs(text)
    local list = {}
    for id in string.gmatch(text, "[0-9]+") do
        table.insert(list, tonumber(id))
    end
    return list
end

-- Główne makro
macro(COOLDOWN_MS, "Corpse Skinner", function()
    if now < (lastUseTime + COOLDOWN_MS) then return end
    
    local pos = player:getPosition()
    if not pos then return end
    
    local toolItem = findItem(tonumber(storage.useItemID))
    if not toolItem then return end
    
    local corpseIDs = parseIDs(storage.corpseIDs)
    local range = tonumber(storage.corpseRange) or 1
    
    for dx = -range, range do
        for dy = -range, range do
            local checkPos = { x = pos.x + dx, y = pos.y + dy, z = pos.z }
            local tile = g_map.getTile(checkPos)
            
            if tile then
                for _, item in ipairs(tile:getItems() or {}) do
                    if table.find(corpseIDs, item:getId()) then
                        g_game.useWith(toolItem, item)
                        lastUseTime = now
                        return
                    end
                end
            end
        end
    end
end)
