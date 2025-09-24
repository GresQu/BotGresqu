HealSetupWindow < MainWindow
  id: healSetupWindow
  size: 360 200
  visible: false
  draggable: true
  text: Healing Setup
  @onEscape: self:hide()

  Button
    id: closeWindowButton
    !text: tr('X')
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.right: parent.right
    margin-top: -8
    margin-right: 3
    size: 18 18
    color: #FF6347
    @onClick: self:getParent():hide()

  Panel
    id: container
    anchors.fill: parent
    padding: 10

    Label
      id: headerSpellName
      text: Spell Name
      font: verdana-11px-rounded
      anchors.top: parent.top
      anchors.left: parent.left
      width: 100
      text-align: center

    Label
      id: headerHealthPerc
      text: Health %
      font: verdana-11px-rounded
      anchors.top: parent.top
      anchors.left: headerSpellName.right
      margin-left: 5
      width: 50
      text-align: center

    Label
      id: headerEnable
      text: Enable
      font: verdana-11px-rounded
      anchors.top: parent.top
      anchors.left: headerHealthPerc.right
      margin-left: 15
      width: 50
      text-align: center

    Label
      id: headerCooldown
      text: Cooldown (ms)
      font: verdana-11px-rounded
      anchors.top: parent.top
      anchors.left: headerEnable.right
      margin-left: 15
      width: 90
      text-align: center

    Label
      id: spell1Label
      text: Spell 1:
      font: verdana-11px-rounded
      anchors.top: headerSpellName.bottom
      anchors.left: parent.left
      margin-top: 10
      width: 60

    BotTextEdit
      id: spell1
      anchors.top: spell1Label.top
      anchors.left: headerSpellName.left
      width: 100
      height: 20

    BotTextEdit
      id: spell1Proc
      anchors.top: spell1Label.top
      anchors.left: spell1.right
      margin-left: 5
      width: 50
      height: 20

    CheckBox
      id: enableSpell1
      text: ""
      anchors.top: spell1Label.top
      anchors.left: spell1Proc.right
      margin-left: 30
      width: 20
      height: 20
      @onCheckChange: |
        local root = self:getParent():getParent()
        root.healSpellsEnabled.spell1 = self:isChecked()

    BotTextEdit
      id: cooldown1
      anchors.top: spell1Label.top
      anchors.left: enableSpell1.right
      margin-left: 30
      width: 50
      height: 20

    Label
      id: spell2Label
      text: Spell 2:
      font: verdana-11px-rounded
      anchors.top: spell1.bottom
      anchors.left: parent.left
      margin-top: 10
      width: 60

    BotTextEdit
      id: spell2
      anchors.top: spell2Label.top
      anchors.left: headerSpellName.left
      width: 100
      height: 20

    BotTextEdit
      id: spell2Proc
      anchors.top: spell2Label.top
      anchors.left: spell2.right
      margin-left: 5
      width: 50
      height: 20

    CheckBox
      id: enableSpell2
      text: ""
      anchors.top: spell2Label.top
      anchors.left: spell2Proc.right
      margin-left: 30
      width: 20
      height: 20
      @onCheckChange: |
        local root = self:getParent():getParent()
        root.healSpellsEnabled.spell2 = self:isChecked()

    BotTextEdit
      id: cooldown2
      anchors.top: spell2Label.top
      anchors.left: enableSpell2.right
      margin-left: 30
      width: 50
      height: 20

    Label
      id: spell3Label
      text: Spell 3:
      font: verdana-11px-rounded
      anchors.top: spell2.bottom
      anchors.left: parent.left
      margin-top: 10
      width: 60

    BotTextEdit
      id: spell3
      anchors.top: spell3Label.top
      anchors.left: headerSpellName.left
      width: 100
      height: 20

    BotTextEdit
      id: spell3Proc
      anchors.top: spell3Label.top
      anchors.left: spell3.right
      margin-left: 5
      width: 50
      height: 20

    CheckBox
      id: enableSpell3
      text: ""
      anchors.top: spell3Label.top
      anchors.left: spell3Proc.right
      margin-left: 30
      width: 20
      height: 20
      @onCheckChange: |
        local root = self:getParent():getParent()
        root.healSpellsEnabled.spell3 = self:isChecked()

    BotTextEdit
      id: cooldown3
      anchors.top: spell3Label.top
      anchors.left: enableSpell3.right
      margin-left: 30
      width: 50
      height: 20

    Label
      id: spell4Label
      text: Spell 4:
      font: verdana-11px-rounded
      anchors.top: spell3.bottom
      anchors.left: parent.left
      margin-top: 10
      width: 60

    BotTextEdit
      id: spell4
      anchors.top: spell4Label.top
      anchors.left: headerSpellName.left
      width: 100
      height: 20

    BotTextEdit
      id: spell4Proc
      anchors.top: spell4Label.top
      anchors.left: spell4.right
      margin-left: 5
      width: 50
      height: 20

    CheckBox
      id: enableSpell4
      text: ""
      anchors.top: spell4Label.top
      anchors.left: spell4Proc.right
      margin-left: 30
      width: 20
      height: 20
      @onCheckChange: |
        local root = self:getParent():getParent()
        root.healSpellsEnabled.spell4 = self:isChecked()

    BotTextEdit
      id: cooldown4
      anchors.top: spell4Label.top
      anchors.left: enableSpell4.right
      margin-left: 30
      width: 50
      height: 20
