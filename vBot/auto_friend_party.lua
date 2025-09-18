setDefaultTab("Main")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local autoParty = macro(10000,'AutoPT_friends_word_"pt"', function() end)
onTalk(function(name, level, mode, text, channelId, pos)
    if autoParty:isOff() then return end
		for i, spec in pairs(getSpectators()) do 
			if isFriend(spec) then -- Use isFriend from vlib.lua
				if string.find(text, "pt") then
					g_game.partyInvite(spec:getId())
				end
			end
		end
end)
