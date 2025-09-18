-- vBot Effect Avoider and Distance Maintainer
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
-- List of wall item IDs to treat as non-walkable
local wallIds = {}

storage.ignoreDistanceWay = storage.ignoreDistanceWay or "deer,rabbit"
UI.Label("Ignore Avoider:"):setColor("orange")
ignoreDistanceWay = UI.TextEdit(storage.ignoreDistanceWay, function(widget, newText)
    widget:setTooltip("Creatures names to ignore.\nSeparated by commas.\neg:'deer,rabbit,hyaena'")
    storage.ignoreDistanceWay = newText
end)

-- Helper function to check if a tile contains a specific wall item
local function tileContainsWall(tile)
    if not tile then return false end
    local items = tile:getItems()
    if items and #items > 0 then
        for _, item in ipairs(items) do
            if table.find(wallIds, item:getId()) then
                return true
            end
        end
    end
    return false
end

-- Helper function combining walkable and wall checks
local function isTileWalkableAndNotWall(tile)
    if not tile or not tile:isWalkable() then
        return false
    end
    return not tileContainsWall(tile)
end


-- Helper function to convert position table to string key
local function posToString(pos)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        -- print("EffectAvoider Error: Invalid position data passed to posToString. Pos: " .. tostring(pos))
        return "[InvalidOrNilPos]" -- Return a descriptive string instead of nil
    end
    return pos.x .. "," .. pos.y .. "," .. pos.z
end

-- Helper function to get direction from one position to an adjacent one
local function getDirection(fromPos, toPos)
    if not fromPos or not toPos or type(fromPos) ~= "table" or type(toPos) ~= "table" then
         -- print("EffectAvoider Error: Invalid positions passed to getDirection")
         return nil
    end
    local dx = toPos.x - fromPos.x
    local dy = toPos.y - fromPos.y
    if dx == 0 and dy == -1 then return North
    elseif dx == 0 and dy == 1 then return South
    elseif dx == -1 and dy == 0 then return West
    elseif dx == 1 and dy == 0 then return East
    elseif dx == -1 and dy == -1 then return NorthWest
    elseif dx == 1 and dy == -1 then return NorthEast
    elseif dx == -1 and dy == 1 then return SouthWest
    elseif dx == 1 and dy == 1 then return SouthEast
    end
    return nil
end

-- Helper function to calculate position in a given direction
local function getPosInDirection(pos, direction)
    if not pos or direction == nil then return nil end
    local nextPos = {x = pos.x, y = pos.y, z = pos.z}
    if direction == North then nextPos.y = nextPos.y - 1
    elseif direction == South then nextPos.y = nextPos.y + 1
    elseif direction == West then nextPos.x = nextPos.x - 1
    elseif direction == East then nextPos.x = nextPos.x + 1
    elseif direction == NorthWest then nextPos.x = nextPos.x - 1; nextPos.y = nextPos.y - 1
    elseif direction == NorthEast then nextPos.x = nextPos.x + 1; nextPos.y = nextPos.y - 1
    elseif direction == SouthWest then nextPos.x = nextPos.x - 1; nextPos.y = nextPos.y + 1
    elseif direction == SouthEast then nextPos.x = nextPos.x + 1; nextPos.y = nextPos.y + 1
    else return nil -- Invalid direction
    end
    return nextPos
end

-- Helper function to check if a position is a "bad corner" (>= 2 non-walkable/wall cardinal neighbors)
local function isBadCorner(pos)
    if not pos then return true end
    local tile = g_map.getTile(pos)
    -- Use the combined check here as well
    if not tile or not isTileWalkableAndNotWall(tile) then
        return true -- Non-walkable or wall tiles are bad destinations
    end

    local blockedCardinalNeighbors = 0
    local cardinalDirections = {North, South, East, West}

    for _, dir in ipairs(cardinalDirections) do
        local neighborPos = getPosInDirection(pos, dir)
        if neighborPos then
            local neighborTile = g_map.getTile(neighborPos)
            -- Use the combined check for neighbors
            if not neighborTile or not isTileWalkableAndNotWall(neighborTile) then
                blockedCardinalNeighbors = blockedCardinalNeighbors + 1
            end
        else
             blockedCardinalNeighbors = blockedCardinalNeighbors + 1
        end
    end
    return blockedCardinalNeighbors >= 3 -- Make it less restrictive, only a "bad corner" if 3+ sides blocked
