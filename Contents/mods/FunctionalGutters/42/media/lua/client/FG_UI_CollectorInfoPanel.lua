require "ISUI/ISPanel"

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")

require "FG_UI_IconTooltip"

FG_UI_CollectorInfoPanel = ISPanel:derive("FG_UI_GutterInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local GOOD_COLOR = getCore():getGoodHighlitedColor()
local table_insert = table.insert

function FG_UI_CollectorInfoPanel:initialise()
    ISPanel.initialise(self)

    self:reloadInfo()
end

function FG_UI_CollectorInfoPanel:createChildren()
    self.innerHeight = BUTTON_HGT*4+UI_BORDER_SPACING*2+2

    self:getIsoObjectTextures()

    -- local y = 1
    local y = 24 + 2*UI_BORDER_SPACING + 1
    self.innerY = y

    local fluidBarW = 0
    if self.container then
        self.fluidBar = ISFluidBar:new(0, y, BUTTON_HGT, self.innerHeight, self.player)
        self.fluidBar:initialise()
        self:addChild(self.fluidBar)
        fluidBarW = self.fluidBar.width

        if self.container:getFluidContainer() then
            self.fluidBar:setContainer(self.container:getFluidContainer())
        end
    end

    self.containerBox = {
        x = UI_BORDER_SPACING+1+64*2 + UI_BORDER_SPACING,
        y = self.innerY,
        w = self.width - fluidBarW - UI_BORDER_SPACING*1 - 2,
        h = self.innerHeight,
    }

    local iconDesc = getText("UI_panel_FunctionalGutters_section_Roof_icon_tooltip_success")
    local icon = enums.textures.icon.fluidDropOn
    self.fluidIconPanel = FG_UI_IconTooltip:new(self.x, self.y, 24, 24, icon, nil, iconDesc, self.player)
    self.fluidIconPanel:initialise()
    self:addChild(self.fluidIconPanel)

    iconDesc = getText("UI_panel_FunctionalGutters_section_Pipes_icon_tooltip_success")
    icon = enums.textures.icon.plumbOn
    self.plumbIconPanel = FG_UI_IconTooltip:new(self.x, self.y, 24, 24, icon, nil, iconDesc, self.player)
    self.plumbIconPanel:initialise()
    self:addChild(self.plumbIconPanel)

    iconDesc = getText("UI_panel_FunctionalGutters_section_Collector_icon_tooltip_success")
    icon = enums.textures.icon.collectorOn
    self.collectorIconPanel = FG_UI_IconTooltip:new(self.x, self.y, 24, 24, icon, nil, iconDesc, self.player)
    self.collectorIconPanel:initialise()
    self:addChild(self.collectorIconPanel)
end

function FG_UI_CollectorInfoPanel:drawTextureIso(texture, x, y, a, r, g, b)
    if texture and texture:getWidthOrig() == 64 * 2 and texture:getHeightOrig() == 128 * 2 then
        ISUIElement.drawTexture(self, texture, x, y, a, r, g, b)
    else
        ISUIElement.drawTextureScaledUniform(self, texture, x, y, 2.0, a, r, g, b)
    end
end

function FG_UI_CollectorInfoPanel:drawTextureOutlines(texture, x, y)
    local c = self.outlineColor
    self:StartOutline(texture, 0.15, c.r, c.g, c.b, c.a)
    self:drawTextureIso(texture, x, y, 1.0,1.0,1.0,1.0)
    self:EndOutline()
end

function FG_UI_CollectorInfoPanel:prerender()
    ISPanel.prerender(self)

    if self.isInvalid then
        local c = self.invalidColor
        self.borderColor = {r=c.r, b=c.b, g=c.g, a=c.a}
        local w = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2
        self.containerBox.w = w
        self.containerBox.h = self.innerHeight
        self.containerBox.x = self:getWidth() - w - UI_BORDER_SPACING + 1
        self.containerBox.y = self.innerY
        self:drawRect(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, 0.75, 0, 0, 0)

        -- Center image in box
        local imageW = 48
        local imageH = 64
        local imageX = self.containerBox.x + (self.containerBox.w - imageW) / 2
        local imageY = self.containerBox.y + (self.containerBox.h - imageH) / 2
        self:drawTextureScaledStatic(self.missingCollectorTexture, imageX, imageY, imageW, imageH, .5, 1, 1, 1)

        -- Center question mark icon in box
        local iconW = 24
        local iconH = 24
        local iconX = self.containerBox.x + (self.containerBox.w - iconW) / 2
        local iconY = self.containerBox.y + (self.containerBox.h - iconH) / 2
        self:drawTextureScaledStatic(self.missingIconTexture, iconX, iconY, iconW, iconH, 1, 1, 1, .5)

        -- "0/1" text to bottom right of container
        local countText = "0/1"
        c = self.invalidColor
        local countTextW = getTextManager():MeasureStringX(UIFont.Small, countText)
        local countTextX = self.containerBox.x + self.containerBox.w - countTextW - UI_BORDER_SPACING
        local countTextY = self.containerBox.y + self.containerBox.h - FONT_HGT_SMALL - UI_BORDER_SPACING
        self:renderText(countText, countTextX, countTextY, c.r,c.g,c.b,c.a, UIFont.Small)

        -- Add "Missing Collector" text below 
        local text = getText("UI_panel_FunctionalGutters_section_Collector_invalid_MissingCollector")
        c = self.textColor
        local textW = getTextManager():MeasureStringX(UIFont.Small, text)
        local textX = self.containerBox.x + (self.containerBox.w - textW) / 2
        local textY = self.containerBox.y + self.containerBox.h + UI_BORDER_SPACING
        self:renderText(text, textX, textY, c.r,c.g,c.b,c.a, UIFont.Small)
    else
        self.borderColor = {r=0.6, g=0.6, b=0.6, a=1}
        self:drawRect(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, 1.0, 0, 0, 0)
    end

    if not self.drainTexture then
        return
    end

    if self.textureList and #self.textureList > 0 then
        local x = UI_BORDER_SPACING+1
        local y = self:getHeight() - 128*2
        for i = 1, #self.textureList do
            local children = self.textureList[i].children
            local texture = self.textureList[i].texture
            local offsetY = -self.textureList[i].offsetY

            if self.collectorTexture and self.textureList[i].texture == self.collectorTexture then
                self:drawTextureIso(texture, x, y + offsetY, 1)

                if children and #children>0 then
                    for j=1, #children do
                        local childTexture = children[j].texture
                        local childOffsetY = -children[j].offsetY
                        self:drawTextureIso(childTexture, x, y + childOffsetY)
                    end
                end

                if self.doOwnerOutlines then
                    self:drawTextureOutlines(texture, x, y + offsetY)

                    if children and #children>0 then
                        for j=1, #children do
                            local childTexture = children[j].texture
                            local childOffsetY = -children[j].offsetY
                            self:drawTextureOutlines(childTexture, x, y + childOffsetY)
                        end
                    end
                end
            else
                if utils:isDrainPipeSprite(texture:getName()) then
                    self:drawTextureIso(texture, x, y + offsetY, 1)
                else
                    self:drawTextureIso(texture, x, y + offsetY, 0.5)
                end
            end
        end
    end

    -- Draw after textures to ensure icon is on top
    -- Icon Container
    local iconContainerW = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2
    local iconContainerH = 24
    local iconContainerX = self:getRight() - iconContainerW - 2*UI_BORDER_SPACING + 1
    local iconContainerY = 1
    local c = {r=0, g=0, b=0, a=0}
    self:drawRect(iconContainerX, iconContainerY, iconContainerW, iconContainerH, c.a, c.r, c.g, c.b)
    -- self:drawTextureScaled(self.gradientTex, iconContainerX, iconContainerY, iconContainerW, iconContainerH, self.gradientAlpha, 1, 1, 1)
    -- c = self.borderColor
    c = {r=0, g=0, b=0, a=0}
    self:drawRectBorder(iconContainerX, iconContainerY, iconContainerW, iconContainerH, c.a, c.r, c.g, c.b)

    -- Fluid Icon
    local iconW = 24
    local iconX = iconContainerX + 8
    local iconY = iconContainerY + 5
    if self.fluidIconPanel.x ~= iconX or self.fluidIconPanel.y ~= iconY then
        self.fluidIconPanel:setX(iconX)
        self.fluidIconPanel:setY(iconY)
    end

    if self.fluidIconPanel.visible ~= true then
        self.fluidIconPanel:setVisible(true)
    end

    local icon = self.isOutside and enums.textures.icon.fluidDropOn or enums.textures.icon.fluidDropOff
    if self.fluidIconPanel.icon ~= icon then
        local endText = self.isOutside and "success" or "error"
        local tooltipText = getText("UI_panel_FunctionalGutters_section_Roof_icon_tooltip_"..endText)
        self.fluidIconPanel:setDescription(tooltipText)
        self.fluidIconPanel:setIcon(icon)
    end

    -- Plumb Icon
    iconX = iconContainerX + (iconContainerW - iconW) / 2
    if self.plumbIconPanel.x ~= iconX or self.plumbIconPanel.y ~= iconY then
        self.plumbIconPanel:setX(iconX)
        self.plumbIconPanel:setY(iconY)
    end

    if self.plumbIconPanel.visible ~= true then
        self.plumbIconPanel:setVisible(true)
    end

    icon = self.isGutterConnected and enums.textures.icon.plumbOn or enums.textures.icon.plumbOff
    if self.plumbIconPanel.icon ~= icon then
        local endText = self.isGutterConnected and "success" or "error"
        local tooltipText = getText("UI_panel_FunctionalGutters_section_Pipes_icon_tooltip_"..endText)
        self.plumbIconPanel:setDescription(tooltipText)
        self.plumbIconPanel:setIcon(icon)
    end

    -- Collector Icon
    iconX = iconContainerX + iconContainerW - iconW - 8
    if self.collectorIconPanel.x ~= iconX or self.collectorIconPanel.y ~= iconY then
        self.collectorIconPanel:setX(iconX)
        self.collectorIconPanel:setY(iconY)
    end

    if self.collectorIconPanel.visible ~= true then
        self.collectorIconPanel:setVisible(true)
    end

    icon = self.collector and enums.textures.icon.collectorOn or enums.textures.icon.collectorOff
    if self.collectorIconPanel.icon ~= icon then
        local endText = self.collector and "success" or "error"
        local tooltipText = getText("UI_panel_FunctionalGutters_section_Collector_icon_tooltip_"..endText)
        self.collectorIconPanel:setDescription(tooltipText)
        self.collectorIconPanel:setIcon(icon)
    end
end

function FG_UI_CollectorInfoPanel:renderCollectorInfo()
    local baseRainFactor = self.baseRainFactor
    if self.containerInfo.baseRainFactor.cache~=baseRainFactor then
        self.containerInfo.baseRainFactor.cache = baseRainFactor
        self.containerInfo.baseRainFactor.value = (not baseRainFactor or baseRainFactor == 0.0) and "0.0" or tostring(round(baseRainFactor, 2))
    end

    local totalRainFactor = self.totalRainFactor
    if self.containerInfo.totalRainFactor.cache~=totalRainFactor then
        self.containerInfo.totalRainFactor.cache = totalRainFactor
        self.containerInfo.totalRainFactor.value = (not totalRainFactor or totalRainFactor == 0.0) and "0.0" or tostring(round(totalRainFactor, 2))
    end

    -- local tagWid = math.max(
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.baseRainFactor.tag),
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.totalRainFactor.tag)
    -- )

    local x = self.width - (3 * UI_BORDER_SPACING) - 2
    local y = self.containerBox.y + self.containerBox.h + UI_BORDER_SPACING
    local tagX = x
    local valX = tagX + UI_BORDER_SPACING

    local c = self.tagColor
    self:renderText(self.containerInfo.baseRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight)
    c = self.textColor
    self:renderText(self.containerInfo.baseRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small)

    y = y + BUTTON_HGT
    c = self.tagColor
    self:renderText(self.containerInfo.totalRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight)
    c = self.isGutterConnected and self.goodColor or self.textColor
    self:renderText(self.containerInfo.totalRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small)
