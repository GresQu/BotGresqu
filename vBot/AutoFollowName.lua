local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
UI.Separator()
UI.Label("Auto Follow Name")
addTextEdit("followleader", storage.followLeader or "player name", function(widget, text)
    storage.followLeader = text
end)

-- Code
local toFollowPos = {}
local followMacro = macro(1, "Follow", function()
    local target = getCreatureByName(storage.followLeader)
    if target then
        local tpos = target:getPosition()
        toFollowPos[tpos.z] = tpos
    end

    if player:isWalking() then
        return
    end

    local p = toFollowPos[posz()]
    if not p then
        return
    end

    if autoWalk(p, 20, {ignoreNonPathable=true, precision=1}) then
        delay(50)
    end
end)

onCreaturePositionChange(function(creature, oldPos, newPos)
    if creature:getName() == storage.followLeader then
        toFollowPos[newPos.z] = newPos
    end
end)
