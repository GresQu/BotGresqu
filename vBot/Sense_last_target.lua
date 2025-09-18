setDefaultTab("Tools")
-- tools tab
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
-- Bezpieczna własna przestrzeń storage
if not storage.senseTracker then
  storage.senseTracker = {
    targetName = '', -- Zmienna resetowana na początek
    targetHistory = {},
    spellName = "sense" -- Domyślnie ustawiamy "sense" jako czar
  }
end

setDefaultTab("Tools")

local SenseLabel = UI.Label("Press Esc to reset\n")

-- Funkcja czyszcząca historię targetów
function clearRecentTargets()
  storage.senseTracker.targetHistory = {}
  -- Zaktualizuj label
  SenseLabel:setText("Press Esc to reset\n")
end

-- Przycisk do czyszczenia historii targetów
UI.Button("Clear Recent Targets", function()
  clearRecentTargets()
end)

-- UITextEdit do wpisania nazwy czaru
local spellNameEdit = UI.TextEdit(storage.senseTracker.spellName or "sense", function(widget, newText)
  storage.senseTracker.spellName = newText
end)
spellNameEdit:setWidth(200) -- Można dostosować szerokość

-- Separator UI

SenseMacro = macro(2500, "Sense LastTarget", function()
  if g_game.isAttacking() then
    local targetCreature = g_game.getAttackingCreature()

    -- Sprawdź, czy atakowany obiekt to gracz
    if targetCreature and targetCreature:isPlayer() then -- Dodano sprawdzenie czy targetCreature nie jest nil
      local name = targetCreature:getName()

      -- Zapisz aktualny target tylko jeśli to gracz
      storage.senseTracker.targetName = name

      -- Dodaj do historii, jeśli nowy
      local history = storage.senseTracker.targetHistory
      if #history == 0 or history[#history] ~= name then
        table.insert(history, name)

        -- Limit 5 ostatnich
        if #history > 5 then
          table.remove(history, 1)
        end
      end
    end -- Jeśli targetCreature nie jest graczem (np. potworem), nie zmieniamy storage.senseTracker.targetName
    
    if not SenseMacro:isOn() then
      resetSenseTracker()
    end
    -- Usunięto 'return' stąd, aby umożliwić 'say' poniżej, jeśli warunki są spełnione
  end -- Koniec bloku 'if g_game.isAttacking() then'

  -- Jeśli mamy zapamiętanego gracza (targetName nie jest pusty) i aktualnie nie atakujemy LUB atakujemy potwora
  -- to rzucamy czar na zapamiętanego gracza.
  -- Sprawdzamy, czy aktualnie atakowany cel to potwór, aby nie przerywać sensowania gracza.
  local currentTarget = g_game.getAttackingCreature()
  local currentlyAttackingMonster = false
  if currentTarget and not currentTarget:isPlayer() then
    currentlyAttackingMonster = true
  end

  if storage.senseTracker.targetName and storage.senseTracker.targetName:len() >= 1 and (not g_game.isAttacking() or currentlyAttackingMonster) then
    say(storage.senseTracker.spellName .. ' "' .. storage.senseTracker.targetName .. '"')
  end

  -- Aktualizacja labela
  local text = "Press Esc to reset\n"
  for i, n in ipairs(storage.senseTracker.targetHistory) do
    text = text .. i .. ". " .. n .. "\n"
  end
  SenseLabel:setText(text)
end)

local key = "Escape"
onKeyPress(function(keys)
  if (keys == key) then
    -- Resetuj tylko aktualny target
    storage.senseTracker.targetName = ""
  end
end)

-- Funkcja kontrolująca wyłączenie makra
function resetSenseTracker()
  -- Resetujemy targetName oraz historię
  storage.senseTracker.targetName = ""
  storage.senseTracker.targetHistory = {}
  SenseLabel:setText("Press Esc to reset\n")
end


