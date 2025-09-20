local lastManaShield = 0

macro(100, "mana shield", function() 
  if hasManaShield() or lastManaShield + 20000 > now then 
    return 
  end
  
  say("chakra barrier")
  lastManaShield = now
end)