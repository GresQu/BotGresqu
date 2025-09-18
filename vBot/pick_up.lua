local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local c = {
  pickUp = {},
  CheckPOS = 1
}

-- Funkcja do parsowania ID z pola tekstowego
local function parseItemIDs(text)
  local list = {}
  for id in string.gmatch(text, "%d+") do
    table.insert(list, tonumber(id))
  end
  return list
end

-- Tworzymy makro z dołączonym UI
macro(200, "Pick_UP", function()
  c.pickUp = parseItemIDs(storage.pickUpIDs or "2")
  
  for x = -c.CheckPOS, c.CheckPOS do
    for y = -c.CheckPOS, c.CheckPOS do
      local tile = g_map.getTile({x = posx() + x, y = posy() + y, z = posz()})
      if tile then
        local things = tile:getThings()
        for _, item in pairs(things) do
          if table.find(c.pickUp, item:getId()) then
            local containers = getContainers()
            for _, container in pairs(containers) do
              g_game.move(item, container:getSlotPosition(container:getItemsCount()), item:getCount())
            end
          end
        end
      end
    end
  end
end)

-- Dodajemy UI do makra
UI.TextEdit(storage.pickUpIDs or "2160,2152,3035,3043,3031,2148", function(widget, text)
	widget:setTooltip("Items to pick up (IDs separated by commas)\neg: '2160,2152,3035'")
	storage.pickUpIDs = text
end)