end

function FG_UI_CollectorInfoPanel:render()
    ISPanel.render(self)

    local c

    if self.doTitle and self.title then
        c = self.textColor
        self:renderText(self.title, self.width/2,UI_BORDER_SPACING+1, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextCentre)
    end

    local name = false

    local x = self.containerBox.x + UI_BORDER_SPACING+1
    local y = self.containerBox.y + UI_BORDER_SPACING+1

    c = self.textColor
    local containerNameRight = x
    if self.containerName then
        self:renderText(self.containerName, x,y+3, c.r,c.g,c.b,c.a,UIFont.Small)
        containerNameRight = x + getTextManager():MeasureStringX(UIFont.Small, self.containerName)
    else
        --try to get containerName automatically.
        if self.container and self.container:getFluidContainer() then
            name = self.container:getFluidContainer():getTranslatedContainerName()
        end

        if name then
            local tx = x
            self:renderText(name, tx, y+3, c.r,c.g,c.b,c.a,UIFont.Small)
            containerNameRight = tx + getTextManager():MeasureStringX(UIFont.Small, name)
        else
            containerNameRight = x + getTextManager():MeasureStringX(UIFont.Small, "Test Name")
        end
    end

    local container = self:getContainer()
    if container then
        local capacity = container:getCapacity()
        local stored = container:getAmount()
        local free = capacity-stored
        if self.containerInfo then
            if self.containerInfo.capacity.cache~=capacity then
                self.containerInfo.capacity.cache = capacity
                self.containerInfo.capacity.value = FluidUtil.getAmountFormatted(capacity)
				if container:isHiddenAmount() then
					self.containerInfo.capacity.value = getText("Fluid_Unknown")
				end
            end
            if self.containerInfo.stored.cache~=stored then
                self.containerInfo.stored.cache = stored
                self.containerInfo.stored.value = FluidUtil.getAmountFormatted(stored)
				if container:isHiddenAmount() then
					self.containerInfo.stored.value = getText("Fluid_Unknown")
				end
            end
            if self.containerInfo.free.cache~=free then
                self.containerInfo.free.cache = free
                self.containerInfo.free.value = FluidUtil.getAmountFormatted(free)
				if container:isHiddenAmount() then
					self.containerInfo.free.value = getText("Fluid_Unknown")
				end
            end

            local tagWid = math.max(
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.capacity.tag),
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.stored.tag),
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.free.tag)
            )
            local tagX = self.containerBox.x + UI_BORDER_SPACING + 1 + tagWid
            local valX = tagX + UI_BORDER_SPACING

            y = self.containerBox.y + self.containerBox.h - FONT_HGT_SMALL - UI_BORDER_SPACING - 4

            c = self.tagColor
            self:renderText(self.containerInfo.free.tag, tagX,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight)
            c = self.textColor
            self:renderText(self.containerInfo.free.value, valX,y, c.r,c.g,c.b,c.a,UIFont.Small)

            y = y - BUTTON_HGT
            c = self.tagColor
            self:renderText(self.containerInfo.stored.tag, tagX,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight)
            c = self.textColor
            self:renderText(self.containerInfo.stored.value, valX,y, c.r,c.g,c.b,c.a,UIFont.Small)

            y = y - BUTTON_HGT
            c = self.tagColor

            self:renderText(self.containerInfo.capacity.tag, tagX,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight)
            c = self.textColor
            self:renderText(self.containerInfo.capacity.value, valX,y, c.r,c.g,c.b,c.a,UIFont.Small)

            local valRight = valX + math.max(
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.capacity.value),
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.stored.value),
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.free.value),
                getTextManager():MeasureStringX(UIFont.Small, "599.9 L") -- prevent panel shifting when the amount includes a decimal point
            )

            self.containerBox.w = math.max(valRight - self.containerBox.x, containerNameRight - self.containerBox.x) + UI_BORDER_SPACING + 1
            self.fluidBar:setX(self.containerBox.x + self.containerBox.w + UI_BORDER_SPACING)
        end

        self:renderCollectorInfo()
	end

    c = self.borderOuterColor
    self:drawRectBorder(0, 0, self.width, self.height, c.a, c.r, c.g, c.b)

    c = self.borderColor
    self:drawRectBorder(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, c.a, c.r, c.g, c.b)
