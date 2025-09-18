

labelcc = UI.Label("Battle Filter")
labelcc:setFont("verdana-11px-rounded")
labelcc:setColor("orange")

local PainelName = "FiltroBattles"
FiltroIcon = setupUI([[
Panel
  height: 20
  margin-top: 3
  
  Panel
    id: inicio
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 0
    margin-top:
    image-border: 2
    text-align: center
    text-align: left
    width: 200
    height: 20
    image-source: 
    font: verdana-11px-rounded
    opacity: 0.80

  Panel
    id: buttons
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    height: 20
    width: 15
    layout:
      type: horizontalBox
      spacing: 20

  BattlePlayers
    id: players
    border: 1 #778899
    image-color: white
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 27
    image-source: /images/game/battle/battle_players
    !tooltip: tr('Filter players.')

  BattleNPCs
    id: npcs
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_npcs
    !tooltip: tr('Filter NPCs.')

  BattleMonsters
    id: mobs
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_monsters
    !tooltip: tr('Filter mobs.')
    opacity: 1.00

  BattleSkulls
    id: sempk
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_skulls
    !tooltip: tr('Filter Players without PK.')
    opacity: 1.00

  BattleParty
    id: party
    border: 1 #778899
    anchors.top: parent.top
    anchors.left: prev.left
    margin-left: 30
    text-align: center
    image-source: /images/game/battle/battle_party
    !tooltip: tr('Filter Party Members.')
    opacity: 1.00
]], parent)

storage.FiltroPlayers = storage.FiltroPlayers or false
storage.FiltroNpcs = storage.FiltroNpcs or false
storage.FiltroMobs = storage.FiltroMobs or false
storage.FiltroSkull = storage.FiltroSkull or false
storage.FiltroParty = storage.FiltroParty or false

macro(100, function()
  if storage.FiltroPlayers then
    FiltroIcon.players:setImageColor('#696969')
  else
    FiltroIcon.players:setImageColor('#FFFFFF')
  end

  if storage.FiltroNpcs then
    FiltroIcon.npcs:setImageColor('#696969')
  else
    FiltroIcon.npcs:setImageColor('#FFFFFF')
  end

  if storage.FiltroMobs then
    FiltroIcon.mobs:setImageColor('#696969')
  else
    FiltroIcon.mobs:setImageColor('#FFFFFF')
  end

  if storage.FiltroSkull then
    FiltroIcon.sempk:setImageColor('#696969')
  else
    FiltroIcon.sempk:setImageColor('#FFFFFF')
  end

  if storage.FiltroParty then
    FiltroIcon.party:setImageColor('#696969')
  else
    FiltroIcon.party:setImageColor('#FFFFFF')
  end
end)

FiltroIcon.players.onClick = function(widget)
  storage.FiltroPlayers = not storage.FiltroPlayers
end

FiltroIcon.npcs.onClick = function(widget)
  storage.FiltroNpcs = not storage.FiltroNpcs
end

FiltroIcon.mobs.onClick = function(widget)
  storage.FiltroMobs = not storage.FiltroMobs
end

FiltroIcon.sempk.onClick = function(widget)
  storage.FiltroSkull = not storage.FiltroSkull
end

FiltroIcon.party.onClick = function(widget)
  storage.FiltroParty = not storage.FiltroParty
end

FiltrarBattle = macro(1, function() end)
modules.game_battle.doCreatureFitFilters = function(creature)
  if creature:isLocalPlayer() or creature:getHealthPercent() <= 0 then
    return false
  end
  local pos = creature:getPosition()
  if not pos or pos.z ~= posz() or not creature:canBeSeen() then return false end

  if creature:isMonster() and FiltrarBattle.isOn() and storage.FiltroMobs then
    return false
  elseif creature:isPlayer() and FiltrarBattle.isOn() and storage.FiltroPlayers then
    return false
  elseif creature:isNpc() and FiltrarBattle.isOn() and storage.FiltroNpcs then
    return false
  elseif creature:isPlayer() and (creature:getEmblem() == 1 or creature:getEmblem() == 4 or creature:getShield() == 3 or creature:getShield() == 4) and FiltrarBattle.isOn() and storage.FiltroParty then
    return false
  elseif creature:isPlayer() and creature:getSkull() == 0 and storage.FiltroSkull then
    return false
  end
  return true
end
UI.Separator()
