local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- Wyłącza TargetBota i CaveBota albo włącza
local function setTargetAndCave(boolean)
  TargetBot.setOn(boolean)
  CaveBot.setOn(boolean)
end


-- Główna funkcja atakująca graczy spoza listy friends
attackPVP = macro(1000, "Attack Players", function()
  if isInPz() then return end

  local targetPlayer
  local lowestHp = 100

  for i, creature in ipairs(getSpectators(posz(), false)) do
    if creature:isPlayer() then
      -- Check if the player has a specific shield/emblem
      if creature:getEmblem() == 1 or creature:getEmblem() == 4 or creature:getShield() == 3 or creature:getShield() == 4 then
        -- Skip this player if they have a protected shield/emblem
        -- print("Player " .. creature:getName() .. " has a protected shield/emblem and will not be targeted by Attack_All.")
      else
        local cname = creature:getName()
        if cname:lower() ~= name():lower() and not isFriend(cname) then -- Use isFriend from vlib
          if creature:getHealthPercent() <= lowestHp then
            lowestHp = creature:getHealthPercent()
            targetPlayer = creature
          end
        end
      end
    end
  end

  if targetPlayer then
    if not g_game.isAttacking() or g_game.getAttackingCreature() ~= targetPlayer then
      g_game.setChaseMode(1)
      setTargetAndCave(false)
	g_game.attack(targetPlayer)
	local currentTarget = g_game.getAttackingCreature()
	if currentTarget and currentTarget:isMonster() then
		g_game.cancelAttack()
	end
    end
  else
    g_game.setChaseMode(0)
    setTargetAndCave(true)
  end
end)
