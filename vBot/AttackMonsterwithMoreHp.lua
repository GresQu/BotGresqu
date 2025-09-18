setDefaultTab("Main")
AttackMonsterWithMore = macro(300, "Attack High", function()
  if isInPz() then return end
  -- if not g_game.isAttacking() then return end

  local currentTarget = g_game.getAttackingCreature()
  if currentTarget and currentTarget:isPlayer() then return end
  local highestAmount = currentTarget and currentTarget:getHealthPercent() or 0
  local mob
  for _, val in pairs(getSpectators()) do
    if val:isMonster() and val:canShoot() then
      -- Sprawdzamy, czy potwór jest na liście ignorowanych
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

      -- Jeśli potwór nie jest ignorowany, porównujemy HP
      if not isIgnored and not val:isPlayer() and tonumber(storage.distance_attack_smart_high) and getDistanceBetween(player:getPosition(), val:getPosition()) <= tonumber(storage.distance_attack_smart_high) then
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

AttackMonsterWithMoreIcon = addIcon("Attack High", {
  item = {id = 7995},
  text = "Attack High",
  movable = true
}, function(icon, isOn)
  icon.text:setColoredText({
    "Attack High", isOn and "green" or "white"
  })
  AttackMonsterWithMore.setOn(isOn)
end)

AttackMonsterWithMoreIcon:setSize({height = 60, width = 60})
AttackMonsterWithMoreIcon.text:setFont('verdana-11px-rounded')


UI.TextEdit(storage.distance_attack_smart_high or "2", function(widget, newText)
  storage.distance_attack_smart_high = newText
end)
