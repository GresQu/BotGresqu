setDefaultTab("Main")

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
ensureIconPos("Attack High", 0.070941336971351, 0.54891304347826)

AttackMonsterWithMore = macro(300, "Attack High", function()
  if isInPz() then return end
  -- if not g_game.isAttacking() then return end

  local currentTarget = g_game.getAttackingCreature()
  if currentTarget and currentTarget:isPlayer() then return end

  local highestAmount = currentTarget and currentTarget:getHealthPercent() or 0
  local mob

  for _, val in pairs(getSpectators()) do
    if val:isMonster() and val:canShoot() then
      local name = val:getName():trim():lower()
      local isIgnored = false

      if storage.ignoreCreatures then
        local ignoreList = string.split(storage.ignoreCreatures, ",")
        for _, ignored in ipairs(ignoreList) do
          if name:find(ignored:lower():trim(), 1, true) then
            isIgnored = true
            break
          end
        end
      end

      if not isIgnored
        and not val:isPlayer()
        and tonumber(storage.distance_attack_smart_high)
        and getDistanceBetween(player:getPosition(), val:getPosition()) <= tonumber(storage.distance_attack_smart_high) then

        local valHp = val:getHealthPercent()
        if valHp >= highestAmount then
          highestAmount = valHp
          mob = val
        end
      end
    end
  end

  if mob and (not g_game.isAttacking() or g_game.getAttackingCreature() ~= mob) then
    g_game.attack(mob)
  end
end)

-- === AdvancedSpellCaster-style controller (jedna prawda stanu) ===

storage.AttackMonsterWithMoreOn = storage.AttackMonsterWithMoreOn == true
local highInitDone = false

local function highUpdateIcon()
  if not AttackMonsterWithMoreIcon then return end
  local on = storage.AttackMonsterWithMoreOn
  AttackMonsterWithMoreIcon:setOn(on)
  AttackMonsterWithMoreIcon.text:setColoredText({ "Attack High", on and "green" or "white" })
end

local function highSetEnabled(on)
  on = not not on
  storage.AttackMonsterWithMoreOn = on
  if on then AttackMonsterWithMore:setOn() else AttackMonsterWithMore:setOff() end
  highUpdateIcon()
end

local function highToggle()
  highSetEnabled(not storage.AttackMonsterWithMoreOn)
end

AttackMonsterWithMoreIcon = addIcon("Attack High", {
  item = { id = 7995 },
  text = "Attack High",
  movable = true,
  switchable = true
}, function()
  if not highInitDone then return end
  highToggle()
end)

AttackMonsterWithMoreIcon:setSize({ height = 60, width = 60 })
AttackMonsterWithMoreIcon.text:setFont('verdana-11px-rounded')

-- Initial sync after load
schedule(10, function()
  highSetEnabled(storage.AttackMonsterWithMoreOn)
  highInitDone = true
end)

-- Watcher: sync when toggled from Macro list
macro(200, function()
  local on = AttackMonsterWithMore.isOn()
  if on ~= storage.AttackMonsterWithMoreOn then
    highSetEnabled(on)
  else
    highUpdateIcon()
  end
end)

UI.TextEdit(storage.distance_attack_smart_high or "2", function(widget, newText)
  storage.distance_attack_smart_high = newText
end)
