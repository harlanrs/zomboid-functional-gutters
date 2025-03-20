require "ISUI/ISPanelJoypad"

require "FG_UI_GutterInfoPanel"
require "FG_UI_CollectorInfoPanel"

local utils = require("FG_Utils")
local options = require("FG_Options")
local enums = require("FG_Enums")
local serviceUtils = require("FG_Utils_Service")

FG_UI_GutterPanel = ISPanelJoypad:derive("FG_UI_GutterPanel");
FG_UI_GutterPanel.players = {};
FG_UI_GutterPanel.cheatSkill = false;
FG_UI_GutterPanel.cheatTransfer = false;

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local GOOD_COLOR = getCore():getGoodHighlitedColor()

function FG_UI_GutterPanel.OpenPanel(_player, _gutter, _collector, _source)
   -- _collector = ISFluidContainer:new(_collector);

    -- TODO gutter object not container
    -- if _collector and not ISFluidUtil.validateContainer(_collector) then
    --     print("GutterPanelUI not a valid (ISFluidContainer) container?")
    --     return;
    -- end

    -- -- TODO
    -- if _collector and not _collector:isValid() then
    --     print("GutterPanelUI container nil or has no owner.")
    --     return;
    -- end
    if not _player then
        print("GutterPanelUI no valid player.")
        return;
    end
    --print("Opening Fluid Transfer UI");
    local playerNum = _player:getPlayerNum();

    local x = getMouseX() + 10;
    local y = getMouseY() + 10;
    local adjustPos = true;

    if FG_UI_GutterPanel.players[playerNum] then
        if FG_UI_GutterPanel.players[playerNum].instance then
            FG_UI_GutterPanel.players[playerNum].instance:close();
            if FG_UI_GutterPanel.players[playerNum].x and FG_UI_GutterPanel.players[playerNum].y then
                x = FG_UI_GutterPanel.players[playerNum].x;
                y = FG_UI_GutterPanel.players[playerNum].y;
                adjustPos = false;
            end
        end
    else
        FG_UI_GutterPanel.players[playerNum] = {};
    end

    local ui = FG_UI_GutterPanel:new(x,y, 400, 600, _player, _gutter, _collector);
    ui:initialise();
    ui:instantiate();
    ui:setVisible(true);
    ui:addToUIManager();

    FG_UI_GutterPanel.players[playerNum].instance = ui;

    --first time open panel and isoobject then middle of screen.
    if getJoypadData(playerNum) or (adjustPos and ui.isIsoPanel) then
        ui:centerOnScreen(playerNum)
        FG_UI_GutterPanel.players[playerNum].x = ui.x;
        FG_UI_GutterPanel.players[playerNum].y = ui.y;
    end

    if getJoypadData(playerNum) then
        setJoypadFocus(playerNum, ui);
    end
end

-- INIT --
function FG_UI_GutterPanel:initialise()
    ISPanelJoypad.initialise(self);
end

function FG_UI_GutterPanel:addCollectorPanel()
    local x, y = UI_BORDER_SPACING+1, self.gutterPanel:getBottom() + UI_BORDER_SPACING;

    self.collectorPanel = FG_UI_CollectorInfoPanel:new(x, y, self.player, self.gutter, self.collector, self.isIsoPanel);
    -- self.collectorPanel.customTitle = "";
    -- self.collectorPanel.title = "";
    self.collectorPanel:initialise();
    self.collectorPanel:instantiate();
    self.collectorPanel:noBackground();
    self.collectorPanel.borderOuterColor = {r=0.4, g=0.4, b=0.4, a=0};
    self:addChild(self.collectorPanel);

    if self.collectorPanel.itemDropBox then
        self.collectorPanel.itemDropBox.isLocked = true;
        self.collectorPanel.itemDropBox.doInvalidHighlight = false;
        if self.owner then
            self.collectorPanel.itemDropBox:setStoredItem( self.owner )
        end
    end
end

function FG_UI_GutterPanel:addGutterInfoPanel()
    local x = UI_BORDER_SPACING+1;
    local y = UI_BORDER_SPACING+1 + BUTTON_HGT + UI_BORDER_SPACING;
    -- local w = self:getWidth() - (UI_BORDER_SPACING * 2);
    self.gutterPanel = FG_UI_GutterInfoPanel:new(x, y, 300, 150, self.gutter);
    self:addChild(self.gutterPanel);
end

