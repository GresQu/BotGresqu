-- Script Name: healing_setup.lua
-- Author: GresQu
-- Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-27 19:34:21
-- Current User's Login: GresQu

setDefaultTab("HP")

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local windowName = "HealSetupWindow"
local healWindow = UI.createWindow(windowName)
healWindow:hide()

-- Inicjalizacja storage dla stanu checkboxów jeśli nie istnieje
storage.healSpellsEnabled = storage.healSpellsEnabled or {
    spell1 = false,
    spell2 = false,
    spell3 = false,
    spell4 = false
}

-- Dodajemy zmienne do śledzenia stanu makr
healWindow.healSpellsEnabled = {
    spell1 = storage.healSpellsEnabled.spell1 or false,
    spell2 = storage.healSpellsEnabled.spell2 or false,
    spell3 = storage.healSpellsEnabled.spell3 or false,
    spell4 = storage.healSpellsEnabled.spell4 or false
}

local ui = setupUI([[
Panel
  height: 19

  Button
    id: open
    anchors.top: parent.top
    anchors.left: parent.left
    width: 175
    height: 20
    text: Healing Spell Setup
    color: yellow
]])
ui:setId("healSetupOpener")
ui.open.onClick = function()
  healWindow:show()
  healWindow:raise()
  healWindow:focus()
end

-- Referencje
local c = healWindow.container
local spell1, spell1Proc, cooldown1 = c.spell1, c.spell1Proc, c.cooldown1
local spell2, spell2Proc, cooldown2 = c.spell2, c.spell2Proc, c.cooldown2
local spell3, spell3Proc, cooldown3 = c.spell3, c.spell3Proc, c.cooldown3
local spell4, spell4Proc, cooldown4 = c.spell4, c.spell4Proc, c.cooldown4

-- Zapis/odczyt
spell1.onTextChange     = function(w,t) storage.spell1     = t end
spell1Proc.onTextChange = function(w,t) storage.spell1Proc = t end
cooldown1.onTextChange  = function(w,t) storage.cooldown1  = t end
spell2.onTextChange     = function(w,t) storage.spell2     = t end
spell2Proc.onTextChange = function(w,t) storage.spell2Proc = t end
cooldown2.onTextChange  = function(w,t) storage.cooldown2  = t end
spell3.onTextChange     = function(w,t) storage.spell3     = t end
spell3Proc.onTextChange = function(w,t) storage.spell3Proc = t end
cooldown3.onTextChange  = function(w,t) storage.cooldown3  = t end
spell4.onTextChange     = function(w,t) storage.spell4     = t end
spell4Proc.onTextChange = function(w,t) storage.spell4Proc = t end
cooldown4.onTextChange  = function(w,t) storage.cooldown4  = t end

spell1:setText    (storage.spell1     or "")
spell1Proc:setText(storage.spell1Proc or "90")
cooldown1:setText (storage.cooldown1  or "100")
spell2:setText    (storage.spell2     or "")
spell2Proc:setText(storage.spell2Proc or "90")
cooldown2:setText (storage.cooldown2  or "100")
spell3:setText    (storage.spell3     or "")
spell3Proc:setText(storage.spell3Proc or "90")
cooldown3:setText (storage.cooldown3  or "100")
spell4:setText    (storage.spell4     or "")
spell4Proc:setText(storage.spell4Proc or "90")
cooldown4:setText (storage.cooldown4  or "100")

-- Ustawienie początkowego stanu checkboxów i dodanie obsługi zdarzeń
if c.enableSpell1 then 
    c.enableSpell1:setChecked(storage.healSpellsEnabled.spell1)
    c.enableSpell1.onCheckChange = function(widget, checked)
        healWindow.healSpellsEnabled.spell1 = checked
        storage.healSpellsEnabled.spell1 = checked
    end
end

if c.enableSpell2 then 
    c.enableSpell2:setChecked(storage.healSpellsEnabled.spell2)
    c.enableSpell2.onCheckChange = function(widget, checked)
        healWindow.healSpellsEnabled.spell2 = checked
        storage.healSpellsEnabled.spell2 = checked
    end
end

if c.enableSpell3 then 
    c.enableSpell3:setChecked(storage.healSpellsEnabled.spell3)
    c.enableSpell3.onCheckChange = function(widget, checked)
        healWindow.healSpellsEnabled.spell3 = checked
        storage.healSpellsEnabled.spell3 = checked
    end
end

if c.enableSpell4 then 
    c.enableSpell4:setChecked(storage.healSpellsEnabled.spell4)
    c.enableSpell4.onCheckChange = function(widget, checked)
        healWindow.healSpellsEnabled.spell4 = checked
        storage.healSpellsEnabled.spell4 = checked
    end
end

-- Zmienne do śledzenia czasu ostatniego użycia spelli
local lastUseTime = {
    spell1 = 0,
    spell2 = 0,
    spell3 = 0,
    spell4 = 0
}

-- ====================================================================
-- # Makra: rejestracja i automatyczne wywołanie
-- ====================================================================
macro(10, "", function()
    if healWindow.healSpellsEnabled.spell1 then
        local proc = tonumber(storage.spell1Proc) or 0
        local cooldown = tonumber(storage.cooldown1) or 100
        local currentTime = now
        if hppercent() <= proc and storage.spell1 ~= "" and (currentTime - lastUseTime.spell1) >= cooldown then
            say(storage.spell1)
            lastUseTime.spell1 = currentTime
        end
    end
end)

macro(10, "", function()
    if healWindow.healSpellsEnabled.spell2 then
        local proc = tonumber(storage.spell2Proc) or 0
        local cooldown = tonumber(storage.cooldown2) or 100
        local currentTime = now
        if hppercent() <= proc and storage.spell2 ~= "" and (currentTime - lastUseTime.spell2) >= cooldown then
            say(storage.spell2)
            lastUseTime.spell2 = currentTime
        end
    end
end)

macro(10, "", function()
    if healWindow.healSpellsEnabled.spell3 then
        local proc = tonumber(storage.spell3Proc) or 0
        local cooldown = tonumber(storage.cooldown3) or 100
        local currentTime = now
        if hppercent() <= proc and storage.spell3 ~= "" and (currentTime - lastUseTime.spell3) >= cooldown then
            say(storage.spell3)
            lastUseTime.spell3 = currentTime
        end
    end
end)

macro(10, "", function()
    if healWindow.healSpellsEnabled.spell4 then
        local proc = tonumber(storage.spell4Proc) or 0
        local cooldown = tonumber(storage.cooldown4) or 100
        local currentTime = now
        if hppercent() <= proc and storage.spell4 ~= "" and (currentTime - lastUseTime.spell4) >= cooldown then
            say(storage.spell4)
            lastUseTime.spell4 = currentTime
        end
    end
end)
