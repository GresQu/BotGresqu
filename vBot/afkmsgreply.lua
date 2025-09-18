local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
local afkMsg = false
addSwitch("afkMsg", "REPLY AFK", function(widget)
    afkMsg = not afkMsg
    widget:setOn(afkMsg)
end)

onTalk(function(name, level, mode, text, channelId, pos) --quando receber uma pm vai responder com a mensagem escolhida abaixo
    if mode == 4 and afkMsg == true then
        g_game.talkPrivate(5, name, storage.afkMsg)
        delay(5000)
    end
end)
UI.TextEdit(storage.afkMsg or "afk", function(widget, newText)
storage.afkMsg = newText
end)


