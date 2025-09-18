setDefaultTab("Tools")
local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')

macro(60000, "Send message on trade", function()
if not storage.autoTradeMessage then storage.targetName = 'Text' end
  local trade = getChannelId("Advertising")
  if not trade then
    trade = getChannelId("trade")
  end
  if trade and storage.autoTradeMessage:len() > 0 then    
    sayChannel(trade, storage.autoTradeMessage)
  end
end)
UI.TextEdit(storage.autoTradeMessage or "Text", function(widget, text)    
  storage.autoTradeMessage = text
end)
