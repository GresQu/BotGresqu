setDefaultTab("Main")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
pve_spell = macro(200, "PvE Spell",  function()
    if not g_game.isAttacking() then return end
    local target = g_game.getAttackingCreature()
    if target and target:isPlayer() then return end

    local players = getPlayerss(7)
    local playerOnScreen = #players > 0

    say(storage.FirstSpellPvE)
    say(storage.SecondSpellPvE)
    say(storage.ThirdSpellPvE)
    if not playerOnScreen then
        say(storage.FourSpellPvE)
    end
    say(storage.FiveSpellPvE)
end)
    
local showEdit = false
UI.Button("Hide/Show", function(widget)
    showEdit = not showEdit
    if showEdit then
        UID7:show()
        UID8:show()
        UID9:show()
        UID10:show()
        UID11:show()
        UID12:show()
        UIDPVE01:show()
        UIDPVE02:show()
        UIDPVE4:show()
        UIDPVE5:show()
    else
        UID7:hide()
        UID8:hide()
        UID9:hide()
        UID10:hide()
        UID11:hide()
        UID12:hide()
        UIDPVE01:hide()
        UIDPVE02:hide()
        UIDPVE4:hide()
        UIDPVE5:hide()
    end
end)
UID7 = UI.Label("First_Spell_PvE:")
UID7:hide()
UID8 = UI.TextEdit(storage.FirstSpellPvE or "Spell_Name", function(widget, newText)
    storage.FirstSpellPvE = newText
end)
UID8:hide()
UID9 = UI.Label("Second_Spell_PvE:")
UID9:hide()
UID10 = UI.TextEdit(storage.SecondSpellPvE or "", function(widget, newText)
    storage.SecondSpellPvE = newText
end)
UID10:hide()
UID11 = UI.Label("Third_Spell PvE:")
UID11:hide()
UID12 = UI.TextEdit(storage.ThirdSpellPvE or "", function(widget, newText)
    storage.ThirdSpellPvE = newText
end)
UID12:hide()
UIDPVE01 = UI.Label("Four_Spell PvE AoeHere:")
UIDPVE01:hide()
UIDPVE4 = UI.TextEdit(storage.FourSpellPvE or "", function(widget, newText)
    storage.FourSpellPvE = newText
end)
UIDPVE4:hide()
UIDPVE02 = UI.Label("FiveSpellPvE_Spell PvE:")
UIDPVE02:hide()
UIDPVE5 = UI.TextEdit(storage.FiveSpellPvE or "", function(widget, newText)
    storage.FiveSpellPvE = newText
end)
UIDPVE5:hide()
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

pvp_spell = macro(200, "PvP Spell",  function()
    if not g_game.isAttacking() then return end
    local target = g_game.getAttackingCreature()
    if target and not target:isPlayer() then return end
    say(storage.FirstSpellPvP)
    say(storage.SecondSpellPvP)
    say(storage.ThirdSpellPvP)
    say(storage.FourSpellPvP)
    say(storage.FiveSpellPvP)
end)
local showEdit = false
UI.Button("Hide/Show", function(widget)
    showEdit = not showEdit
    if showEdit then
        UID1:show()
        UID2:show()
        UID3:show()
        UID4:show()
        UID5:show()
        UID6:show()
        UIDPVP01:show()
        UIDPVP02:show()
        UIPVP7:show()
        UIPVP8:show()
    else
        UID1:hide()
        UID2:hide()
        UID3:hide()
        UID4:hide()
        UID5:hide()
        UID6:hide()
        UIDPVP01:hide()
        UIDPVP02:hide()
        UIPVP7:hide()
        UIPVP8:hide()
    end
end)

UID1 = UI.Label("First_Spell_PvP:")
UID1:hide()
UID2 = UI.TextEdit(storage.FirstSpellPvP or "Spell_Name", function(widget, newText)
    storage.FirstSpellPvP = newText
end)
UID2:hide()
UID3 = UI.Label("Second_Spell PvP:")
UID3:hide()
UID4 = UI.TextEdit(storage.SecondSpellPvP or "", function(widget, newText)
    storage.SecondSpellPvP = newText
end)
UID4:hide()
UID5 = UI.Label("Third_Spell PvP:")
UID5:hide()
UID6 = UI.TextEdit(storage.ThirdSpellPvP or "", function(widget, newText)
    storage.ThirdSpellPvP = newText
end)
UID6:hide()
UIDPVP01 = UI.Label("FourSpellPvP_Spell PvE:")
UIDPVP01:hide()
UIPVP7 = UI.TextEdit(storage.FourSpellPvP or "", function(widget, newText)
    storage.FourSpellPvP = newText
end)
UIPVP7:hide()
UIDPVP02 = UI.Label("FiveSpellPvP_Spell PvE:")
UIDPVP02:hide()
UIPVP8 = UI.TextEdit(storage.FiveSpellPvP or "", function(widget, newText)
    storage.FiveSpellPvP = newText
end)
UIPVP8:hide()
UI.Separator()

function getPlayerss(range)
  local pos = player:getPosition()
  local spectators = g_map.getSpectators(pos, false)
  local players = {}

  for i = 1, #spectators do
    local spec = spectators[i]
    if spec:isPlayer() and spec ~= player and getDistanceBetween(pos, spec:getPosition()) <= range then
      table.insert(players, spec)
    end
  end

  return players
