require "ISUI/ISPanel"

FG_UI_IconTooltip = ISPanel:derive("FG_UI_IconTooltip");

function FG_UI_IconTooltip:initialise()
    ISPanel.initialise(self)
end

function FG_UI_IconTooltip:createChildren()
end

function FG_UI_IconTooltip:render()
    ISPanel.render(self);

    local c;
    -- Base backdrop.
    self:drawRect(0, 0, self.width, self.height, 1.0, 0, 0, 0);

    self.innerX = 2;
    self.innerY = 2;
    self.innerW = self.width-4;
    self.innerH = self.height-4;

    -- draw overlaying ui parts
    c = self.detailInnerColor;
    self:drawRectBorder(1, 1, self.width-2, self.height-2, c.a, c.r, c.g, c.b);
    c = self.borderColor;
    self:drawRectBorder(0, 0, self.width, self.height, c.a, c.r, c.g, c.b);
end



function FG_UI_IconTooltip:setIcon(icon)
    self.icon = icon;
end

function FG_UI_IconTooltip:setTooltipText(text)
    self.text = text;
end

function FG_UI_IconTooltip:prerender()
    ISPanel.prerender(self);

    if self.toolTip and not self:isMouseOver() then
        self:deactivateToolTip();
    end
end

function FG_UI_IconTooltip:onMouseMove(dx, dy)
    if self:isMouseOver() then
        self:activateToolTip();
    else
        self:deactivateToolTip();
    end
end

function FG_UI_IconTooltip:onMouseMoveOutside(dx, dy)
    self:deactivateToolTip();
end

function FG_UI_IconTooltip:activateToolTip()
    if self.doToolTip then
        if self.toolTip ~= nil then
            self.toolTip:setVisible(true);
            self.toolTip:addToUIManager();
            self.toolTip:bringToTop()
        else
            local container = self.container;
            if self.containerMixed then
                container = self.containerMixed; --todo make this based of what the mouse is over, and add self.containerAdd
            end
            if self.resource then
                --override with resource if set
                container = self.resource;
            end
            if not container then
                return;
            end
            self.toolTip = ISToolTipInv:new(container);
            self.toolTip:initialise();
            self.toolTip:setVisible(true);
            self.toolTip:addToUIManager();
            self.toolTip:setOwner(self);
            self.toolTip:setCharacter(self.player);
            --self.toolTip:doLayout();
        end
    end
end
function FG_UI_IconTooltip:deactivateToolTip()
    if self.toolTip then
        self.toolTip:removeFromUIManager();
        self.toolTip:setVisible(false);
        self.toolTip = nil;
    end
end

function FG_UI_IconTooltip:new (x, y, width, height, _player, _resource)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = false;
    o.backgroundColor = {r=0, g=0, b=0, a=0.0};
    o.borderColor = {r=0.6, g=0.6, b=0.6, a=1};
    o.detailInnerColor = {r=0,g=0,b=0,a=1}
    o.width = width;
    o.height = height;
    o.anchorLeft = false;
    o.anchorRight = false;
    o.anchorTop = false;
    o.anchorBottom = false;
    o.player = _player;

    o.ratioOrig = 0;
    o.ratioNew = 0;
    o.drawMeasures = true;
    o.doToolTip = true;
    o.resource = _resource;
    return o
end