end

-- Helper function to check if a kiting position is occluded by a wall towards the target
-- Helper for math.sign as it may not be available in all Lua versions
local function sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end
local _math_sign = math.sign or sign -- Use math.sign if available, else use local fallback
local function isKitePosOccludedByWall(checkPos, targetPos)
    if not checkPos or not targetPos then return false end

    local cardinalDirections = {North, South, East, West}
    for _, dir in ipairs(cardinalDirections) do
        local adjacentPos = getPosInDirection(checkPos, dir)
        if adjacentPos then
            local adjacentTile = g_map.getTile(adjacentPos)
            -- tileContainsWall is defined earlier and uses the global wallIds
            if adjacentTile and tileContainsWall(adjacentTile) then -- Found a wall
                -- Check if the target is beyond this wall relative to checkPos
                local dxWall = adjacentPos.x - checkPos.x
                local dyWall = adjacentPos.y - checkPos.y

                local dxTarget = targetPos.x - checkPos.x
                local dyTarget = targetPos.y - checkPos.y

                -- Check if target is generally in the same cardinal direction as the wall
                -- and the wall is indeed between checkPos and targetPos or at targetPos.
                if dxWall ~= 0 then -- Wall is East or West
                    if _math_sign(dxTarget) == _math_sign(dxWall) and math.abs(dxTarget) >= math.abs(dxWall) then
                        -- Ensure target is not significantly off-axis for this wall check
                        if math.abs(dyTarget) <= 1 then return true end
                    end
                end
                if dyWall ~= 0 then -- Wall is North or South
                    if _math_sign(dyTarget) == _math_sign(dyWall) and math.abs(dyTarget) >= math.abs(dyWall) then
                        -- Ensure target is not significantly off-axis for this wall check
                        if math.abs(dxTarget) <= 1 then return true end
                    end
                end
            end
        end
    end
    return false
end
-- Helper function to check if a tile is an actual corner (wall on X-axis neighbor AND Y-axis neighbor)
local function isActuallyACornerTile(pos)
    if not pos then return true end -- Treat nil pos as a bad spot an actual corner for kiting

    local wallAdjacentX = false
    local wallAdjacentY = false

    -- Check West/East
    local westTile = g_map.getTile(getPosInDirection(pos, West))
    if westTile and tileContainsWall(westTile) then wallAdjacentX = true end
    if not wallAdjacentX then
        local eastTile = g_map.getTile(getPosInDirection(pos, East))
        if eastTile and tileContainsWall(eastTile) then wallAdjacentX = true end
    end

    -- Check North/South
    local northTile = g_map.getTile(getPosInDirection(pos, North))
    if northTile and tileContainsWall(northTile) then wallAdjacentY = true end
    if not wallAdjacentY then
        local southTile = g_map.getTile(getPosInDirection(pos, South))
        if southTile and tileContainsWall(southTile) then wallAdjacentY = true end
    end

    return wallAdjacentX and wallAdjacentY
end

local EffectAvoider = {
    config = {
        enabled = true,
        effect_ids = {1528, 1531},
        check_area = {x=6, y=6},
        maintain_distance_enabled = true,
        min_distance = 2,
        max_distance = 4,
        pathfinding_search_radius = 7
    },
    effects_detected = false,
    avoidance_path = nil,
    just_finished_avoidance = false,
    last_effect_check_time = 0,
    active = true,
    activeToggle = nil,
    updateMacro = nil,
    debugLogFilePath = "EffectAvoider_Debug.log", -- Path relative to OTClient/logs or a specific bot folder if known
}

function EffectAvoider:activate()
    self.active = true
    self.just_finished_avoidance = false
    -- print("Effect Avoider script activated.")
    if self.activeToggle then self.activeToggle:setOn(true) end
    if self.updateMacro then self.updateMacro.setOn(true) end
    self:saveState() -- Save state after activation
end

function EffectAvoider:deactivate()
    self.active = false
    self.avoidance_path = nil
    self.just_finished_avoidance = false
    -- print("Effect Avoider script deactivated.")
    if self.activeToggle then self.activeToggle:setOn(false) end
    if self.updateMacro then self.updateMacro.setOn(false) end
    self:saveState() -- Save state after deactivation
