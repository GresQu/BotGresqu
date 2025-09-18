local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local panelName = "alarms"
local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Alarms')

  Button
    id: alerts
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Edit

]])
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
    enabled = false,
    playerAttack = false,
    playerDetected = false,
    playerDetectedLogout = false,
    creatureDetected = false,
    healthBelow = false,
    healthValue = 40,
    manaBelow = false,
    manaValue = 50,
    privateMessage = false,
    ignoreFriends = true,
    warnBoss = false,
    bossName = '[B]'
  }
end

local config = storage[panelName]
local lastPlayerAttackAlarmTime = 0 -- For 1-second cooldown on player attack alarms

ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
config.enabled = not config.enabled
widget:setOn(config.enabled)
end

-- new var's validation
config.messageText = config.messageText or ""
config.bossName = config.bossName or ""

rootWidget = g_ui.getRootWidget()
if rootWidget then
  alarmsWindow = UI.createWindow('AlarmsWindow', rootWidget)
  alarmsWindow:hide()

  alarmsWindow.closeButton.onClick = function(widget)
    alarmsWindow:hide()
  end

  alarmsWindow.playerAttack:setOn(config.playerAttack)
  alarmsWindow.playerAttack.onClick = function(widget)
    config.playerAttack = not config.playerAttack
    widget:setOn(config.playerAttack)
  end

  alarmsWindow.playerDetected:setOn(config.playerDetected)
  alarmsWindow.playerDetected.onClick = function(widget)
    config.playerDetected = not config.playerDetected
    widget:setOn(config.playerDetected)
  end

  alarmsWindow.playerDetectedLogout:setChecked(config.playerDetectedLogout)
  alarmsWindow.playerDetectedLogout.onClick = function(widget)
    config.playerDetectedLogout = not config.playerDetectedLogout
    widget:setChecked(config.playerDetectedLogout)
  end

  alarmsWindow.creatureDetected:setOn(config.creatureDetected)
  alarmsWindow.creatureDetected.onClick = function(widget)
    config.creatureDetected = not config.creatureDetected
    widget:setOn(config.creatureDetected)
  end

  alarmsWindow.healthBelow:setOn(config.healthBelow)
  alarmsWindow.healthBelow.onClick = function(widget)
    config.healthBelow = not config.healthBelow
    widget:setOn(config.healthBelow)
  end

  alarmsWindow.healthValue.onValueChange = function(scroll, value)
    config.healthValue = value
    alarmsWindow.healthBelow:setText("Health < " .. config.healthValue .. "%")  
  end
  alarmsWindow.healthValue:setValue(config.healthValue)

  alarmsWindow.manaBelow:setOn(config.manaBelow)
  alarmsWindow.manaBelow.onClick = function(widget)
    config.manaBelow = not config.manaBelow
    widget:setOn(config.manaBelow)
  end

  alarmsWindow.manaValue.onValueChange = function(scroll, value)
    config.manaValue = value
    alarmsWindow.manaBelow:setText("Mana < " .. config.manaValue .. "%")  
  end
  alarmsWindow.manaValue:setValue(config.manaValue)

  alarmsWindow.privateMessage:setOn(config.privateMessage)
  alarmsWindow.privateMessage.onClick = function(widget)
    config.privateMessage = not config.privateMessage
    widget:setOn(config.privateMessage)
  end

  alarmsWindow.ignoreFriends:setOn(config.ignoreFriends)
  alarmsWindow.ignoreFriends.onClick = function(widget)
    config.ignoreFriends = not config.ignoreFriends
    widget:setOn(config.ignoreFriends)
  end

  alarmsWindow.warnBoss:setOn(config.warnBoss)
  alarmsWindow.warnBoss.onClick = function(widget)
    config.warnBoss = not config.warnBoss
    widget:setOn(config.warnBoss)
  end

  alarmsWindow.bossName:setText(config.bossName)
  alarmsWindow.bossName.onTextChange = function(widget, text)
    config.bossName = text
  end

  alarmsWindow.warnMessage:setOn(config.warnMessage)
  alarmsWindow.warnMessage.onClick = function(widget)
    config.warnMessage = not config.warnMessage
    widget:setOn(config.warnMessage)
  end

  alarmsWindow.messageText:setText(config.messageText)
  alarmsWindow.messageText.onTextChange = function(widget, text)
    config.messageText = text
  end

  local pName = player:getName()
  onTextMessage(function(mode, text)
    -- Player Attack Alarm
    if config.enabled and config.playerAttack then
      local capturedPart = string.match(text, "You lose %d+ hitpoints due to an attack by (.*)")

      if capturedPart then
        local attackerString = capturedPart:gsub("%.?$", "") 
        local isMonsterAttack = false
        local actualAttackerName = attackerString

        if attackerString:sub(1, 2) == "a " then
          isMonsterAttack = true
        elseif attackerString:sub(1, 3) == "an " then
          isMonsterAttack = true
        else
          actualAttackerName = attackerString:trim() 
        end

        if not isMonsterAttack then
          local creature = getCreatureByName(actualAttackerName)
          if creature and creature:isPlayer() then
            local shouldIgnore = false
            if config.ignoreFriends and isFriend(creature) then
              shouldIgnore = true
            end

            if not shouldIgnore then
              if (now - lastPlayerAttackAlarmTime > 2000) then
                playSound("/sounds/Player_Attack.ogg")
                g_window.setTitle(pName .. " - Player Attack: " .. actualAttackerName)
                lastPlayerAttackAlarmTime = now
              end
              return 
            end
          end
        end
      end
    end

    -- Warn Message / Special Message check
    if config.warnMessage and config.messageText:len() > 0 then
      local text_lower = text:lower() 
      local parts = string.split(config.messageText, ",")
      for i=1,#parts do
        local part = parts[i]
        part = part:trim()
        part = part:lower()

        if text_lower:find(part) then
          delay(1500) 
          playSound(g_resources.fileExists("/sounds/Special_Message.ogg") and "/sounds/Special_Message.ogg" or "/sounds/Private_Message.ogg")
          g_window.setTitle(pName .. " - Special Message Detected: "..part)
          return
        end
      end
    end
  end)

  macro(100, function()
    if not config.enabled then
      return
    end
    local specs = getSpectators()
    if config.playerDetected then
      for i, spec in pairs(getSpectators()) do 
        if spec:isPlayer() and spec:getName() ~= name() then
          local specPos = spec:getPosition()
          if (not config.ignoreFriends or not isFriend(spec)) and math.max(math.abs(posx()-specPos.x), math.abs(posy()-specPos.y)) <= 8 then
            playSound("/sounds/Player_Detected.ogg")
            delay(1500)
            g_window.setTitle(pName .. " - Player Detected! "..spec:getName())
            if config.playerDetectedLogout then
              modules.game_interface.tryLogout(false)
            end
            return
          end
        end
      end
    end

    if config.creatureDetected then
      for _, spec in ipairs(specs) do
        if not spec:isPlayer() then
          local specPos = spec:getPosition()
          if math.max(math.abs(posx()-specPos.x), math.abs(posy()-specPos.y)) <= 8 then
            playSound("/sounds/Creature_Detected.ogg")
            delay(1500)
            g_window.setTitle(pName .. " - Creature Detected! "..spec:getName())
            return
          end
        end
      end
    end

    if config.warnBoss then
      if config.bossName:len() > 0 then
        local names = string.split(config.bossName, ",")
        local combinedString = ""
        for _, spec in ipairs(specs) do
          local specPos = spec:getPosition()
          if math.max(math.abs(posx() - specPos.x), math.abs(posy() - specPos.y)) <= 8 then
            local name_lower = spec:getName():lower() 
            combinedString = combinedString .."&"..name_lower
          end
        end
        for i=1,#names do
          local name_to_check = names[i] 
          name_to_check = name_to_check:trim()
          name_to_check = name_to_check:lower()

          if combinedString:find(name_to_check) then
            playSound(g_resources.fileExists("/sounds/Special_Creature.ogg") and "/sounds/Special_Creature.ogg" or "/sounds/Creature_Detected.ogg")
            delay(1500)
            g_window.setTitle(pName .. " - Special Creature Detected: "..name_to_check)
            return
          end

        end
      end
    end

    if config.healthBelow then
      if hppercent() <= config.healthValue then
        playSound("/sounds/Low_Health.ogg")
        delay(1500)
        g_window.setTitle(pName .. " - Low Health! only: "..hppercent().."%")
        return
      end
    end

    if config.manaBelow then
      if manapercent() <= config.manaValue then
        playSound("/sounds/Low_Mana.ogg")
        delay(1500)
        g_window.setTitle(pName .. " - Low Mana! only: "..manapercent().."%")
        return
      end
    end
  end)

  onTalk(function(name, level, mode, text, channelId, pos)
    if mode == 4 and config.enabled and config.privateMessage then
      playSound("/sounds/Private_Message.ogg")
      g_window.setTitle(pName .. " - Private Message from: " .. name)
      return
    end
  end)
end

ui.alerts.onClick = function(widget)
  alarmsWindow:show()
  alarmsWindow:raise()
  alarmsWindow:focus()
end