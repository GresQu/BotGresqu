setDefaultTab("Main")

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

-- Ustaw domyślną pozycję ikony TYLKO jeśli nie ma wpisu w storage._icons
storage._icons = storage._icons or {}
local function ensureIconPos(name, x, y)
  storage._icons[name] = storage._icons[name] or {}
  local rec = storage._icons[name]
  if rec.x == nil or rec.y == nil then
    rec.x = x
    rec.y = y
  end
end
-- Domyślne współrzędne dla pierwszego uruchomienia (nie nadpisują istniejących)
ensureIconPos("Attack Low", 0.072739632902787, 0.63179347826087)

smartertarg = macro(300, "Attack Low", function()
  if isInPz() then return end
  -- if not g_game.isAttacking() then return end

  local monsterPriorities = {
    ["[General Grade] Ant Shadow"] = 1
  }

  -- Load priorities from storage if provided
  if storage.monsterPrioritiesList and #storage.monsterPrioritiesList > 0 then
    monsterPriorities = {}
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

  local defaultPriority = math.huge
  local bestTarget = nil
  local bestPriorityFound = defaultPriority
  local lowestHpAtBestPriority = 101

  local currentTarget = g_game.getAttackingCreature()
  if currentTarget and currentTarget:isPlayer() then return end

  for _, val in pairs(getSpectators()) do
    if val:isMonster() and val:canShoot() and tonumber(storage.distance_attack_smart_high) then
      if getDistanceBetween(player:getPosition(), val:getPosition()) <= tonumber(storage.distance_attack_smart_high) then
        if val:isPlayer() then goto continue_spectator_loop end

        local nameExact = val:getName():trim()
        local nameLower = nameExact:lower()

        local isIgnored = false
        if storage.ignoreCreatures then
          local ignoreList = string.split(storage.ignoreCreatures, ",")
          for _, ignoredEntry in ipairs(ignoreList) do
            if nameLower:find(ignoredEntry:lower():trim(), 1, true) then
              isIgnored = true
              break
            end
          end
        end

        if not isIgnored then
          local prio = monsterPriorities[nameExact] or defaultPriority
          local hp = val:getHealthPercent()

          if prio < bestPriorityFound then
            bestPriorityFound = prio
            lowestHpAtBestPriority = hp
            bestTarget = val
          elseif prio == bestPriorityFound and hp < lowestHpAtBestPriority then
            lowestHpAtBestPriority = hp
            bestTarget = val
          end
        end
      end
    end
    ::continue_spectator_loop::
  end

  if bestTarget and (not g_game.isAttacking() or g_game.getAttackingCreature() ~= bestTarget) then
    g_game.attack(bestTarget)
  end
end)

-- === AdvancedSpellCaster-style controller (jedna prawda stanu) ===

storage.smartertargOn = storage.smartertargOn == true
local smartInitDone = false

local function smartUpdateIcon()
  if not smartertargIcon then return end
  local on = storage.smartertargOn
  smartertargIcon:setOn(on)
  smartertargIcon.text:setColoredText({ "Attack Low", on and "green" or "white" })
end

local function smartSetEnabled(on)
  on = not not on
  storage.smartertargOn = on
  if on then smartertarg:setOn() else smartertarg:setOff() end
  smartUpdateIcon()
end

local function smartToggle()
  smartSetEnabled(not storage.smartertargOn)
end

smartertargIcon = addIcon("Attack Low", {
  item = { id = 7995 },
  text = "Attack Low",
  movable = true,
  switchable = true
}, function()
  if not smartInitDone then return end
  smartToggle()
end)

smartertargIcon:setSize({ height = 60, width = 55 })
smartertargIcon.text:setFont('verdana-11px-rounded')

-- Initial sync after load
schedule(10, function()
  smartSetEnabled(storage.smartertargOn)
  smartInitDone = true
end)

-- Watcher: sync when toggled from Macro list
macro(200, function()
  local on = smartertarg.isOn()
  if on ~= storage.smartertargOn then
    smartSetEnabled(on)
  else
    smartUpdateIcon()
  end
end)
