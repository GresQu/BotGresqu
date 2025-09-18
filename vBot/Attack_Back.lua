local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local macroName = "Fight_Back" -- macro name
local pauseTarget = true -- pause targetbot
local pauseCave = true -- pause cavebot
local followTarget = true -- set chase mode to follow


local st = "AutoRevide"
storage[st] = storage[st] or {
    pausedTarget = false,
    pausedCave = false
}

local c_storage = storage[st]
local target = nil
Fight_Back = macro(250,macroName, function()
  if not target then
    if c_storage.pausedTarget then
      c_storage.pausedTarget = false
      TargetBot.setOn()
    end
    if c_storage.pausedCave then
      c_storage.pausedCave = false
      CaveBot.setOn()
    end
    return
  end

  local creature = getPlayerByName(target)
  if not creature then target = nil return end
  if pauseTargetBot then -- Assuming pauseTargetBot is a global or defined elsewhere
    c_storage.pausedTarget = true
    TargetBot.setOff()
  end
  if pauseTarget then
    c_storage.pausedTarget = true
    TargetBot.setOff()
  end
  if pauseCave then
    c_storage.pausedCave = true
    CaveBot.setOff()
  end

  if followTarget then
    g_game.setChaseMode(2)
  end

  if g_game.isAttacking() then
    if g_game.getAttackingCreature():getName() == target then
      return
    end
  end
  g_game.attack(creature)
end)

onTextMessage(function(mode, text)
  if Fight_Back:isOff() then return end
  if not text:find('hitpoints due to an attack by') then return end
  local p_regex = 'You lose (%d+) hitpoints due to an attack by (.+)%.' -- Renamed 'p' to 'p_regex'
  local hp, attacker = text:match(p_regex)
  local creature_attacker = getPlayerByName(attacker) -- Renamed 'c' to 'creature_attacker'
  if not creature_attacker then return end

  -- Check if the attacker is a player
  if creature_attacker:isPlayer() then
    if isFriend(creature_attacker) then -- Check if the attacker is a friend
      -- print("Player " .. creature_attacker:getName() .. " is a friend and will not be auto-attacked.")
      return -- Do not set as target
    end
    -- Check if the player has a specific shield/emblem
    if (creature_attacker:getEmblem() == 1 or creature_attacker:getEmblem() == 4 or creature_attacker:getShield() == 3 or creature_attacker:getShield() == 4) then
      -- Log or print a message that this player will not be targeted (optional)
      -- print("Player " .. creature_attacker:getName() .. " has a protected shield/emblem and will not be auto-attacked.")
      return -- Do not set as target
    end
  end

  target = creature_attacker:getName()
end)