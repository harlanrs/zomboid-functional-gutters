require "ISUI/ISPanelJoypad"

require "FG_UI_GutterInfoPanel"
require "FG_UI_CollectorInfoPanel"
require "FG_UI_PrintMediaPage"

local utils = require("FG_Utils")
local options = require("FG_Options")
local enums = require("FG_Enums")
local serviceUtils = require("FG_Utils_Service")

FG_UI_GutterPanel = ISPanelJoypad:derive("FG_UI_GutterPanel")
FG_UI_GutterPanel.players = {}
FG_UI_GutterPanel.cheatSkill = false
FG_UI_GutterPanel.cheatTransfer = false

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local GOOD_COLOR = getCore():getGoodHighlitedColor()

function FG_UI_GutterPanel.OpenPanel(_player, _gutterDrain, _source)
    if not _player then
        utils:modPrint("FG_UI_GutterPanel not provided a valid player.")
        return
    end

    if not _gutterDrain or not utils:isDrainPipe(_gutterDrain) then
        utils:modPrint("FG_UI_GutterPanel not provided a valid gutter.")
        return
    end

    local playerNum = _player:getPlayerNum()

    local x = getMouseX() + 10
    local y = getMouseY() + 10
    local adjustPos = true

    if FG_UI_GutterPanel.players[playerNum] then
        if FG_UI_GutterPanel.players[playerNum].instance then
            FG_UI_GutterPanel.players[playerNum].instance:close()
            if FG_UI_GutterPanel.players[playerNum].x and FG_UI_GutterPanel.players[playerNum].y then
                x = FG_UI_GutterPanel.players[playerNum].x
                y = FG_UI_GutterPanel.players[playerNum].y
                adjustPos = false
            end
        end
    else
        FG_UI_GutterPanel.players[playerNum] = {}
    end

    local ui = FG_UI_GutterPanel:new(x, y, _player, _gutterDrain)
    ui:initialise()
    ui:instantiate()
    ui:setVisible(true)
    ui:addToUIManager()

    FG_UI_GutterPanel.players[playerNum].instance = ui

    --first time open panel and isoobject then middle of screen.
    if getJoypadData(playerNum) or (adjustPos) then
        ui:centerOnScreen(playerNum)
        FG_UI_GutterPanel.players[playerNum].x = ui.x
        FG_UI_GutterPanel.players[playerNum].y = ui.y
    end

    if getJoypadData(playerNum) then
        setJoypadFocus(playerNum, ui)
    end
end

function FG_UI_GutterPanel:initialise()
    ISPanelJoypad.initialise(self)

    self:reloadCollector()
    self:reloadInfo()

    self.eventWrapper = function(square)
        self:onUpdateGutterTile(square)
    end

    Events.OnGutterTileUpdate.Add(self.eventWrapper)
end

function FG_UI_GutterPanel:addCollectorInfoPanel()
    local x, y = UI_BORDER_SPACING+1, self.gutterPanel:getBottom() + UI_BORDER_SPACING
    self.collectorPanel = FG_UI_CollectorInfoPanel:new(x, y, self.player, self.gutterDrain, self.collector)
    self.collectorPanel:initialise()
    self.collectorPanel:noBackground()
    self.collectorPanel.borderOuterColor = {r=0.4, g=0.4, b=0.4, a=0}
    self:addChild(self.collectorPanel)

    if self.collectorPanel.itemDropBox then
        self.collectorPanel.itemDropBox.isLocked = true
        self.collectorPanel.itemDropBox.doInvalidHighlight = false
        if self.owner then
            self.collectorPanel.itemDropBox:setStoredItem( self.owner )
        end
    end
end

function FG_UI_GutterPanel:addGutterInfoPanel()
    local x = UI_BORDER_SPACING+1
    local y = UI_BORDER_SPACING+1 + BUTTON_HGT + UI_BORDER_SPACING
    self.gutterPanel = FG_UI_GutterInfoPanel:new(x, y, 300, 150, self.gutterDrain, self.gutterSection)
    self:addChild(self.gutterPanel)
end

