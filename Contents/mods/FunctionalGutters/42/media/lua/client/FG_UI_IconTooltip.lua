require "ISUI/ISPanel"

FG_UI_IconTooltip = ISPanel:derive("FG_UI_IconTooltip")

function FG_UI_IconTooltip:initialise()
    ISPanel.initialise(self)
end

function FG_UI_IconTooltip:createChildren()
end

function FG_UI_IconTooltip:prerender()
    ISPanel.prerender(self)

    if self.toolTip and not self:isMouseOver() then
        self:deactivateToolTip()
    end

    self:drawTextureScaledStatic(self.iconTexture, 0, 0, self.width, self.height, 1, 1, 1, 1)
end

function FG_UI_IconTooltip:render()
    ISPanel.render(self)
end

function FG_UI_IconTooltip:setIcon(icon)
    if self.icon == icon then return end

    self.icon = icon
    self.iconTexture = getTexture(self.icon)
end

function FG_UI_IconTooltip:setTitle(title)
    self.title = title
    if self.toolTip then
        self.toolTip:setName(self.title)
    end
end

function FG_UI_IconTooltip:setDescription(text)
    self.description = text
    if self.toolTip then
        self.toolTip:setDescription(self.description)
    end
end

function FG_UI_IconTooltip:onMouseMove(dx, dy)
    if self:isMouseOver() then
        self:activateToolTip()
    else
        self:deactivateToolTip()
    end
end

function FG_UI_IconTooltip:onMouseMoveOutside(dx, dy)
    self:deactivateToolTip()
end

function FG_UI_IconTooltip:activateToolTip()
    if self.doToolTip then
        if self.toolTip ~= nil then
            self.toolTip:setVisible(true)
            self.toolTip:addToUIManager()
            self.toolTip:setName(self.title)
            self.toolTip:setDescription(self.description)
            self.toolTip:bringToTop()
        else
            self.toolTip = ISToolTip:new()
            self.toolTip.descriptionPanel.backgroundColor = {r=0, g=0, b=0, a=0.5}
            -- self.toolTip.followMouse = false
            self.toolTip:initialise()
            self.toolTip:setVisible(true)
            self.toolTip:addToUIManager()
            self.toolTip:setOwner(self)
        end
    end
end
function FG_UI_IconTooltip:deactivateToolTip()
    if self.toolTip then
        self.toolTip:removeFromUIManager()
        self.toolTip:setVisible(false)
        self.toolTip = nil
    end
end

function FG_UI_IconTooltip:new(x, y, width, height, icon, title, description, _player, _resource)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.background = false
    o.backgroundColor = {r=0, g=0, b=0, a=0.0}
    o.borderColor = {r=0.6, g=0.6, b=0.6, a=1}
    o.detailInnerColor = {r=0,g=0,b=0,a=1}
    o.width = width
    o.height = height
    o.anchorLeft = false
    o.anchorRight = false
    o.anchorTop = false
    o.anchorBottom = false
    o.player = _player
    o.icon = icon
    o.iconTexture = getTexture(o.icon)
    o.title = title
    o.description = description

    o.drawMeasures = true
    o.doToolTip = true
    o.resource = _resource
    return o
end