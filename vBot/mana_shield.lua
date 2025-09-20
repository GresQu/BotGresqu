local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

local lastManaShield = 0

macro(100, "mana shield", function() 
  if hasManaShield() or lastManaShield + 1000 > now then 
    return 
  end
  
  say("chakra barrier")
  lastManaShield = now
end)