function FG_UI_GutterPanel:createChildren()
    ISPanelJoypad.createChildren(self)

    self:addGutterInfoPanel()
    self:addCollectorInfoPanel()

    -- Ensure gutter plane is above the collector panel to cover tile texture overlap
    self.gutterPanel:bringToTop()

    local closeW = 20
    local closeH = 20
    local closeX = self:getRight() - closeW
    local closeY = UI_BORDER_SPACING+1
    self.btnClose = ISButton:new(closeX, closeY, closeW, closeH, "X", self, FG_UI_GutterPanel.onButton)
    self.btnClose.internal = "CLOSE"
    self.btnClose:initialise()
    self.btnClose:enableCancelColor()
    self:addChild(self.btnClose)

    local infoW = 20
    local infoH = 20
    local infoX = closeX - UI_BORDER_SPACING - infoW
    local infoY = UI_BORDER_SPACING+1
    self.btnInfo = ISButton:new(infoX, infoY, infoW, infoH, "", self, FG_UI_GutterPanel.onButton)
    self.btnInfo.internal = "INFO"
    self.btnInfo.borderColor.a = 0.0
	self.btnInfo.backgroundColor.a = 0
	self.btnInfo.backgroundColorMouseOver.a = 0
    self.btnInfo:setImage(self.btnInfoTexture)
    self.btnInfo:initialise()
    self:addChild(self.btnInfo)

    local buildW = 20
    local buildH = 20
    local buildX = infoX - UI_BORDER_SPACING - buildW
    local buildY = UI_BORDER_SPACING+1
    self.btnBuild = ISButton:new(buildX, buildY, buildW, buildH, "", self, FG_UI_GutterPanel.onButton)
    self.btnBuild.internal = "BUILD"
    self.btnBuild.borderColor.a = 0.0
	self.btnBuild.backgroundColor.a = 0
	self.btnBuild.backgroundColorMouseOver.a = 0
    self.btnBuild.forcedWidthImage = 12
    self.btnBuild.forcedHeightImage = 12
    self.btnBuild:setImage(self.btnBuildTexture)
    self.btnBuild:initialise()
    self:addChild(self.btnBuild)

    local toggleX = UI_BORDER_SPACING+1
    local toggleY = self.collectorPanel:getBottom() + UI_BORDER_SPACING
    local toggleW = self.collectorPanel:getWidth()
    self.btnToggleConnect = ISButton:new(toggleX, toggleY, toggleW, BUTTON_HGT, "Connect", self, FG_UI_GutterPanel.onButton)
    self.btnToggleConnect.internal = "TOGGLE_CONNECT"
    self.btnToggleConnect:initialise()
    self:styleToggleButton()
    self:addChild(self.btnToggleConnect)

    self:setHeight(self.btnToggleConnect:getBottom() + UI_BORDER_SPACING+1)

    self:checkCanPlumb()
end

function FG_UI_GutterPanel:prerender()
    ISPanelJoypad.prerender(self)

    -- Draws a background for button that marks action progress if action exists.
    if self.btnToggleConnect then
        local x = self.btnToggleConnect:getX()
        local y = self.btnToggleConnect:getY()
        local w = self.btnToggleConnect:getWidth()
        local h = self.btnToggleConnect:getHeight()
        local borderColor = self.btnToggleConnect.borderColor
        self:drawRect(x, y, w, h, 1.0, 0, 0, 0)
        if self.action and self.action.action then
            w = w * self.action:getJobDelta()
            self:drawRect(x, y, w, h, .5, borderColor.r, borderColor.g, borderColor.b)
        end
    end
end

function FG_UI_GutterPanel:render()
    self:renderJoypadFocus()

    local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING + 1
    self:drawText(getText("UI_panel_FunctionalGutters_panel_title"), x, y, 1, 1, 1, 1, UIFont.Medium)
end

function FG_UI_GutterPanel:validatePanel()
    if not self.collector then
        return
    end

    if self.action then
        if ISTimedActionQueue.hasAction(self.action) then
            self.disableConnect = true
        else
            self.action = false
            self.disableConnect = false

            self:reloadCollectorInfoPanel()
        end
    else
        if not self.disableConnect then
            self:styleToggleButton()
        end
    end

    if not self.canPlumb then
        self.btnToggleConnect.enabled = false
    else
        self.btnToggleConnect.enabled = not self.disableConnect
    end
end

function FG_UI_GutterPanel:alignElements()
    local childPanelW = 300
    local mainPanelW = 300 + (2 * UI_BORDER_SPACING)
    if self.width > mainPanelW then
        self:setWidth(mainPanelW)
    end

    if self.gutterPanel.width > childPanelW then
        self.gutterPanel.width = childPanelW
    end

    if self.collectorPanel.width > childPanelW then
        self.collectorPanel.width = childPanelW
    end

    self.btnToggleConnect:setWidth(childPanelW)
    local closeX = childPanelW - UI_BORDER_SPACING - 1
    self.btnClose:setX(closeX)
    self.btnInfo:setX(self.btnClose.x - UI_BORDER_SPACING - 20)
    self.btnBuild:setX(self.btnInfo.x - UI_BORDER_SPACING - 20)
