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

-- Container = FluidContainer instance
function FG_UI_GutterPanel.OpenPanel(_player, _gutter, _container, _source)
   -- _container = ISFluidContainer:new(_container);

    -- TODO gutter object not container
    -- if _container and not ISFluidUtil.validateContainer(_container) then
    --     print("GutterPanelUI not a valid (ISFluidContainer) container?")
    --     return;
    -- end

    -- -- TODO
    -- if _container and not _container:isValid() then
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

    local ui = FG_UI_GutterPanel:new(x,y, 400, 600, _player, _gutter, _container);
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
    -- local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING+1;
    local x, y = UI_BORDER_SPACING+1, self.gutterPanel:getBottom() + UI_BORDER_SPACING;

    -- self.panelText = getText("Fluid_Info_Panel");
    self.collectorPanel = FG_UI_CollectorInfoPanel:new(x, y, self.player, self.uiContainer, true, true, self.isIsoPanel);
    self.collectorPanel.customTitle = "";
    self.collectorPanel.title = "";
    self.collectorPanel.doTitle = false;
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
    local w = self:getWidth() - (UI_BORDER_SPACING * 2);
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
    local closeW = 20;
    local closeY = UI_BORDER_SPACING+1;
    self.btnClose = ISButton:new(closeX, closeY, closeW, 20, btnText, self, FG_UI_GutterPanel.onButton);
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
    if not utils:getModDataIsGutterConnected(self.container, nil) then
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

    self:addChild(self.toggleConnectBtn);

    self:setWidth(self.collectorPanel:getRight() + UI_BORDER_SPACING + 1);
    self:setHeight(self.toggleConnectBtn:getBottom() + UI_BORDER_SPACING+1);
end

