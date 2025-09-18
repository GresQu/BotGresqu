setDefaultTab("Main")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
UI.Button("Friend List", function(newText) -- Botón para anadir la lista de players
  UI.MultilineEditorWindow(storage.friendName or "xxxx", {title="Friend List", description="Friend list like Magebot\nExample:\nPlayer1\nPlayer2\nPlayer3"}, function(text)
    storage.friendName = text
    if vBot and vBot.clearFriendCache then
      vBot.clearFriendCache()
    end
  end)
end)

UI.Button("Enemy List", function(newText)
  UI.MultilineEditorWindow(storage.EnemyList or "xxxx", {title="Enemy List", description="Enemy list like Magebot\nExample:\nPlayer1\nPlayer2\nPlayer3"}, function(text)
    storage.EnemyList = text
    if vBot and vBot.clearEnemyCache then
      vBot.clearEnemyCache()
    end
  end)
end)