end

function FG_UI_GutterPanel:update()
    -- Range check for gutter drain square
    if self.gutterSquare and self.player then
        local dist = 10
        if self.player:getX() < self.gutterSquare:getX()-dist or self.player:getX() > self.gutterSquare:getX()+dist or self.player:getY() < self.gutterSquare:getY()-dist or self.player:getY() > self.gutterSquare:getY()+dist then
            self:close()
            return
        end
    end

    if not self.gutterDrain or not self.gutterSquare then
        self:close()
        return
    end

    self:validatePanel()
    self:alignElements()
end

function FG_UI_GutterPanel:close()
    if self.player then
        local playerNum = self.player:getPlayerNum()
        if FG_UI_GutterPanel.players[playerNum] then
            FG_UI_GutterPanel.players[playerNum].x = self:getX()
            FG_UI_GutterPanel.players[playerNum].y = self:getY()
        end
        if JoypadState.players[playerNum+1] then
            setJoypadFocus(playerNum, nil)
        end
    end

    -- Remove event listener
    Events.OnGutterTileUpdate.Remove(self.eventWrapper)

    -- Cleanup panels
    self.gutterPanel:close()
    self.collectorPanel:close()
    -- if self.infoPanel then
    --     self.infoPanel:close()
    -- end

    self:setVisible(false)
    self:removeFromUIManager()
end

function FG_UI_GutterPanel:openInfoPage()
    local win = PZAPI.UI.PrintMedia{
        x = 730, y = 100,
    }
    local val = "KnoxKnews_July1_Classifieds_Gutter"
    win.media_id = val
    win.data = getText("Print_Media_" .. val .. "_info")
    win.children.bar.children.name.text = getText("Print_Media_" .. val .. "_title")
    win.textTitle = getText("Print_Text_" .. val .. "_title")
    win.textData = string.gsub(getText("Print_Text_" .. val .. "_info"), "\\n", "\n")

    win:instantiate()
    win.javaObj:setAlwaysOnTop(false)
    local playerNum = self.player:getPlayerNum()
    if getJoypadData(playerNum) then
        ISAtomUIJoypad.Apply(win)
        win.close = function(self)
            UIManager.RemoveElement(self.javaObj)
            if getJoypadData(self.playerNum) then
                setJoypadFocus(self.playerNum, self.prevFocus)
            end
        end
        win.children.bar.children.closeButton.onLeftClick = function(_self)
            getSoundManager():playUISound(_self.sounds.activate)
            _self.parent.parent:close()
        end
        win.playerNum = playerNum
        win.prevFocus = getJoypadData(playerNum).focus
        win.onJoypadDown = function(self, button, joypadData)
            if button == Joypad.BButton then
                self.children.bar.children.closeButton:onLeftClick()
            end
            if button == Joypad.XButton then
                self:onClickNewspaperButton()
            end
            if button == Joypad.YButton then
                self:onClickMapButton()
            end
        end
        setJoypadFocus(playerNum, win)
    end
end

function FG_UI_GutterPanel:onButton(_btn)
    if _btn.internal=="CLOSE" then
        self:close()
    elseif _btn.internal=="INFO" then
        self:openInfoPage()
    elseif _btn.internal=="BUILD" then
        ISEntityUI.OpenBuildWindow(self.player, nil, "*")
        local buildMenu = ISEntityUI.players[self.player:getPlayerNum()].windows["BuildWindow"]
        if not buildMenu or not buildMenu.instance then return end

        local recipeFilterPanel = buildMenu.instance.BuildPanel.recipesPanel.recipeFilterPanel

        -- NOTE: need to set the filter as well since setting the text here doesn't appear to trigger the filter
        local searchFilter = getText("UI_craft_FunctionalGutters_search_filter")
        recipeFilterPanel.entryBox:setText(searchFilter)
        buildMenu.instance.BuildPanel:setRecipeFilter(searchFilter)

        local recipeListPanel = buildMenu.instance.BuildPanel.recipesPanel.recipeListPanel.recipeListPanel
        local items = recipeListPanel.items
        if items and #items > 0 then
            buildMenu.instance.BuildPanel.logic:setRecipe(items[1].item)
        end
    elseif _btn.internal=="TOGGLE_CONNECT" and self.collector then
        self.primaryCollector = serviceUtils:getPrimaryCollector(self.collector)
        if not self.primaryCollector then
            return
        end

        if utils:getModDataIsGutterConnected(self.primaryCollector) then
            self:DoDisconnectCollector()
        else
            self:DoConnectCollector()
        end
    end
end