function FG_UI_GutterPanel:renderContainerInfo()
    local baseRainFactor = self.baseRainFactor
    if self.containerInfo.baseRainFactor.cache~=baseRainFactor then
        self.containerInfo.baseRainFactor.cache = baseRainFactor;
        self.containerInfo.baseRainFactor.value = baseRainFactor == 0.0 and "0.0" or tostring(round(baseRainFactor, 2));
    end

    local gutterRainFactor = self.gutterRainFactor;
    if self.containerInfo.gutterRainFactor.cache~=gutterRainFactor then
        self.containerInfo.gutterRainFactor.cache = gutterRainFactor;
        self.containerInfo.gutterRainFactor.value = gutterRainFactor == 0.0 and "0.0" or tostring(round(gutterRainFactor, 2));
    end

    local totalRainFactor = self.totalRainFactor;
    if self.containerInfo.totalRainFactor.cache~=totalRainFactor then
        self.containerInfo.totalRainFactor.cache = totalRainFactor;
        self.containerInfo.totalRainFactor.value = totalRainFactor == 0.0 and "0.0" or tostring(round(totalRainFactor, 2));
    end

    -- local tagWid = math.max(
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.baseRainFactor.tag),
    --     -- getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.gutterRainFactor.tag),
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.totalRainFactor.tag)
    -- )

    local x = self.collectorPanel:getWidth() - (3 * UI_BORDER_SPACING) - 2;
    local y = self.collectorPanel:getBottom() - UI_BORDER_SPACING - UI_BORDER_SPACING;
    local tagX = x
    local valX = tagX + UI_BORDER_SPACING;

    local c = self.tagColor;
    self:renderText(self.containerInfo.totalRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.isGutterConnected and self.goodColor or self.textColor;
    self:renderText(self.containerInfo.totalRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y - BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.containerInfo.baseRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.containerInfo.baseRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small);

    -- y = y + BUTTON_HGT;
    -- c = self.tagColor;
    -- self:renderText(self.containerInfo.gutterRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    -- c = self.textColor;
    -- self:renderText(self.containerInfo.gutterRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small);
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

    self:renderContainerInfo()
end

function FG_UI_GutterPanel:validatePanel()
    self.disableConnect = false;
    if self.action then
        if ISTimedActionQueue.hasAction(self.action) then
            self.disableConnect = true;
        else
            self.action = false;
            self.disableConnect = false;

            self:reloadInfo();
        end
    else
        if not self.disableConnect then
            -- TODO isValid check for container
            if not utils:getModDataIsGutterConnected(self.container, nil) then
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
    self:setWidth(self.collectorPanel.width + UI_BORDER_SPACING*2+2);
    self.gutterPanel:setWidth(self.collectorPanel.width);
    self.btnClose:setX(self.collectorPanel.width - UI_BORDER_SPACING - 1);
    self.toggleConnectBtn:setWidth(self.collectorPanel.width)
end

function FG_UI_GutterPanel:update()
    --range check for isoPanels.
    if self.isIsoPanel then
        if ISFluidUtil.validateContainer(self.uiContainer) and self.owner and self.owner:getSquare() and self.player then
            local square = self.owner:getSquare();
            local dist = ISFluidUtil.isoMaxPanelDist;
            if self.player:getX() < square:getX()-dist or self.player:getX() > square:getX()+dist or self.player:getY() < square:getY()-dist or self.player:getY() > square:getY()+dist then
                self:close();
                return
            end
        else
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

    -- Cleanup panels
    self.gutterPanel:close()

    self:setVisible(false);
    self:removeFromUIManager();
end

function FG_UI_GutterPanel:onButton(_btn)
    if _btn.internal=="CLOSE" then
        self:close()
    elseif _btn.internal=="TOGGLE_CONNECT" then
        if utils:getModDataIsGutterConnected(self.container, nil) then
            self:DoDisconnectCollector()
        else
            self:DoConnectCollector()
        end
    end
end

function FG_UI_GutterPanel:DoConnectCollector()
    self.toggleConnectBtn.title = "Connecting...";

    if luautils.walkAdj(self.player, self.container:getSquare(), true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(self.player:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(self.player, self.player:getPrimaryHandItem(), wrench, true)
                self.action = FG_TA_ConnectContainer:new(self.player, self.container, wrench)
                ISTimedActionQueue.add(self.action)

            end
        else
            self.action = FG_TA_ConnectContainer:new(self.player, self.container, nil)
            ISTimedActionQueue.add(self.action)
        end
    end
end

function FG_UI_GutterPanel:DoDisconnectCollector()
    self.toggleConnectBtn.title = "Disconnecting...";

    if luautils.walkAdj(self.player, self.container:getSquare(), true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(self.player:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(self.player, self.player:getPrimaryHandItem(), wrench, true)
                self.action = FG_TA_DisconnectContainer:new(self.player, self.container, wrench)
                ISTimedActionQueue.add(self.action)
            end
        else
            self.action = FG_TA_DisconnectContainer:new(self.player, self.container, nil)
            ISTimedActionQueue.add(self.action)
        end
    end
end

function FG_UI_GutterPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self:setISButtonForB(self.btnClose)
end

function FG_UI_GutterPanel:reloadInfo()
    self.baseRainFactor = utils:getModDataBaseRainFactor(self.container);
    self.gutterRainFactor = serviceUtils:calculateGutterSystemRainFactor(self.gutter:getSquare());
    local fluidContainer = self.container:getFluidContainer();
    if fluidContainer then
        self.totalRainFactor = fluidContainer:getRainCatcher();
    else
        self.totalRainFactor = 0.0;
    end
    self.isGutterConnected = utils:getModDataIsGutterConnected(self.container, nil);
end

function FG_UI_GutterPanel:renderText(_s, _x, _y, _r, _g, _b, _a, _font, _func)
    local alpha = 1.0;
    if _func then
        _func(self, _s, _x+1, _y-1, 0, 0, 0, alpha, _font);
        _func(self, _s, _x+1, _y+1, 0, 0, 0, alpha, _font);
        _func(self, _s, _x-1, _y+1, 0, 0, 0, alpha, _font);
        _func(self, _s, _x-1, _y-1, 0, 0, 0, alpha, _font);
        _func(self, _s, _x, _y, _r, _g, _b, _a, _font);
    else
        self:drawText(_s, _x+1, _y-1, 0, 0, 0, alpha, _font);
        self:drawText(_s, _x+1, _y+1, 0, 0, 0, alpha, _font);
        self:drawText(_s, _x-1, _y+1, 0, 0, 0, alpha, _font);
        self:drawText(_s, _x-1, _y-1, 0, 0, 0, alpha, _font);
        self:drawText(_s, _x, _y, _r, _g, _b, _a, _font);
    end
end

function FG_UI_GutterPanel:new(x, y, width, height, _player, _gutter, _container)
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
    o.container = _container;

    o.gutterPanel = nil;
    o.collectorPanel = nil;
    o.uiContainer = ISFluidContainer:new(_container:getFluidContainer()) or nil;
    o.owner = o.uiContainer:getOwner();
    o.isIsoPanel = o.uiContainer:isIsoPanel(); -- instanceof(_container:getOwner(), "IsoObject");

    o.action = nil;
    o.disableConnect = false;
    o.isGutterConnected = false;

    o:reloadInfo(o);

    o.containerInfo = {
        baseRainFactor = { tag = "Base Rain Factor"..": ", value = "0.0", cache = 0.0 },
        gutterRainFactor = { tag = "Gutter Rain Factor"..": ", value = "0.0", cache = 0.0 },
        totalRainFactor = { tag = "Total Rain Factor"..": ", value = "0.0", cache = 0.0 },
    }

    return o;
end