end

function EffectAvoider:getStateFilePath()
    local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
    local profile = g_settings.getNumber('profile')
    return "/bot/" .. configName .. "/vBot_configs/profile_".. profile .. "/EffectAvoider.json"
end

function EffectAvoider:saveState()
    local state = {
        active = self.active
    }
    local jsonState = json.encode(state)
    local filePath = self:getStateFilePath()
    g_resources.writeFileContents(filePath, jsonState)
    -- print("Effect Avoider state saved to " .. filePath)
end

function EffectAvoider:loadState()
    local filePath = self:getStateFilePath()
    if g_resources.fileExists(filePath) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(filePath))
        end)
        if status and result and type(result.active) == "boolean" then
            self.active = result.active
            -- print("Effect Avoider state loaded from " .. filePath)
        else
            -- print("Effect Avoider: Could not decode state or invalid format from " .. filePath .. ". Using default.")
            self.active = true -- Default if load fails
        end
    else
        -- print("Effect Avoider: No saved state found at " .. filePath .. ". Using default.")
        self.active = true -- Default if file not found
    end
-- function EffectAvoider:logDebug(message) -- File logging removed
--     if not self.debugLogFilePath then
--         -- This print might not be seen by user, but good for direct console debugging if possible
--         -- print("EffectAvoider Error: debugLogFilePath not set for logDebug.")
--         return
--     end
--
--     local timestamp = os.date("[%Y-%m-%d %H:%M:%S] ")
--     local formattedMessage = timestamp .. message .. "\n"
--
--     -- Overwrite the file with the latest message
--     local writeStatus, writeError = pcall(g_resources.writeFileContents, self.debugLogFilePath, formattedMessage)
--     if not writeStatus then
--         -- This print might not be seen
--         -- print("EffectAvoider Error: Failed to write to debug log (overwrite) - " .. tostring(writeError))
--     end
end

function EffectAvoider:detectEffects()
    self.effects_detected = false
    local player = g_game.getLocalPlayer()
    if not player then return end
    local playerPos = player:getPosition()
    if not playerPos then return end
    local checkArea = self.config.check_area
    local effectIdsToAvoid = self.config.effect_ids

    for x = playerPos.x - checkArea.x, playerPos.x + checkArea.x do
        for y = playerPos.y - checkArea.y, playerPos.y + checkArea.y do
            local tile = g_map.getTile({x = x, y = y, z = playerPos.z})
            if tile then
                local effects = tile:getEffects()
                if effects and #effects > 0 then
                    for _, effect in ipairs(effects) do
                        if table.find(effectIdsToAvoid, effect:getId()) then
                            self.effects_detected = true
                            return
                        end
                    end
                end
            end
        end
    end
end

local function isTileSafe(tile, effectIdsToAvoid)
    if not tile then return false end
    -- Check for walls first
    if tileContainsWall(tile) then return false end
    -- Then check for effects
    local effects = tile:getEffects()
    if effects and #effects > 0 then
        for _, effect in ipairs(effects) do
            if table.find(effectIdsToAvoid, effect:getId()) then
                return false
            end
        end
    end
    return true
end

function EffectAvoider:findShortestPathToSafeTile(startPos, effectIdsToAvoid)
    if not startPos then return nil end
    local startKey = posToString(startPos)
    if not startKey then return nil end

    local queue = {startPos}
    local visited = {[startKey] = true}
    local parent = {}
    local searchRadius = self.config.pathfinding_search_radius

    local directions = {
        {dx = 0, dy = -1, dir = North}, {dx = 0, dy = 1, dir = South},
        {dx = -1, dy = 0, dir = West}, {dx = 1, dy = 0, dir = East},
        {dx = -1, dy = -1, dir = NorthWest}, {dx = 1, dy = -1, dir = NorthEast},
        {dx = -1, dy = 1, dir = SouthWest}, {dx = 1, dy = 1, dir = SouthEast}
    }

    while #queue > 0 do
        local currentPos = table.remove(queue, 1)
        local currentTile = g_map.getTile(currentPos)

        -- Check if current tile is safe (includes wall check via isTileSafe)
        if currentTile and isTileSafe(currentTile, effectIdsToAvoid) then
            local path = {}
            local step = currentPos
            while posToString(step) ~= startKey do
                local pKey = posToString(step)
                if not pKey then break end
                local p = parent[pKey]
                if not p then return nil end -- Error
                local dir = getDirection(p, step)
                if dir then table.insert(path, 1, dir) end
                step = p
            end
            return path
        end

        for _, d in ipairs(directions) do
            local neighborPos = {x = currentPos.x + d.dx, y = currentPos.y + d.dy, z = currentPos.z}
            local neighborKey = posToString(neighborPos)

            if neighborKey and
               math.abs(neighborPos.x - startPos.x) <= searchRadius and
               math.abs(neighborPos.y - startPos.y) <= searchRadius and
               not visited[neighborKey] then

                local neighborTile = g_map.getTile(neighborPos)
                -- Use combined check for pathfinding neighbors
                if neighborTile and isTileWalkableAndNotWall(neighborTile) then
                    visited[neighborKey] = true
                    parent[neighborKey] = currentPos
                    table.insert(queue, neighborPos)
                end
            end
        end
    end
    return nil
