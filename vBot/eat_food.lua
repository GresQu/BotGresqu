setDefaultTab("HP")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
if voc() ~= 1 and voc() ~= 11 then
    if storage.foodItems then
        local t = {}
        for i, v in pairs(storage.foodItems) do
            if not table.find(t, v.id) then
                table.insert(t, v.id)
            end
        end
        local foodItems = {}
        for i, item in pairs(foodItems) do
            if not table.find(t, item) then
                table.insert(storage.foodItems, item)
            end
        end
    end
end

UI.Label("Eatable items:")
if type(storage.foodItems) ~= "table" then
  storage.foodItems = {}
end

local foodContainer = UI.Container(function(widget, items)
  storage.foodItems = items
end, true)
foodContainer:setHeight(35)
foodContainer:setItems(storage.foodItems)

macro(3000, "Eat Food", function()
  if player:getRegenerationTime() > 400 or not storage.foodItems[1] then return end
  -- search for food in containers
  for _, container in pairs(g_game.getContainers()) do
    for __, item in ipairs(container:getItems()) do
      for i, foodItem in ipairs(storage.foodItems) do
        if item:getId() == foodItem.id then
          return g_game.use(item)
        end
      end
    end
  end
end)