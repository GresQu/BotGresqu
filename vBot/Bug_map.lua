local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

local wsadWalking = modules.game_walking.wsadWalking
local doorsIds = { 1631, 1629, 1632, 5129 , 6264}

function checkForDoors(pos)
  local tile = g_map.getTile(pos)
  if tile then
    local useThing = tile:getTopUseThing()
    if useThing and table.find(doorsIds, useThing:getId()) then
      g_game.use(useThing)
    end
  end
end

onKeyPress(function(keys)
  local pos = player:getPosition()
  if keys == 'Up' or (wsadWalking and keys == 'W') then
    pos.y = pos.y - 1
  elseif keys == 'Down' or (wsadWalking and keys == 'S') then
    pos.y = pos.y + 1
  elseif keys == 'Left' or (wsadWalking and keys == 'A') then
    pos.x = pos.x - 1
  elseif keys == 'Right' or (wsadWalking and keys == 'D') then
    pos.x = pos.x + 1
  end
  checkForDoors(pos)
end)


local function checkPos(x, y)
 xyz = g_game.getLocalPlayer():getPosition()
 xyz.x = xyz.x + x
 xyz.y = xyz.y + y
 tile = g_map.getTile(xyz)
 if tile then
  return g_game.use(tile:getTopUseThing())
 else
  return false
 end
end

macro(1, 'Bug Map', "shift+1", function() 
 if modules.game_console and modules.game_console:isChatEnabled() then return end

 if modules.corelib.g_keyboard.isKeyPressed('w') then
  checkPos(0, -5)
 elseif modules.corelib.g_keyboard.isKeyPressed('e') then
  checkPos(3, -3)
 elseif modules.corelib.g_keyboard.isKeyPressed('d') then
  checkPos(5, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('c') then
  checkPos(3, 3)
 elseif modules.corelib.g_keyboard.isKeyPressed('s') then
  checkPos(0, 5)
 elseif modules.corelib.g_keyboard.isKeyPressed('z') then
  checkPos(-3, 3)
 elseif modules.corelib.g_keyboard.isKeyPressed('a') then
  checkPos(-5, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('q') then
  checkPos(-3, -3)
 end
end)