function FG_UI_GutterPanel:styleToggleButton()
    if self.collector and not self.primaryCollector then
        self.primaryCollector = serviceUtils:getPrimaryCollector(self.collector)
    end

    if not self.collector or not self.primaryCollector then
        self.btnToggleConnect.title = getText("UI_context_menu_FunctionalGutters_ConnectContainer")
        self.btnToggleConnect.tooltip = getText("UI_panel_FunctionalGutters_section_Collector_icon_tooltip_error")
        self.btnToggleConnect:setEnable(false)
        self.disableConnect = true
        return
    end

    if self.canPlumb then
        self.disableConnect = false
        self.btnToggleConnect.tooltip = nil
        self.btnToggleConnect:setEnable(true)

        if not utils:getModDataIsGutterConnected(self.primaryCollector) then
            self.btnToggleConnect.title = getText("UI_context_menu_FunctionalGutters_ConnectContainer")
            self.btnToggleConnect:enableAcceptColor()
        else
            self.btnToggleConnect.title = getText("UI_context_menu_FunctionalGutters_DisconnectContainer")
            local bgC = self.btnDefault.backgroundColor
            local bgCMO = self.btnDefault.backgroundColorMouseOver
            local bC = self.btnDefault.borderColor
            self.btnToggleConnect:setBackgroundRGBA(bgC.r, bgC.g, bgC.b, bgC.a)
            self.btnToggleConnect:setBackgroundColorMouseOverRGBA(bgCMO.r, bgCMO.g, bgCMO.b, bgCMO.a)
            self.btnToggleConnect:setBorderRGBA(bC.r, bC.g, bC.b, bC.a)
        end
    else
        self.disableConnect = true
        self.btnToggleConnect:setEnable(false)
        self.btnToggleConnect.tooltip = getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench"))
    end
end

function FG_UI_GutterPanel:checkCanPlumb()
    if options:getRequireWrench() then
        local wrench = utils:playerGetItem(self.player:getInventory(), "PipeWrench")
        if not wrench then
            self.canPlumb = false
            return self.canPlumb
        end
    end
    self.canPlumb = true
    return self.canPlumb
end