end


-- Helper function to check if a creature is in the ignore list
local function isCreatureIgnored(creature)
    if not creature or not storage.ignoreDistanceWay then return false end
    local name = creature:getName():trim():lower()
    local ignoreList = string.split(storage.ignoreDistanceWay, ",")
    for k, v in ipairs(ignoreList) do
        if name:find(v:trim():lower(), 1, true) then return true end
    end
    return false
end

function EffectAvoider:maintainDistance()
    -- local currentTimeMs = os.clock() * 1000 -- Debug print related
    -- local canPrintDebug = (currentTimeMs - self.last_debug_print_time > self.config.debug_print_throttle_ms) -- Debug print related

    if not self.config.maintain_distance_enabled then return end
    if not g_game.isAttacking() then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - not attacking.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    local targetCreature = g_game.getAttackingCreature()
    if not targetCreature then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - no target creature.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    if isCreatureIgnored(targetCreature) then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - target is ignored: " .. targetCreature:getName()) -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - player object not found.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end
    local playerPos = player:getPosition()
    if not playerPos then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - playerPos is nil.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    local initialTargetPos = targetCreature:getPosition()
    if not initialTargetPos then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - initialTargetPos is nil.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    local initialDistance = getDistanceBetween(playerPos, initialTargetPos)
    local minDistance = self.config.min_distance
    local maxDistance = self.config.max_distance

    if (initialDistance >= minDistance and initialDistance <= maxDistance) then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Already in desired distance range: " .. initialDistance) -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return -- Already in desired range
    end

    -- if canPrintDebug then -- Debug print related
        -- print("EffectAvoider DBG: Current dist: " .. string.format("%.2f", initialDistance) .. ", Target: " .. posToString(initialTargetPos) .. ", Player: " .. posToString(playerPos) .. ". Desired: " .. minDistance .. "-" .. maxDistance) -- Debug print related
    -- end -- Debug print related

    local targetPosForSearch = targetCreature:getPosition() -- Re-fetch, might have moved
    if not targetPosForSearch then
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: Not maintaining distance - targetPosForSearch is nil before BFS.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
        return
    end

    local queue = {{pos = playerPos, pathDirs = {}, depth = 0}}
    local visited = {[posToString(playerPos)] = true}
    
    local foundFirstStepDir = nil

    local maxSearchDepth = self.config.pathfinding_search_radius -- Use configured search radius

    local allDirections = {
        {dirEnum = North, dx = 0, dy = -1}, {dirEnum = South, dx = 0, dy = 1},
        {dirEnum = West, dx = -1, dy = 0}, {dirEnum = East, dx = 1, dy = 0},
        {dirEnum = NorthWest, dx = -1, dy = -1}, {dirEnum = NorthEast, dx = 1, dy = -1},
        {dirEnum = SouthWest, dx = -1, dy = 1}, {dirEnum = SouthEast, dx = 1, dy = 1}
    }

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local currentPos = current.pos
        local currentPathDirs = current.pathDirs
        local currentDepth = current.depth

        if currentDepth > 0 then -- Only evaluate actual steps, not the starting player position
            local distToTarget = getDistanceBetween(currentPos, targetPosForSearch)
            if distToTarget >= minDistance and distToTarget <= maxDistance then
                -- currentPos is a valid kiting destination.
                -- currentPathDirs[1] is the first step from player's original position.
                foundFirstStepDir = currentPathDirs[1]
                -- if canPrintDebug then -- Debug print related
                    -- print("EffectAvoider DBG: BFS found kiting step. Dest: " .. posToString(currentPos) .. ", FirstStepDir: " .. tostring(foundFirstStepDir) .. ", Depth: " .. currentDepth .. ", DistToTarget: " .. string.format("%.2f", distToTarget)) -- Debug print related
                -- end -- Debug print related
                break -- Exit BFS, we found the first suitable spot
            end
        end

        if currentDepth >= maxSearchDepth then
            goto continue_queue_bfs -- Skip adding children if max depth reached for this path
        end

        for _, dirInfo in ipairs(allDirections) do
            local neighborPos = getPosInDirection(currentPos, dirInfo.dirEnum)
            local neighborKey = posToString(neighborPos)

            if neighborPos and not visited[neighborKey] then
                visited[neighborKey] = true
                local neighborTile = g_map.getTile(neighborPos)

                if neighborTile and isTileWalkableAndNotWall(neighborTile) and not neighborTile:hasCreature() and not isBadCorner(neighborPos) then
                    local newPathDirs = {}
                    for _, pd in ipairs(currentPathDirs) do table.insert(newPathDirs, pd) end
                    table.insert(newPathDirs, dirInfo.dirEnum)
                    table.insert(queue, {pos = neighborPos, pathDirs = newPathDirs, depth = currentDepth + 1})
                -- else -- Debug print related
                    -- if canPrintDebug and neighborTile then -- Debug print related
                         -- Only print if the tile itself exists, to avoid spamming for out-of-bounds checks -- Debug print related
                        -- local reason = "" -- Debug print related
                        -- if not isTileWalkableAndNotWall(neighborTile) then reason = reason .. "NotWalkableOrWall " end -- Debug print related
                        -- if neighborTile:hasCreature() then reason = reason .. "HasCreature " end -- Debug print related
                        -- if isBadCorner(neighborPos) then reason = reason .. "IsBadCorner " end -- Debug print related
                        -- if reason ~= "" then -- Debug print related
                            -- print("EffectAvoider DBG: BFS skipped neighbor: " .. posToString(neighborPos) .. " Reason: " .. reason) -- Debug print related
                        -- end -- Debug print related
                    -- end -- Debug print related
                end
            end
        end
        ::continue_queue_bfs::
    end


    if foundFirstStepDir then
        local finalPlayerPos = player:getPosition() -- Re-fetch player pos
        if not finalPlayerPos then
            -- if canPrintDebug then print("EffectAvoider DBG: Walk failed - finalPlayerPos is nil.") self.last_debug_print_time = currentTimeMs end -- Debug print related
            return
        end
        local finalTargetPos = targetCreature:getPosition() -- Re-fetch target pos
        if not finalTargetPos then
            -- if canPrintDebug then print("EffectAvoider DBG: Walk failed - finalTargetPos is nil.") self.last_debug_print_time = currentTimeMs end -- Debug print related
            return
        end
        
        local finalCurrentDistance = getDistanceBetween(finalPlayerPos, finalTargetPos)

        local shouldWalk = false
        if initialDistance < minDistance and finalCurrentDistance < minDistance then
            shouldWalk = true -- Player is too close, and after BFS calculation, is still too close
        elseif initialDistance > maxDistance and finalCurrentDistance > maxDistance then
            shouldWalk = true -- Player is too far, and after BFS calculation, is still too far
        end
        
        if shouldWalk then
            local destinationPos = getPosInDirection(finalPlayerPos, foundFirstStepDir)
            if destinationPos then
                -- if canPrintDebug then -- Debug print related
                    -- print("EffectAvoider DBG: Executing autoWalk to: " .. posToString(destinationPos) .. " (Dir: " .. tostring(foundFirstStepDir) .. ") InitialDist: " .. string.format("%.2f", initialDistance) .. " FinalDist: " .. string.format("%.2f", finalCurrentDistance)) -- Debug print related
                    -- self.last_debug_print_time = currentTimeMs -- Debug print related
                -- end -- Debug print related
                player:autoWalk(destinationPos)
            -- else -- Debug print related
                -- if canPrintDebug then print("EffectAvoider DBG: Walk failed - destinationPos is nil for dir " .. tostring(foundFirstStepDir)) self.last_debug_print_time = currentTimeMs end -- Debug print related
            end
        -- else -- Debug print related
            -- if canPrintDebug then -- Debug print related
                -- print("EffectAvoider DBG: Decided not to walk. InitialDist: " .. string.format("%.2f", initialDistance) .. " FinalDist: " .. string.format("%.2f", finalCurrentDistance) .. " (Min: " .. minDistance .. " Max: " .. maxDistance .. ")") -- Debug print related
                -- self.last_debug_print_time = currentTimeMs -- Debug print related
            -- end -- Debug print related
        end
    -- else -- Debug print related
        -- if canPrintDebug then -- Debug print related
            -- print("EffectAvoider DBG: No suitable kiting step found by BFS.") -- Debug print related
            -- self.last_debug_print_time = currentTimeMs -- Debug print related
        -- end -- Debug print related
    end