end

function FG_UI_CollectorInfoPanel:renderText(_s, _x, _y, _r, _g, _b, _a, _font, _func)
    local alpha = 1.0
    if _func then
        _func(self, _s, _x+1, _y-1, 0, 0, 0, alpha, _font)
        _func(self, _s, _x+1, _y+1, 0, 0, 0, alpha, _font)
        _func(self, _s, _x-1, _y+1, 0, 0, 0, alpha, _font)
        _func(self, _s, _x-1, _y-1, 0, 0, 0, alpha, _font)
        _func(self, _s, _x, _y, _r, _g, _b, _a, _font)
    else
        self:drawText(_s, _x+1, _y-1, 0, 0, 0, alpha, _font)
        self:drawText(_s, _x+1, _y+1, 0, 0, 0, alpha, _font)
        self:drawText(_s, _x-1, _y+1, 0, 0, 0, alpha, _font)
        self:drawText(_s, _x-1, _y-1, 0, 0, 0, alpha, _font)
        self:drawText(_s, _x, _y, _r, _g, _b, _a, _font)
    end
end

function FG_UI_CollectorInfoPanel:setInvalid(_b)
    self.isInvalid = _b
end

function FG_UI_CollectorInfoPanel:setTitle(_title)
    self.customTitle = _title
