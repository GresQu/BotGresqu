-- auto recording for cavebot
CaveBot.Recorder = {}

local isEnabled = nil
local lastPos = nil

local dawinbiDoors = {17998, 17705, 17565, 11239, 11139, 9863, 6896, 9556, 7038, 9367, 7727, 8367, 8265, 1648, 29864, 1666, 6264, 6207, 1680, 1687, 5293, 5102, 5120, 29865, 8263, 7047, 7725, 6262, 6205, 5291, 5129, 5111, 1696, 1678, 1664, 1646, 8365, 9365, 9565, 9872, 11146, 11248, 17574, 17714, 18007, 6905}
local visitedPositions = {}

local function setup()
  local function addPosition(pos)
    local tile = g_map.getTile(pos)
    if tile then
      local items = tile:getItems()
      local foundDoor = false
      if items and #items > 0 then
        for i, item in ipairs(items) do
          local itemId = item:getId()
          for j, doorId in ipairs(dawinbiDoors) do
            if itemId == doorId then
              foundDoor = true
              break
            end
          end
          if foundDoor then
            break
          end
        end
      end
      if not foundDoor then
        local key = pos.x .. "," .. pos.y .. "," .. pos.z
        if not visitedPositions[key] then
          CaveBot.addAction("goto", key, true)
          visitedPositions[key] = true
          lastPos = pos
        end
      end
    end
  end

  

  local function addPositionStairs(pos)
    CaveBot.addAction("goto", pos.x .. "," .. pos.y .. "," .. pos.z, true)
    lastPos = pos
  end

  onPlayerPositionChange(function(newPos, oldPos)
    if CaveBot.isOn() or not isEnabled then return end    
    if not lastPos then
      -- first step
      addPosition(oldPos)
    elseif newPos.z ~= oldPos.z or math.abs(oldPos.x - newPos.x) > 1 or math.abs(oldPos.y - newPos.y) > 1 then
      -- stairs/teleport
      addPositionStairs(oldPos)
    elseif math.max(math.abs(lastPos.x - newPos.x), math.abs(lastPos.y - newPos.y)) > 5 then
      -- 5 steps from last pos
      addPosition(newPos)
    end
  end)



  
  onUse(function(pos, itemId, stackPos, subType)
    if CaveBot.isOn() or not isEnabled then return end
    if pos.x ~= 0xFFFF then 
      lastPos = pos
      CaveBot.addAction("use", pos.x .. "," .. pos.y .. "," .. pos.z, true)
    end
  end)
  
  onUseWith(function(pos, itemId, target, subType)
    if CaveBot.isOn() or not isEnabled then return end
    if not target:isItem() then return end
    local targetPos = target:getPosition()
    if targetPos.x == 0xFFFF then return end
    lastPos = pos
    CaveBot.addAction("usewith", itemId .. "," .. targetPos.x .. "," .. targetPos.y .. "," .. targetPos.z, true)
  end)
end

CaveBot.Recorder.isOn = function()
  return isEnabled
end

CaveBot.Recorder.enable = function()
  CaveBot.setOff()
  if isEnabled == nil then
    setup()
  end
  CaveBot.Editor.ui.autoRecording:setOn(true)
  isEnabled = true
  lastPos = nil
end

CaveBot.Recorder.disable = function()
  if isEnabled == true then
    isEnabled = false
  end
  CaveBot.Editor.ui.autoRecording:setOn(false)
  CaveBot.save()
end