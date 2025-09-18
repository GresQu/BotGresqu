setDefaultTab("Main")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

smartertarg = macro(300, "Attack Low", function()
  if isInPz() then return end
  -- if not g_game.isAttacking() then return end

  local monsterPriorities = {
    ["[General Grade] Ant Shadow"] = 1
  }

  -- Clear the hardcoded examples if we are loading from storage, or initialize if not.
  if storage.monsterPrioritiesList and #storage.monsterPrioritiesList > 0 then
    monsterPriorities = {} -- Clear examples if loading from storage
    local priorityEntries = string.split(storage.monsterPrioritiesList, ",")
    for _, entry in ipairs(priorityEntries) do
      local parts = string.split(entry, ":")
      if #parts == 2 then
        local name = parts[1]:trim()
        local priority = tonumber(parts[2]:trim())
        if name and #name > 0 and priority then
          monsterPriorities[name] = priority
        end
      end
    end
  end
  local defaultPriority = math.huge -- For monsters not in the list

  local bestTarget = nil
  local bestPriorityFound = defaultPriority
  local lowestHpAtBestPriority = 101 -- Start higher than max HP percentage

  local currentTarget = g_game.getAttackingCreature()
  if currentTarget and currentTarget:isPlayer() then return end

  for _, val in pairs(getSpectators()) do
    if val:isMonster() and val:canShoot() and tonumber(storage.distance_attack_smart_high) then
      if getDistanceBetween(player:getPosition(), val:getPosition()) <= tonumber(storage.distance_attack_smart_high) then
        if val:isPlayer() then goto continue_spectator_loop end -- Skip players

        local monsterNameForPriority = val:getName():trim() -- Use exact name for priority lookup
        local monsterNameForIgnore = monsterNameForPriority:lower() -- Use lowercased name for ignore list

        local isIgnored = false
        if storage.ignoreCreatures then
          local ignoreList = string.split(storage.ignoreCreatures, ",")
          for _, ignoredEntry in ipairs(ignoreList) do
            if monsterNameForIgnore:find(ignoredEntry:lower():trim(), 1, true) then
              isIgnored = true
              break
            end
          end
        end

        if not isIgnored then
          local currentMonsterPriority = monsterPriorities[monsterNameForPriority] or defaultPriority
          local currentMonsterHp = val:getHealthPercent()

          if currentMonsterPriority < bestPriorityFound then
            -- New best priority found
            bestPriorityFound = currentMonsterPriority
            lowestHpAtBestPriority = currentMonsterHp
            bestTarget = val
          elseif currentMonsterPriority == bestPriorityFound then
            -- Same priority, check HP
            if currentMonsterHp < lowestHpAtBestPriority then
              lowestHpAtBestPriority = currentMonsterHp
              bestTarget = val
            end
          end
        end
      end
    end
    ::continue_spectator_loop::
  end

  local mob = bestTarget
  if mob then
    if not g_game.isAttacking() or g_game.getAttackingCreature() ~= mob then
      g_game.attack(mob)
    end
  end
end)

smartertargIcon = addIcon("Attack Low", {
  item = {id = 7995},
  text = "Attack Low",
  movable = true
}, function(icon, isOn)
  icon.text:setColoredText({
    "Attack Low", isOn and "green" or "white"
  })
  smartertarg.setOn(isOn)
end)

smartertargIcon:setSize({height = 60, width = 55})
smartertargIcon.text:setFont('verdana-11px-rounded')
