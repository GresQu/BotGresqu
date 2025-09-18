    -- Dodaj separator i tytuł w interfejsie
    setDefaultTab("Main")
    local sep = UI.Separator()
    sep:setHeight(4)
    sep:setBackgroundColor('#A0B0C0')
    MainSpell1 = UI.Label("- Spell Settings -")
    MainSpell1:setColor("green")
    local sep = UI.Separator()
    sep:setHeight(4)
    sep:setBackgroundColor('#A0B0C0')

healfriend_macro = macro(200, "Friend Healer AoE", function()
  -- Ensure storage variables have default values if not set
  if not storage.friendName then storage.friendName = '' end -- Default to empty string
  if not storage.healFriendPercent then storage.healFriendPercent = "85" end
  if not storage.friend_range then storage.friend_range = "2" end
  if not storage.friendSpellName then storage.friendSpellName = "spell_name_here" end
  if not storage.healFriendDelay then storage.healFriendDelay = "200" end

  for i, spec in pairs(getSpectators()) do
    if isFriend(spec) then -- Use the updated isFriend function from vlib.lua
      if spec:getHealthPercent() <= tonumber(storage.healFriendPercent) then
		if tonumber(storage.friend_range) and getDistanceBetween(player:getPosition(), spec:getPosition()) <= tonumber(storage.friend_range) then
        say(storage.friendSpellName)
        delay(tonumber(storage.healFriendDelay))
	  end
      end
    end
  end
end)

healfriend_macro_with_name = macro(200, "Friend Healer With Name", function()
  -- Ensure storage variables have default values if not set
  if not storage.friendName then storage.friendName = '' end -- Default to empty string
  if not storage.healFriendPercent then storage.healFriendPercent = "85" end
  if not storage.friend_range then storage.friend_range = "2" end
  if not storage.friendSpellName then storage.friendSpellName = "spell_name_here" end
  if not storage.healFriendDelay then storage.healFriendDelay = "200" end

  for i, spec in pairs(getSpectators()) do
    if isFriend(spec) then -- Use the updated isFriend function from vlib.lua
      if spec:getHealthPercent() <= tonumber(storage.healFriendPercent) then
        if tonumber(storage.friend_range) and getDistanceBetween(player:getPosition(), spec:getPosition()) <= tonumber(storage.friend_range) then
          -- Używamy dynamicznej nazwy czaru, dodając 'friendname' do storage.friendSpellName
          local spellWithName = storage.friendSpellName .. ' "' .. spec:getName() .. '"' -- Added closing quote for the name
          say(spellWithName)
          delay(tonumber(storage.healFriendDelay))
        end
      end
    end
  end
end)

local showEdit = false
UI.Button("Hide/Show", function(widget)
  showEdit = not showEdit
    if showEdit then
	UID19:show()
	UID20:show()
	UID21:show()
	UFID21:show()
	UID22:show()
	UFID22:show()
	UID23:show()
	UID24:show()
	else
	UID19:hide()
	UID20:hide()
	UID21:hide()
	UFID21:hide()
	UID22:hide()
	UFID22:hide()
	UID23:hide()
	UID24:hide()
	end
end)

UID19 = UI.Label("Spell_Name:")
UID19:hide()
UID20 = UI.TextEdit(storage.friendSpellName or "Spell_Name", function(widget, newText)
  storage.friendSpellName = newText
end)
UID20:hide()
UID21 = UI.Label("Friend_%HP:")
UID21:hide()
UID22 = UI.TextEdit(storage.healFriendPercent or "85", function(widget, newText)
  storage.healFriendPercent = newText
end)
UID22:hide()
UFID21 = UI.Label("Friend_Range:")
UFID21:hide()
UFID22 = UI.TextEdit(storage.friend_range or "2", function(widget, newText)
  storage.friend_range = newText
end)
UFID22:hide()
UID23 = UI.Label("Delay")
UID23:hide()
UID24 = UI.TextEdit(storage.healFriendDelay or "200", function(widget, newText)
  storage.healFriendDelay = newText
end)
UID24:hide()
