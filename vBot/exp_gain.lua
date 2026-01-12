setDefaultTab("Main")

-- Estetyczne separatory
local sep1 = UI.Separator()
sep1:setHeight(4)
sep1:setBackgroundColor('#A0B0C0')

-- Zmienne
local expGain = 0
local startTime = nil

-- PROSTY LABEL (W jednej linii: "Exp/h: 0")
local expLabel = UI.Label("Exp/h: 0")
expLabel:setTextAlign(AlignCenter) -- Wyśrodkowany tekst
expLabel:setColor("#00EB00")       -- Zielony kolor (jak w bocie)

-- Macro
local m = macro(1000, "Start Counter", function()
    if not startTime then
        startTime = now
    end

    local elapsed = (now - startTime) / 1000
    if elapsed > 0 then
        local expPerHour = (expGain / elapsed) * 3600
        
        -- Formatowanie liczby (proste, bez zależności)
        local val = math.floor(expPerHour)
        local formatted = tostring(val):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
        
        -- Aktualizacja tekstu w Labelu
        expLabel:setText("Exp/h: " .. formatted)
    else
        expLabel:setText("Exp/h: 0")
    end
end)

-- Przycisk Reset
UI.Button("Reset", function()
    expGain = 0
    startTime = now
    expLabel:setText("Exp/h: 0")
end)

-- Zliczanie
onTextMessage(function(mode, text)
    if m.isOff() then return end
    if mode ~= 28 and mode ~= 24 then return end

    local gained_xp_str = string.match(text, "You gained (%d+) experience points%.")
    if gained_xp_str then
        local m_xp = tonumber(gained_xp_str)
        if m_xp then
            expGain = expGain + m_xp
        end
    end
end)