end

function FG_UI_CollectorInfoPanel:setContainerName(_name)
    self.containerName = _name
end

function FG_UI_CollectorInfoPanel:getContainer()
    if self.container and self.container:getFluidContainer() then
        return self.container:getFluidContainer()
    end
    return nil
end

function FG_UI_CollectorInfoPanel:getIsoObjectTextures()
    -- Copied from vanilla Fluid Container UI with minor modifications
    self.textureList = {}

    if (not self.gutterDrain) or (not instanceof(self.gutterDrain, "IsoObject")) or (not self.gutterDrain:getTextureName()) then
        return
    end

    self.collectorTexture = self.collector and getTexture( self.collector:getTextureName() ) or nil
    self.drainTexture = self.gutterDrain and getTexture( self.gutterDrain:getTextureName() ) or nil

    if not self.drainTexture then
        return
    end

    local square = self.gutterDrain:getSquare()
    if not square then return end

    if square then
        if square:getFloor() and square:getFloor():getTextureName() and getTexture(square:getFloor():getTextureName()) then
            local t = { texture = getTexture(square:getFloor():getTextureName()), offsetY = 0 }
            table_insert(self.textureList, t)
        end

        local drainTextureTable
        local collectorTextureTable

        for i = 1, square:getObjects():size()-1 do
            local obj = square:getObjects():get(i)
            if obj and obj:getTextureName() and getTexture(obj:getTextureName()) then
                local objTexture = getTexture(obj:getTextureName())
                local t = { texture = objTexture, offsetY = obj:getRenderYOffset() * Core.getTileScale() }

                if objTexture == self.drainTexture then
                    drainTextureTable = t
                elseif objTexture == self.collectorTexture then
                    collectorTextureTable = t
                else
                    table_insert(self.textureList, t)
                end

                local sprList = obj:getChildSprites()
                if sprList and (not instanceof(obj,"IsoBarbecue")) then
                    local list_size 	= sprList:size()
                    if list_size > 0 then
                        t.children = {}
                        for l=list_size-1, 0, -1 do
                            local sprite = sprList:get(l):getParentSprite()
                            if sprite:getName() and getTexture(sprite:getName()) then
                                local child = { texture = getTexture(sprite:getName()), offsetY = obj:getRenderYOffset() * Core.getTileScale() }
                                table_insert(t.children, child)
                            end
                        end
                    end
                end
            end
        end

        -- Add drain and collector textures last to ensure layer ordering
        if drainTextureTable then
            table_insert(self.textureList, drainTextureTable)
        end
        if collectorTextureTable then
            table_insert(self.textureList, collectorTextureTable)
        end
    end

    return self.textureList