function FG_UI_GutterPanel:DoConnectCollector()
    -- NOTE: using collector instead of primaryCollector because we need to provide the object on the same tile as the drain pipe
    -- This will be swapped for primaryCollector inside the method if the object is a multi-tile trough
    if not self:checkCanPlumb() or not self.collector or self.disableConnect then return end
    self.btnToggleConnect.title = getText("UI_panel_FunctionalGutters_section_Collector_btn_connecting")

    if luautils.walkAdj(self.player, self.gutterSquare, true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(self.player:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(self.player, self.player:getPrimaryHandItem(), wrench, true)
                self.action = FG_TA_ConnectContainer:new(self.player, self.collector, wrench)
                ISTimedActionQueue.add(self.action)
            end
        else
            self.action = FG_TA_ConnectContainer:new(self.player, self.collector, nil)
            ISTimedActionQueue.add(self.action)
        end
    end
end

function FG_UI_GutterPanel:DoDisconnectCollector()
    -- NOTE: using collector instead of primaryCollector because we need to provide the object on the same tile as the drain pipe
    -- This will be swapped for primaryCollector inside the method if the object is a multi-tile trough
    if not self:checkCanPlumb() or not self.collector or self.disableConnect then return end
    self.btnToggleConnect.title = getText("UI_panel_FunctionalGutters_section_Collector_btn_disconnecting")

    if luautils.walkAdj(self.player, self.gutterSquare, true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(self.player:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(self.player, self.player:getPrimaryHandItem(), wrench, true)
                self.action = FG_TA_DisconnectContainer:new(self.player, self.collector, wrench)
                ISTimedActionQueue.add(self.action)
            end
        else
            self.action = FG_TA_DisconnectContainer:new(self.player, self.collector, nil)
            ISTimedActionQueue.add(self.action)
        end
    end
end

function FG_UI_GutterPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self:setISButtonForB(self.btnClose)
end

function FG_UI_GutterPanel:reloadGutterInfoPanel()
    local refreshGutterHighlight = self.gutterPanel.gutterHighlight
    if refreshGutterHighlight then
        self.gutterPanel:highlightGutterObjects(false)
    end

    local refreshRoofHighlight = self.gutterPanel.roofAreaHighlight
    if refreshRoofHighlight then
        self.gutterPanel:highlightRoofArea(false)
    end

    self.gutterPanel.gutterDrain = self.gutterDrain -- TODO rename gutter -> drainPipe
    self.gutterPanel.gutterSection = self.gutterSection
    self.gutterPanel:reloadInfo()

    if refreshGutterHighlight then
        self.gutterPanel:highlightGutterObjects(true)
    end

    if refreshRoofHighlight then
        self.gutterPanel:highlightRoofArea(true)
    end
end

function FG_UI_GutterPanel:reloadCollectorInfoPanel(full)
    if full then
        self.collectorPanel.collector = self.collector
    end

    if self.collectorPanel then
        self.collectorPanel:reloadInfo(full)
    end
end

function FG_UI_GutterPanel:reloadInfo()
    _, self.gutterDrain, _, _ = utils:getSpriteCategoryMemberOnTile(self.gutterSquare, enums.pipeType.drain)
    if not self.gutterDrain then
        self:close()
        return
    end

    self.gutterSection = serviceUtils:calculateGutterSection(self.gutterSquare)
    if not self.gutterSection then
        self:close()
        return
    end

    self:checkCanPlumb()
end

function FG_UI_GutterPanel:reloadCollector()
    local squareCollector
    local squareObjects = self.gutterSquare:getObjects()
    for i = 0, squareObjects:size() - 1 do
        local object = squareObjects:get(i)
        if serviceUtils:isValidCollectorObject(object) then
            squareCollector = object
            break
        end
    end
    self.collector = squareCollector
    self.primaryCollector = self.collector and serviceUtils:getPrimaryCollector(squareCollector) or nil
    self.primaryCollectorSquare = self.primaryCollector and self.primaryCollector:getSquare() or nil
end

function FG_UI_GutterPanel:onUpdateGutterTile(square)
    local squareID = square:getID()
    local gutterSquareID = self.gutterSquare:getID()
    if squareID == gutterSquareID or (self.primaryCollectorSquare and squareID == self.primaryCollectorSquare:getID()) then
        if not utils:isDrainPipeSquare(self.gutterSquare) then
            -- Gutter no longer exists on square so close the panel
            self:close()
            return
        end

        local prevCollector = self.collector
        self:reloadCollector() -- TODO rename or be more explicit for panel reloads

        if not self.collector and prevCollector then
            -- Collector removed from square - refresh the panel
            self:styleToggleButton()
            self:reloadCollectorInfoPanel(true)
        elseif self.collector and not prevCollector then
            -- Collector added to square - refresh the panel
            self:styleToggleButton()
            self:reloadCollectorInfoPanel(true)
        else
            -- Potential collector data update so do partial refresh of panel
            self:reloadInfo()
            self:reloadGutterInfoPanel()
            self:reloadCollectorInfoPanel(nil)
        end
    else
        -- Updated gutter tile wasn't primary drain square
        -- Potentially could be new pipe or other related change to the gutter system so still want to reload data
        -- Event could theoretically not be related to this specific gutter section but easier to just do redundant work in these rare cases
        self:reloadCollector()
        self:reloadInfo()
        self:reloadGutterInfoPanel()
        self:reloadCollectorInfoPanel(nil)
    end
end

function FG_UI_GutterPanel:new(x, y, _player, _gutterDrain)
    local w = 300 + (2 * UI_BORDER_SPACING)
    local h = 600
    local o = ISPanelJoypad.new(self, x, y, w, h)
    o.variableColor={r=0.9, g=0.55, b=0.1, a=1} -- TODO remove
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.btnDefault = {
        borderColor = {r=0.7, g=0.7, b=0.7, a=1},
	    backgroundColor = {r=0, g=0, b=0, a=0.25},
	    backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0.5}
    }
    o.textColor = {r=1,g=1,b=1,a=1}
    o.tagColor = {r=0.8,g=0.8,b=0.8,a=1}
    o.invalidColor = {r=0.6,g=0.2,b=0.2,a=1}
    o.goodColor = {r=GOOD_COLOR:getR(), g=GOOD_COLOR:getG(), b=GOOD_COLOR:getB(), a=1}
    o.transferColor = {r=0.0, g=1.0, b=0.0, a=0.5}

    o.btnInfoTexture = getTexture("media/ui/Entity/blueprint_info.png")
    o.btnBuildTexture = getTexture("media/ui/Entity/Crafting_Keep_24.png")
    o.btnBuildTexture2 = getTexture("media/ui/Entity/Icon_Tools_48x48.png")

    o.moveWithMouse = true
    o.player = _player
    o.gutterDrain = _gutterDrain
    o.gutterSquare = o.gutterDrain:getSquare()

    o.gutterPanel = nil
    o.collectorPanel = nil

    o.action = nil
    o.disableConnect = false
    o.canPlumb = false

    return o
end


