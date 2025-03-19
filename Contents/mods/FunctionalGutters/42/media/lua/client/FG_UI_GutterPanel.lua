require "ISUI/ISPanelJoypad"

local utils = require("FG_Utils")

FG_UI_GutterPanel = ISPanelJoypad:derive("FG_UI_GutterPanel");
FG_UI_GutterPanel.players = {};
FG_UI_GutterPanel.cheatSkill = false;
FG_UI_GutterPanel.cheatTransfer = false;

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

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

    local ui = FG_UI_GutterPanel:new(x,y,400,600, _player, _gutter, _container);
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

    self.panelText = getText("Fluid_Info_Panel");
    self.panel = ISFluidContainerPanel:new(x, y, self.player, self.uiContainer, true, true, self.isIsoPanel);
    self.panel.customTitle = "";
    self.panel.title = "";
    self.panel.doTitle = false;
    self.panel:initialise();
    self.panel:instantiate();
    self.panel:noBackground();
    self.panel.borderOuterColor = {r=0.4, g=0.4, b=0.4, a=0};
    self:addChild(self.panel);

    if self.panel.itemDropBox then
        self.panel.itemDropBox.isLocked = true;
        self.panel.itemDropBox.doInvalidHighlight = false;
        if self.owner then
            self.panel.itemDropBox:setStoredItem( self.owner )
        end
    end
end

function FG_UI_GutterPanel:addGutterInfoPanel()
    local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING+1;
    -- local x, y = UI_BORDER_SPACING+1, self.panel:getBottom() + UI_BORDER_SPACING;
    -- local w = self.panel:getWidth();
    local w = self:getWidth() + UI_BORDER_SPACING*2+2;
    self.gutterPanel = FG_UI_GutterInfoPanel:new(x, y, 300, 200, self.gutter);
    self:addChild(self.gutterPanel);
end

function FG_UI_GutterPanel:createChildren()
    ISPanelJoypad.createChildren(self);

    self:addGutterInfoPanel();
    self:addCollectorPanel();

    self.gutterPanel:bringToTop();

    local toggleX = self.width - 100;
    -- local toggleY = self.gutterPanel:getBottom() + UI_BORDER_SPACING;
    local toggleY = self.panel:getBottom() - BUTTON_HGT - UI_BORDER_SPACING;
    self.toggleConnectBtn = ISButton:new(toggleX, toggleY, 100, BUTTON_HGT, "Connect", self, FG_UI_GutterPanel.onButton);
    self.toggleConnectBtn.internal = "TOGGLE_CONNECT";
    self.toggleConnectBtn:initialise();
    self.toggleConnectBtn:instantiate();
    self:addChild(self.toggleConnectBtn);

    self.panelX = self.panel:getX();
    local w = self.panel:getWidth();
    local y = self.panel:getBottom() + UI_BORDER_SPACING

    local btnText = "Close";
    self.btnClose = ISButton:new(UI_BORDER_SPACING+1, y, w, BUTTON_HGT, btnText, self, FG_UI_GutterPanel.onButton);
    self.btnClose.internal = "CLOSE";
    self.btnClose:initialise();
    self.btnClose:instantiate();
    self.btnClose:enableCancelColor()
    self:addChild(self.btnClose);

    self:setWidth(self.panel:getRight() + UI_BORDER_SPACING + 1);
    self:setHeight(self.btnClose:getBottom() + UI_BORDER_SPACING+1);
end

function FG_UI_GutterPanel:prerender()
    ISPanelJoypad.prerender(self);
end

function FG_UI_GutterPanel:render()
    self:renderJoypadFocus()
end

function FG_UI_GutterPanel:update()
    --range check for isoPanels.
    -- if self.isIsoPanel then
    --     if ISFluidUtil.validateContainer(self.container) and self.owner and self.owner:getSquare() and self.player then
    --         local square = self.owner:getSquare();
    --         local dist = ISFluidUtil.isoMaxPanelDist;
    --         if self.player:getX() < square:getX()-dist or self.player:getX() > square:getX()+dist or self.player:getY() < square:getY()-dist or self.player:getY() > square:getY()+dist then
    --             self:close();
    --             return
    --         end
    --     else
    --         self:close();
    --         return
    --     end
    -- end
    self:setWidth(self.panel.width + UI_BORDER_SPACING*2+2);
    self.gutterPanel:setWidth(self.panel.width);
    self.toggleConnectBtn:setX(self.panel.width - 100);
    self.btnClose:setWidth(self.panel.width)
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
        utils:modPrint("TODO toggle connect")
    end
end

function FG_UI_GutterPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self:setISButtonForB(self.btnClose)
end

function FG_UI_GutterPanel:new(x, y, width, height, _player, _gutter, _container)
    local o = ISPanelJoypad.new(self, x, y, 400, height);
    o.variableColor={r=0.9, g=0.55, b=0.1, a=1};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
    o.transferColor = {r=0.0, g=1.0, b=0.0, a=0.5}; -- TODO  remove artifacts from ISFluidPanel
    o.zOffsetSmallFont = 25;
    o.moveWithMouse = true;
    o.player = _player;
    o.gutter = _gutter;
    o.container = _container;
    o.uiContainer = ISFluidContainer:new(_container:getFluidContainer()) or nil;
    o.owner = o.uiContainer:getOwner();
    o.isIsoPanel = o.uiContainer:isIsoPanel(); -- instanceof(_container:getOwner(), "IsoObject");

    return o;
end