end

function FG_UI_CollectorInfoPanel:hasValidContainer()
    if self.container then
        --check if iso still has square
        return ISFluidUtil.validateContainer(self.container)
    end
end

function FG_UI_CollectorInfoPanel:close()

end

function FG_UI_CollectorInfoPanel:reloadInfo(full)
    if self.collector then
        self.primaryCollector = serviceUtils:getPrimaryCollector(self.collector)

        if self.primaryCollector then
            self.baseRainFactor = serviceUtils:getObjectBaseRainFactor(self.primaryCollector)

            local fluidContainer = self.primaryCollector:getFluidContainer()
            self.totalRainFactor = fluidContainer:getRainCatcher()
            self.isGutterConnected = utils:getModDataIsGutterConnected(self.primaryCollector)
        else
            self.baseRainFactor = 0.0
            self.totalRainFactor = 0.0
            self.isGutterConnected = false
        end

        if self.isInvalid then
            self:setInvalid(false)
        end
    else
        self.primaryCollector = nil
        self.baseRainFactor = 0.0
        self.totalRainFactor = 0.0
        self.isGutterConnected = false
        self:setInvalid(true)
    end

    local gutterSquare = self.gutterDrain:getSquare()
    self.isOutside = gutterSquare:isOutside()

    if full then
        self.container = self.primaryCollector and ISFluidContainer:new(self.primaryCollector:getFluidContainer()) or nil
        if self.container then
            self.owner = self.collector
        else
            self.owner = self.gutterDrain
        end
        self:clearChildren()
        self:createChildren()
    end