function FG_UI_GutterPanel:createChildren()
    ISPanelJoypad.createChildren(self);

    self:addGutterInfoPanel();
    self:addCollectorPanel();

    self.gutterPanel:bringToTop();

    local btnText = "X";
    local closeX = self:getRight() - 20;
    local closeY = UI_BORDER_SPACING+1;
    local closeW = 20;
    local closeH = 20;
    self.btnClose = ISButton:new(closeX, closeY, closeW, closeH, btnText, self, FG_UI_GutterPanel.onButton);
    self.btnClose.internal = "CLOSE";
    self.btnClose:initialise();
    self.btnClose:instantiate();
    self.btnClose:enableCancelColor()
    self:addChild(self.btnClose);

    local toggleX = UI_BORDER_SPACING+1;
    local toggleY = self.collectorPanel:getBottom() + UI_BORDER_SPACING;
    local toggleW = self.collectorPanel:getWidth();
    self.toggleConnectBtn = ISButton:new(toggleX, toggleY, toggleW, BUTTON_HGT, "Connect", self, FG_UI_GutterPanel.onButton);
    self.toggleConnectBtn.internal = "TOGGLE_CONNECT";
    self.toggleConnectBtn:initialise();
    self.toggleConnectBtn:instantiate();

    if self.collector then
        if not utils:getModDataIsGutterConnected(self.collector, nil) then
            self.toggleConnectBtn.title = "Connect";
            self.toggleConnectBtn:enableAcceptColor();
        else
            self.toggleConnectBtn.title = "Disconnect";
            local bgC = self.btnDefault.backgroundColor;
            local bgCMO = self.btnDefault.backgroundColorMouseOver;
            local bC = self.btnDefault.borderColor;
            self.toggleConnectBtn:setBackgroundRGBA(bgC.r, bgC.g, bgC.b, bgC.a);
            self.toggleConnectBtn:setBackgroundColorMouseOverRGBA(bgCMO.r, bgCMO.g, bgCMO.b, bgCMO.a);
            self.toggleConnectBtn:setBorderRGBA(bC.r, bC.g, bC.b, bC.a);
        end
    else
        self.toggleConnectBtn.title = "No Collector";
        self.toggleConnectBtn:setEnable(false);
        self.disableConnect = true;
    end

    self:addChild(self.toggleConnectBtn);

    self:setWidth(self.collectorPanel:getRight() + UI_BORDER_SPACING + 1);
    self:setHeight(self.toggleConnectBtn:getBottom() + UI_BORDER_SPACING+1);
end

function FG_UI_GutterPanel:prerender()
    ISPanelJoypad.prerender(self);

    --draws a background for button that marks action progress if action exists.
    if self.toggleConnectBtn then
        local x = self.toggleConnectBtn:getX();
        local y = self.toggleConnectBtn:getY();
        local w = self.toggleConnectBtn:getWidth();
        local h = self.toggleConnectBtn:getHeight();
        local borderColor = self.toggleConnectBtn.borderColor
        self:drawRect(x, y, w, h, 1.0, 0, 0, 0);
        if self.action and self.action.action then
            -- local c = self.transferColor;
            w = w * self.action:getJobDelta();
            self:drawRect(x, y, w, h, .5, borderColor.r, borderColor.g, borderColor.b);
        end
    end
end

function FG_UI_GutterPanel:render()
    self:renderJoypadFocus()

    local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING + 1;
    self:drawText("Gutter System", x, y, 1, 1, 1, 1, UIFont.Medium);
end

function FG_UI_GutterPanel:validatePanel()
    if not self.collector then
        -- self.disableConnect = true;
        -- self.toggleConnectBtn.title = "No Collector";
        -- self.toggleConnectBtn:setEnable(false);
        return;
    end

    self.disableConnect = false;
    if self.action then
        if ISTimedActionQueue.hasAction(self.action) then
            self.disableConnect = true;
        else
            self.action = false;
            self.disableConnect = false;

            self:reloadCollectorInfo();
        end
    else
        if not self.disableConnect then
            -- TODO isValid check for container
            if not utils:getModDataIsGutterConnected(self.collector, nil) then
                self.toggleConnectBtn.title = "Connect";
                self.toggleConnectBtn:enableAcceptColor();
            else
                self.toggleConnectBtn.title = "Disconnect";
                local bgC = self.btnDefault.backgroundColor
                local bgCMO = self.btnDefault.backgroundColorMouseOver
                local bC = self.btnDefault.borderColor
                self.toggleConnectBtn:setBackgroundRGBA(bgC.r, bgC.g, bgC.b, bgC.a)
                self.toggleConnectBtn:setBackgroundColorMouseOverRGBA(bgCMO.r, bgCMO.g, bgCMO.b, bgCMO.a)
                self.toggleConnectBtn:setBorderRGBA(bC.r, bC.g, bC.b, bC.a)
            end
        end
    end

    self.toggleConnectBtn.enabled = not self.disableConnect;
end

function FG_UI_GutterPanel:alignElements()
    local childPanelW = 300;
    local mainPanelW = 300 + (2 * UI_BORDER_SPACING);
    if self.width > mainPanelW then
        self:setWidth(mainPanelW);
    end

    if self.gutterPanel.width > childPanelW then
        self.gutterPanel.width = childPanelW;
    end

    if self.collectorPanel.width > childPanelW then
        self.collectorPanel.width = childPanelW;
    end

    self.toggleConnectBtn:setWidth(childPanelW);
    self.btnClose:setX(childPanelW - UI_BORDER_SPACING - 1);
end

