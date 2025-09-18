-- Script to create profile selector buttons using setupUI and OTML
UI.Separator()
-- Ensure this script can be reloaded for development/testing
if g_profileSelectorPanel and g_profileSelectorPanel.destroy then
  g_profileSelectorPanel:destroy()
  g_profileSelectorPanel = nil
end

g_profileSelectorPanel = nil 

function initProfileSelectorUI()
  if not g_ui or not setupUI or not setDefaultTab or not UI or not UI.Separator then
    -- Silently return if essential functions are missing
    return
  end

local sep = UI.Separator()
sep:setHeight(4)
sep:setBackgroundColor('#A0B0C0')
  setDefaultTab("Main")
  
  local panelPadding = 5 -- Used for left, right, and bottom internal padding, and spacing around label/buttons
  local labelTopInternalMargin = 0 -- Specific margin for the label from the panel's top content edge
  
  local buttonWidth = 30
  local buttonHeight = 20
  local spacing = 2
  local buttonsPerRow = 5
  local numRows = 2

  local labelText = "Select Profile"
  local labelHeight = 15
  local spaceBelowLabel = 5

  local buttonsAreaWidth = (buttonsPerRow * buttonWidth) + ((buttonsPerRow - 1) * spacing)
  local buttonsAreaHeight = (numRows * buttonHeight) + ((numRows - 1) * spacing)

  local panelTotalWidth = buttonsAreaWidth + (2 * panelPadding) -- Left and Right padding
  -- Height: label's top margin + label height + space below label + buttons area height + bottom panel padding
  local panelTotalHeight = labelTopInternalMargin + labelHeight + spaceBelowLabel + buttonsAreaHeight + panelPadding

  local otmlLines = {}

  table.insert(otmlLines, "Panel")
  table.insert(otmlLines, string.format("  width: %d", panelTotalWidth))
  table.insert(otmlLines, string.format("  height: %d", panelTotalHeight))
  table.insert(otmlLines, "  margin-top: 2") -- Panel's own margin, kept from previous version
  table.insert(otmlLines, "  margin-left: 10")

  -- Add Label with text wrapping
  table.insert(otmlLines, "  Label")
  table.insert(otmlLines, "    id: profileSelectorInfoLabel")
  table.insert(otmlLines, string.format("    text: %s", labelText))
  table.insert(otmlLines, "    anchors.top: parent.top")
  table.insert(otmlLines, "    anchors.left: parent.left")
  table.insert(otmlLines, "    anchors.right: parent.right")
  table.insert(otmlLines, string.format("    margin-top: %d", labelTopInternalMargin)) -- Use specific top margin for label
  table.insert(otmlLines, string.format("    margin-left: %d", panelPadding)) -- Still use panelPadding for L/R
  table.insert(otmlLines, string.format("    margin-right: %d", panelPadding))
  table.insert(otmlLines, string.format("    height: %d", labelHeight))
  table.insert(otmlLines, "    text-align: center")
  table.insert(otmlLines, "    text-wrap: true")
  table.insert(otmlLines, "    text-auto-resize: true")

  local buttonsStartActualMarginTop = labelTopInternalMargin + labelHeight + spaceBelowLabel

  for i = 1, 10 do
    local row = math.floor((i - 1) / buttonsPerRow)
    local col = (i - 1) % buttonsPerRow
    local marginLeft = panelPadding + col * (buttonWidth + spacing) -- Buttons still use panelPadding for their left start
    local currentButtonMarginTop = buttonsStartActualMarginTop + row * (buttonHeight + spacing)

    table.insert(otmlLines, "  Button")
    table.insert(otmlLines, string.format("    id: profileButton%d", i))
    table.insert(otmlLines, string.format("    text: P%d", i))
    table.insert(otmlLines, string.format("    width: %d", buttonWidth))
    table.insert(otmlLines, string.format("    height: %d", buttonHeight))
    table.insert(otmlLines, "    anchors.left: parent.left")
    table.insert(otmlLines, "    anchors.top: parent.top")
    table.insert(otmlLines, string.format("    margin-left: %d", marginLeft))
    table.insert(otmlLines, string.format("    margin-top: %d", currentButtonMarginTop))
  end

  local finalOtml = table.concat(otmlLines, "\n")

  g_profileSelectorPanel = setupUI(finalOtml)

  if not g_profileSelectorPanel then
    return
  end
  
  g_profileSelectorPanel:setId('profileSelectorPanel')
  
  for i = 1, 10 do
    local buttonId = 'profileButton' .. i
    local buttonWidget = g_profileSelectorPanel:getChildById(buttonId)
    if buttonWidget then
      local profileNum = i
      buttonWidget.onClick = function()
        if ProfileChanger and ProfileChanger.changeProfile then
          ProfileChanger.changeProfile(profileNum)
        end
      end
    end
  end
end

function terminateProfileSelectorUI()
  if g_profileSelectorPanel and g_profileSelectorPanel.destroy then
    g_profileSelectorPanel:destroy()
    g_profileSelectorPanel = nil
  end
end

-- Initialize the UI when the script is loaded
initProfileSelectorUI()
