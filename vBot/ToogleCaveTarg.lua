-- Ustaw domyślne pozycje ikon TYLKO jeśli nie ma wpisu w storage._icons
storage._icons = storage._icons or {}
local function ensureIconPos(name, x, y)
  storage._icons[name] = storage._icons[name] or {}
  local rec = storage._icons[name]
  if rec.x == nil or rec.y == nil then
    rec.x = x
    rec.y = y
  end
end

-- Startowe współrzędne (unormowane 0..1) z Twojej listy
ensureIconPos("cI", 0.075880758807588, 0.41383812010444)
ensureIconPos("tI", 0.073170731707317, 0.45953002610966)

-- Ikony
local cIcon = addIcon("cI",{text="Cave\nBot",switchable=false,moveable=true}, function()
  if CaveBot.isOff() then 
    CaveBot.setOn()
  else 
    CaveBot.setOff()
    -- If Attack_Back macro (m) exists and is running, turn it off
    if Fight_Back and type(Fight_Back.setOff) == 'function' and Fight_Back:isOn() then
      Fight_Back:setOff()
    end
    -- If Attack_All macro (attackPVP) exists and is running, turn it off
    if attackPVP and type(attackPVP.setOff) == 'function' and attackPVP:isOn() then
      attackPVP:setOff()
    end
  end
end)
cIcon:setSize({height=30,width=50})
cIcon.text:setFont('verdana-11px-rounded')

local tIcon = addIcon("tI",{text="Target\nBot",switchable=false,moveable=true}, function()
  if TargetBot.isOff() then 
    TargetBot.setOn()
  else 
    TargetBot.setOff()
    if Fight_Back and type(Fight_Back.setOff) == 'function' and Fight_Back:isOn() then
      Fight_Back:setOff()
    end
    -- If Attack_All macro (attackPVP) exists and is running, turn it off
    if attackPVP and type(attackPVP.setOff) == 'function' and attackPVP:isOn() then
      attackPVP:setOff()
    end
  end
end)
tIcon:setSize({height=30,width=50})
tIcon.text:setFont('verdana-11px-rounded')

macro(50,function()
  if CaveBot.isOn() then
    cIcon.text:setColoredText({"CaveBot\n","green","ON","green"})
  else
    cIcon.text:setColoredText({"CaveBot\n","white","OFF","red"})
  end
  if TargetBot.isOn() then
    tIcon.text:setColoredText({"Target\n","green","ON","green"})
  else
    tIcon.text:setColoredText({"Target\n","white","OFF","red"})
  end
end)
