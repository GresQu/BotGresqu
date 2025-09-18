local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local UpDown = macro(50, "Move Up-Down", function()
    walk(0) -- północ
    delay(50)
    walk(2) -- południe
    delay(50)
end)

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local MoveEW = macro(50, "Move Left-Right", function()
    walk(1) -- zachód
    delay(50)
    walk(3) -- wschód
    delay(50)
end)

local lastMoveTime = os.time()
local lastPosition = g_game.getLocalPlayer():getPosition()

local function hasMoved()
    local player = g_game.getLocalPlayer()
    if player then
        local currentPos = player:getPosition()
        return currentPos.x ~= lastPosition.x or currentPos.y ~= lastPosition.y or currentPos.z ~= lastPosition.z
    end
    return false
end

macro(50, "AntyStuck", function()
    local player = g_game.getLocalPlayer()
    if not player then return end

    if hasMoved() then
        lastMoveTime = os.time()
        lastPosition = player:getPosition()
    else
        -- Reaguj po 0.5 sekundy zamiast 1 sekundy
        if os.time() - lastMoveTime > 0.5 then
            local direction
            
            if UpDown:isOn() then
                -- Tylko lewo/prawo (0 - zachód, 2 - wschód)
                direction = math.random(1, 2) == 1 and 1 or 3
            elseif MoveEW:isOn() then
                -- Tylko góra/dół (1 - północ, 3 - południe)
                direction = math.random(0, 1) == 0 and 0 or 2
            else
                -- Losowy kierunek jeśli żadne makro nie aktywne
                direction = math.random(0, 3)
            end

            walk(direction)
            lastMoveTime = os.time()
        end
    end
end)