end

pve_aoe_spell = macro(200, "PvE Aoe Spell", function()
    local target = g_game.getAttackingCreature()
    if target and target:isPlayer() then return end

    local players = getPlayerss(7)
    local playerOnScreen = #players > 0

    if not playerOnScreen and getMonsters(tonumber(storage.AoeRange)) >= tonumber(storage.MonsterLower) then
        say(storage.FirstSpellPvEAoe)
    elseif g_game.isAttacking() then
        say(storage.FirstSpellPvETarget)
        say(storage.SecondSpellPvETarget)
        say(storage.ThirdSpellPvETarget)
        say(storage.FourthSpellPvETarget)
        say(storage.FifthSpellPvETarget)
    end
end)
    
local showEdit = false
UI.Button("Hide/Show", function(widget)
    showEdit = not showEdit
    if showEdit then
        UID13:show()
        UID14:show()
        UID15:show()
        UID16:show()
        UID17:show()
        UID18:show()
        UID29:show()
        UID30:show()
        UID31:show()
        UID32:show()
        UID33:show()
        UID34:show()
        UID35:show()
        UID36:show()
    else
        UID13:hide()
        UID14:hide()
        UID15:hide()
        UID16:hide()
        UID17:hide()
        UID18:hide()
        UID29:hide()
        UID30:hide()
        UID31:hide()
        UID32:hide()
        UID33:hide()
        UID34:hide()
        UID35:hide()
        UID36:hide()
    end
end)

UID13 = UI.Label("Spell_Aoe:")
UID13:hide()
UID14 = UI.TextEdit(storage.FirstSpellPvEAoe or "Spell_Name", function(widget, newText)
    storage.FirstSpellPvEAoe = newText
end)
UID14:hide()
UID29 = UI.Label("First_Target_Spell:")
UID29:hide()
UID30 = UI.TextEdit(storage.FirstSpellPvETarget or "Spell_Name", function(widget, newText)
    storage.FirstSpellPvETarget = newText
end)
UID30:hide()
UID31 = UI.Label("Second_Target_Spell:")
UID31:hide()
UID32 = UI.TextEdit(storage.SecondSpellPvETarget or "", function(widget, newText)
    storage.SecondSpellPvETarget = newText
end)
UID32:hide()
UID33 = UI.Label("Third_Target_Spell:")
UID33:hide()
UID34 = UI.TextEdit(storage.ThirdSpellPvETarget or "", function(widget, newText)
    storage.ThirdSpellPvETarget = newText
end)
UID34:hide()
UID35 = UI.Label("Fourth_Target_Spell:")
UID35:hide()
UID36 = UI.TextEdit(storage.FourthSpellPvETarget or "", function(widget, newText)
    storage.FourthSpellPvETarget = newText
end)
UID36:hide()
UID37 = UI.Label("Fifth_Target_Spell:")
UID37:hide()
UID38 = UI.TextEdit(storage.FifthSpellPvETarget or "", function(widget, newText)
    storage.FifthSpellPvETarget = newText
end)
UID38:hide()
UID15 = UI.Label("Min_Monster_Amount:")
UID15:hide()
UID16 = UI.TextEdit(storage.MonsterLower or "2", function(widget, newText)
    storage.MonsterLower = newText
end)
UID16:hide()
UID17 = UI.Label("Min_Monster_Range:")
UID17:hide()
UID18 = UI.TextEdit(storage.AoeRange or "5", function(widget, newText)
    storage.AoeRange = newText
end)
UID18:hide()


local icon_pvp_cast_spell = addIcon("PvP_Spell",{ text="", movable=true}, function(icon, isOn)
    icon.text:setColoredText({
        "PvP", isOn and "green" or "white"
    })
    pvp_spell.setOn()
    pvp_spell.setOff(not isOn)
    if CaveBot and TargetBot and isOn then
        CaveBot.setOff()
        TargetBot.setOff()
    else
        return
    end
end) 

icon_pvp_cast_spell:setSize({height=30,width=60})
icon_pvp_cast_spell.text:setFont('verdana-11px-rounded')

local icon_pve_aoe_cast_spell = addIcon("Aoe_PvE",{ text = "", movable=true}, function(icon, isOn)
    icon.text:setColoredText({
        "AoE", isOn and "green" or "white"
    })
    pve_aoe_spell.setOn()  -- If the icon is ON, turn PvE macros OFF
    pve_aoe_spell.setOff(not isOn)
    if CaveBot and TargetBot and isOn then
        CaveBot.setOff()
        TargetBot.setOff()
    else
        return
    end
end) 
icon_pve_aoe_cast_spell:setSize({height=30,width=60})
icon_pve_aoe_cast_spell.text:setFont('verdana-11px-rounded')


local icon_pve_cast_spell = addIcon("Pve_Spell",{ text="", movable=true}, function(icon, isOn)
    icon.text:setColoredText({
        "PvE", isOn and "green" or "white"
    })  -- If the icon is ON, turn PvE macros OFF
    pve_spell.setOn()
    pve_spell.setOff(not isOn)
    if CaveBot and TargetBot and isOn then
        CaveBot.setOff()
        TargetBot.setOff()
    else
        return
    end
end) 
icon_pve_cast_spell:setSize({height=30,width=60})
icon_pve_cast_spell.text:setFont('verdana-11px-rounded')