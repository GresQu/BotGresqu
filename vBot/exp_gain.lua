setDefaultTab("Main")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

local title = UI.Label("Exp/h")
title:setColor("orange")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

local expGain = 0
local startTime = nil
local expPerHourLabel = UI.DualLabel("Exp/h:", "0", contentsPanel).right

local m = macro(1000, "Start", function()
    if not startTime then
        startTime = now
    end
    local elapsed = (now - startTime) / 1000 -- czas w sekundach
    if elapsed > 0 then
        local expPerHour = (expGain / elapsed) * 3600
        expPerHourLabel:setText(format_thousand(math.floor(expPerHour)))
    end
end)

UI.Button("Reset", function()
    expGain = 0
    startTime = now
    expPerHourLabel:setText("0")
end)

onTextMessage(function(mode, text)
    if m.isOff() then
        return
    end

    if mode ~= 28 and mode ~= 24 then -- Check for both mode 28 and 24
        return
    end

    -- More robust matching for "You gained X experience points."
    local gained_xp_str = string.match(text, "You gained ([0-9]+) experience points%.")
    
    if gained_xp_str then
        local m_xp = tonumber(gained_xp_str)
        if m_xp then
            expGain = expGain + m_xp
        end
    end
end)

