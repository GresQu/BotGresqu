setDefaultTab("HP")

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
 UI.Label("Mana Training") 
if type(storage.manaTrain) ~= "table" then
  storage.manaTrain = {on=false, title="MP%", text="Power Down", min=80, max=100}
end

local manatrainmacro = macro(1000, function()
if not storage.manaTrain.text then storage.targetName = 'Power Down' end
  local mana = math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
  if storage.manaTrain.max >= mana and mana >= storage.manaTrain.min then
    say(storage.manaTrain.text)
  end
end)
manatrainmacro.setOn(storage.manaTrain.on)

UI.DualScrollPanel(storage.manaTrain, function(widget, newParams) 
  storage.manaTrain = newParams
    manatrainmacro.setOn(storage.manaTrain.on)
end)
