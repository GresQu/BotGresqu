-- Nadpisanie funkcji warning
warning = function(text)
  -- Sprawdź, czy tekst zawiera wzorzec "Slow macro ("
  if string.find(text, "Slow macro %(") then
    return -- Ignoruj komunikat
  end
  -- Jeśli nie zawiera, przekazuj dalej
  return warn(text)
end

-- Przykładowe wywołania
warning("Slow macro (200ms): Something") -- zostanie zignorowane
warning("Slow macro (999ms): Another line") -- również zignorowane