end

function FG_UI_CollectorInfoPanel:new(x, y, _player, _gutterDrain, _collector)
    local width = 300
    local height = BUTTON_HGT*6+UI_BORDER_SPACING*6+FONT_HGT_SMALL
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.background = false
    o.backgroundColor = {r=0, g=0, b=0, a=0.0}
    o.borderColor = {r=0.6, g=0.6, b=0.6, a=1}
    o.borderOuterColor = {r=0.6, g=0.6, b=0.6, a=1}
    o.detailInnerColor = {r=0,g=0,b=0,a=1}
    o.textColor = {r=1,g=1,b=1,a=1}
    o.tagColor = {r=0.8,g=0.8,b=0.8,a=1}
    o.invalidColor = {r=0.6,g=0.2,b=0.2,a=1}
    o.goodColor = {r=GOOD_COLOR:getR(), g=GOOD_COLOR:getG(), b=GOOD_COLOR:getB(), a=1}
    o.width = width
    o.height = height
    o.anchorLeft = false
    o.anchorRight = false
    o.anchorTop = false
    o.anchorBottom = false
    o.missingCollectorTexture = getTexture("carpentry_02_124")
    o.missingIconTexture = getTexture("media/ui/Entity/BTN_Missing_Icon_48x48.png")
    o.gutterConnectedTexture = getTexture("media/ui/craftingMenus/BuildProperty_Drain.png")
    o.gradientTex = getTexture("media/ui/Fluids/fluid_gradient.png")
    o.gradientAlpha = 0.15

    o.player = _player
    o.gutterDrain = _gutterDrain
    o.collector = _collector
    o.primaryCollector = serviceUtils:getPrimaryCollector(_collector)

    -- Generate ISFluidContainer from the collector iso object
    o.container = o.primaryCollector and ISFluidContainer:new(o.primaryCollector:getFluidContainer()) or nil
    -- Use collector on same square as drain for multi-tile collectors (primarily to get the correct textures)
    o.owner = o.container and o.collector or o.gutterDrain

    -- if true add a title.
    o.doTitle = false -- TODO 
    o.title = "" -- TODO
    o.customTitle = false

    -- TODO remove unused holdovers from copied vanilla fluid panel
    o.funcTarget = false
    o.onContainerAdd = false
    o.overrideAddFull = false
    o.onContainerRemove = false
    o.overrideRemoveFull = false
    o.onContainerVerify = false

    o.doOwnerOutlines = false
    o.outlineColor = {r=0.85,g=0.82,b=0.78,a=1}
    o.containerName = false

    --if set invalid draws invalid background color
    o.isInvalid = false

    o.containerInfo = {
        capacity = { tag = getText("Fluid_Capacity")..": ", value = "0", cache = 0 },
        stored = { tag = getText("Fluid_Stored")..": ", value = "0", cache = 0 },
        free = { tag = getText("Fluid_Free")..": ", value = "0", cache = 0 },
        baseRainFactor = { tag = getText("UI_panel_FunctionalGutters_section_Collector_item_BaseRainFactor")..": ", value = "0.0", cache = 0.0 },
        totalRainFactor = { tag = getText("UI_panel_FunctionalGutters_section_Collector_item_TotalRainFactor")..": ", value = "0.0", cache = 0.0 },
    }

    return o
end