end

function EffectAvoider:update()
    if not self.config.enabled then return end

    local player = g_game.getLocalPlayer()
    if not player then return end
    local playerPos = player:getPosition()

    if not playerPos then
        self.avoidance_path = nil
        self.just_finished_avoidance = false
        g_game.stop()
        return
    end

    if self.just_finished_avoidance then
        self.just_finished_avoidance = false
        return
    end

    if self.avoidance_path and #self.avoidance_path > 0 then
        local nextStepDir = self.avoidance_path[1]
        if not playerPos then self.avoidance_path = nil; g_game.stop(); return end
        local nextPos = getPosInDirection(playerPos, nextStepDir)
        if not nextPos then self.avoidance_path = nil; g_game.stop(); return end

        local nextTile = g_map.getTile(nextPos)
        -- Use combined check for path following
        if nextTile and isTileWalkableAndNotWall(nextTile) and not nextTile:hasCreature() then
             g_game.walk(nextStepDir)
             table.remove(self.avoidance_path, 1)
             if #self.avoidance_path == 0 then self.just_finished_avoidance = true end
        else
            self.avoidance_path = nil
            g_game.stop()
        end
        return
    end

    local currentTile = g_map.getTile(playerPos)
    local effectIdsToAvoid = self.config.effect_ids
    -- Use combined check for current tile safety (isTileSafe now includes wall check)
    local isCurrentTileSafeCheck = isTileSafe(currentTile, effectIdsToAvoid)

    if not isCurrentTileSafeCheck then
        self.avoidance_path = self:findShortestPathToSafeTile(playerPos, effectIdsToAvoid)

        if self.avoidance_path and #self.avoidance_path > 0 then
            local nextStepDir = self.avoidance_path[1]
            if not playerPos then self.avoidance_path = nil; g_game.stop(); return end
            local nextPos = getPosInDirection(playerPos, nextStepDir)
             if not nextPos then self.avoidance_path = nil; g_game.stop(); return end

            local nextTile = g_map.getTile(nextPos)
            -- Use combined check for first step
            if nextTile and isTileWalkableAndNotWall(nextTile) and not nextTile:hasCreature() then
                g_game.walk(nextStepDir)
                table.remove(self.avoidance_path, 1)
                if #self.avoidance_path == 0 then self.just_finished_avoidance = true end
            else
                 self.avoidance_path = nil
                 g_game.stop()
            end
        else
            g_game.stop()
        end
        return
    else
        self.avoidance_path = nil
        self:detectEffects()

        if not self.effects_detected then
            self:maintainDistance()
        end
    end
end


function EffectAvoider:init()
    self:loadState() -- Load state before initializing controls

    if not self.activeToggle then
        self.activeToggle = addSwitch("effectAvoiderToggle", "Effect Avoider", function(widget)
            EffectAvoider.active = not EffectAvoider.active
            widget:setOn(EffectAvoider.active)
            if EffectAvoider.active then EffectAvoider:activate() else EffectAvoider:deactivate() end
        end)
        if self.activeToggle then self.activeToggle:setOn(self.active)
        else return end
    end

    if not self.updateMacro then
        self.updateMacro = macro(100, function() EffectAvoider:update() end)
        self.updateMacro.setOn(self.active)
    end

    -- print("Effect Avoider script initialized.")
end

EffectAvoider:init()

return EffectAvoider

