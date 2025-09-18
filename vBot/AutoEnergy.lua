setDefaultTab("Tools")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
function hasEffect(tile, effect)
  for i, fx in ipairs(tile:getEffects()) do
    if fx:getId() == effect then
      return true
    end
  end
  return false
end

macro(500, "Auto_Energy Wodbo", function()
 for _, tile in pairs(g_map.getTiles(posz())) do
   if (hasEffect(tile, 16)) then  -- zmien effect id na energy ten effekt co jest w ene roomie
   tile:setText("Effect")
 end
if tile and tile:getText() == "Effect" then
 CaveBot.delay(500)
  autoWalk(tile:getPosition(), 100, { ignoreNonPathable = true });
  schedule(2000, function() tile:setText("") end)
  end
 end
end)