function FG_UI_GutterPanel:update()
    -- Range check for gutter drain square
    if self.gutterSquare and self.player then
        local dist = 10;
        if self.player:getX() < self.gutterSquare:getX()-dist or self.player:getX() > self.gutterSquare:getX()+dist or self.player:getY() < self.gutterSquare:getY()-dist or self.player:getY() > self.gutterSquare:getY()+dist then
            self:close();
            return
        end
    end

    self:validatePanel();
    self:alignElements();
end

function FG_UI_GutterPanel:close()
    if self.player then
        local playerNum = self.player:getPlayerNum();
        if FG_UI_GutterPanel.players[playerNum] then
            FG_UI_GutterPanel.players[playerNum].x = self:getX();
            FG_UI_GutterPanel.players[playerNum].y = self:getY();
        end
        if JoypadState.players[playerNum+1] then
            setJoypadFocus(playerNum, nil)
        end
    end

    -- Remove event listener
    Events.OnGutterTileUpdate.Remove(self.eventWrapper)

    -- Cleanup panels
    self.gutterPanel:close()
    self.collectorPanel:onClose() -- TODO sync terms

    self:setVisible(false);
    self:removeFromUIManager();
end

function FG_UI_GutterPanel:onButton(_btn)
    if _btn.internal=="CLOSE" then
        self:close()
    elseif _btn.internal=="TOGGLE_CONNECT" and self.collector then
        if utils:getModDataIsGutterConnected(self.collector, nil) then
            self:DoDisconnectCollector()
        else
            self:DoConnectCollector()
        end
    end
end

function FG_UI_GutterPanel:DoConnectCollector()
    if not self.collector then return end
    self.toggleConnectBtn.title = "Connecting...";

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
    if not self.collector then return end
    self.toggleConnectBtn.title = "Disconnecting...";

    if luautils.walkAdj(self.player, self.collector:getSquare(), true) then
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

function FG_UI_GutterPanel:reloadCollectorInfo(full)
    if full then
        self.collectorPanel.collector = self.collector;
    end

    if self.collectorPanel then
        self.collectorPanel:reloadInfo(full);
    end

    if self.collector then
        self.isGutterConnected = utils:getModDataIsGutterConnected(self.collector, nil);
    end
end

function FG_UI_GutterPanel:onUpdateGutterTile(square)
    if self.gutterSquare:getID() == square:getID() then
        if not utils:checkPropIsDrainPipe(square) then
            -- Gutter no longer exists on square so close the panel
            self:close();
            return;
        end

        -- TODO handle multi-tile troughs
        local squareCollector
        local squareObjects = square:getObjects()
        for i = 0, squareObjects:size() - 1 do
            local object = squareObjects:get(i)
            if serviceUtils:isValidContainerObject(object) then
                squareCollector = object
                break
            end
        end

        -- TODO consolidate some of this logic to init and destroy methods for the collector
        if not squareCollector and self.collector then
            -- Collector removed from square - refresh the panel
            self.collector = nil
            self.disableConnect = true
            self.toggleConnectBtn.title = "No Collector";
            self.toggleConnectBtn:setEnable(false);
            self:reloadCollectorInfo(true)
        elseif squareCollector and not self.collector then
            -- Collector added to square - refresh the panel
            self.collector = squareCollector
            self.disableConnect = false;
            self.toggleConnectBtn.title = "Connect";
            self.toggleConnectBtn:setEnable(true);
            self.toggleConnectBtn:enableAcceptColor();
            self:reloadCollectorInfo(true)
        end
    end
end

function FG_UI_GutterPanel:new(x, y, width, height, _player, _gutter, _collector)
    local w = 300 + (2 * UI_BORDER_SPACING);
    local o = ISPanelJoypad.new(self, x, y, w, height);
    o.variableColor={r=0.9, g=0.55, b=0.1, a=1}; -- TODO remove
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
    o.btnDefault = {
        borderColor = {r=0.7, g=0.7, b=0.7, a=1};
	    backgroundColor = {r=0, g=0, b=0, a=0.25};
	    backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0.5};
    }
    o.textColor = {r=1,g=1,b=1,a=1}
    o.tagColor = {r=0.8,g=0.8,b=0.8,a=1}
    o.invalidColor = {r=0.6,g=0.2,b=0.2,a=1}
    o.goodColor = {r=GOOD_COLOR:getR(), g=GOOD_COLOR:getG(), b=GOOD_COLOR:getB(), a=1}
    o.transferColor = {r=0.0, g=1.0, b=0.0, a=0.5};

    o.zOffsetSmallFont = 25;
    o.moveWithMouse = true;
    o.player = _player;
    o.gutter = _gutter;
    o.collector = _collector;
    o.gutterSquare = o.gutter:getSquare()

    o.gutterPanel = nil;
    o.collectorPanel = nil;

    o.action = nil;
    o.disableConnect = false;
    o.isGutterConnected = false;

    o.eventWrapper = function(square)
        o:onUpdateGutterTile(square)
    end

    Events.OnGutterTileUpdate.Add(o.eventWrapper)

    return o;
end


