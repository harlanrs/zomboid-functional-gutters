require "ISUI/ISPanel"

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local serviceUtils = require("FG_Utils_Service")

FG_UI_CollectorInfoPanel = ISPanel:derive("FG_UI_GutterInfoPanel");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local GOOD_COLOR = getCore():getGoodHighlitedColor()

function FG_UI_CollectorInfoPanel:initialise()
    ISPanel.initialise(self)

    self:reloadInfo();
end

function FG_UI_CollectorInfoPanel:createChildren()
    self.innerHeight = BUTTON_HGT*4+UI_BORDER_SPACING*2+2;

    self:getIsoObjectTextures();

    local y = UI_BORDER_SPACING+1;
    -- local y = 0;
    if self.doTitle then
        y = y+FONT_HGT_SMALL+UI_BORDER_SPACING;
    end

    self.innerY = y;

    local fluidBarW = 0;
    if self.container then
        self.fluidBar = ISFluidBar:new(0, y, BUTTON_HGT, self.innerHeight, self.player);
        self.fluidBar:initialise();
        self.fluidBar:instantiate();
        self:addChild(self.fluidBar);
        fluidBarW = self.fluidBar.width;

        if self.container:getFluidContainer() then
            self.fluidBar:setContainer(self.container:getFluidContainer());
        end
    end

    self.containerBox = {
        x = UI_BORDER_SPACING+1+64*2 + UI_BORDER_SPACING,
        y = y,
        w = self.width - fluidBarW - UI_BORDER_SPACING*1 - 2,
        h = self.innerHeight,
    }
end

function FG_UI_CollectorInfoPanel:drawTextureIso(texture, x, y, a, r, g, b)
    if texture and texture:getWidthOrig() == 64 * 2 and texture:getHeightOrig() == 128 * 2 then
        ISUIElement.drawTexture(self, texture, x, y, a, r, g, b)
    else
        ISUIElement.drawTextureScaledUniform(self, texture, x, y, 2.0, a, r, g, b)
    end
end

function FG_UI_CollectorInfoPanel:drawTextureOutlines(texture, x, y)
    local c = self.outlineColor;
    self:StartOutline(texture, 0.15, c.r, c.g, c.b, c.a)
    self:drawTextureIso(texture, x, y, 1.0,1.0,1.0,1.0);
    self:EndOutline();
end

function FG_UI_CollectorInfoPanel:prerender()
    ISPanel.prerender(self);

    if self.isInvalid then
        local c = self.invalidColor;
        self.borderColor = {r=c.r, b=c.b, g=c.g, a=c.a};
        local w = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
        self.containerBox.w = w;
        self.containerBox.h = 80;
        self.containerBox.x = self:getWidth() - w - UI_BORDER_SPACING + 1;
        self.containerBox.y = self.innerY;
        self:drawRect(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, 0.75, 0, 0, 0);

        -- Center image in box
        local imageW = 48;
        local imageH = 64;
        local imageX = self.containerBox.x + (self.containerBox.w - imageW) / 2;
        local imageY = self.containerBox.y + (self.containerBox.h - imageH) / 2;
        self:drawTextureScaledStatic(self.missingCollectorTexture, imageX, imageY, imageW, imageH, .5, 1, 1, 1);

        -- Center question mark icon in box
        local iconW = 24;
        local iconH = 24;
        local iconX = self.containerBox.x + (self.containerBox.w - iconW) / 2;
        local iconY = self.containerBox.y + (self.containerBox.h - iconH) / 2;
        self:drawTextureScaledStatic(self.missingIconTexture, iconX, iconY, iconW, iconH, 1, 1, 1, 1);

        -- "0/1" text to bottom right of container
        local countText = "0/1";
        c = self.invalidColor;
        local countTextW = getTextManager():MeasureStringX(UIFont.Small, countText);
        local countTextX = self.containerBox.x + self.containerBox.w - countTextW - UI_BORDER_SPACING;
        local countTextY = self.containerBox.y + self.containerBox.h - FONT_HGT_SMALL - UI_BORDER_SPACING;
        self:renderText(countText, countTextX, countTextY, c.r,c.g,c.b,c.a, UIFont.Small);

        -- Add "Missing Collector" text below 
        local text = "Gutter Collector";
        c = self.textColor;
        local textW = getTextManager():MeasureStringX(UIFont.Small, text);
        local textX = self.containerBox.x + (self.containerBox.w - textW) / 2;
        local textY = self.containerBox.y + self.containerBox.h + UI_BORDER_SPACING;
        self:renderText(text, textX, textY, c.r,c.g,c.b,c.a, UIFont.Small);
    else
        self.borderColor = {r=0.6, g=0.6, b=0.6, a=1};
        self:drawRect(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, 1.0, 0, 0, 0);
    end

    if (not self.owner) or (not instanceof(self.owner, "IsoObject")) then
        return;
    end
    local ownerOffsetY = self.owner:getRenderYOffset() * Core.getTileScale();

    if self.textureList and #self.textureList > 0 then
        local x = UI_BORDER_SPACING+1;
        local y = self:getHeight() - 128*2;
        for i = 1, #self.textureList do
            local children = self.textureList[i].children;
            local texture = self.textureList[i].texture;
            local offsetY = -self.textureList[i].offsetY;

            if self.textureList[i].texture == self.ownerTexture and self.textureList[i].offsetY == ownerOffsetY then
                self:drawTextureIso(texture, x, y + offsetY, 1);

                if children and #children>0 then
                    for j=1, #children do
                        local childTexture = children[j].texture;
                        local childOffsetY = -children[j].offsetY;
                        self:drawTextureIso(childTexture, x, y + childOffsetY);
                    end
                end

                if self.doOwnerOutlines then
                    self:drawTextureOutlines(texture, x, y + offsetY);

                    if children and #children>0 then
                        for j=1, #children do
                            local childTexture = children[j].texture;
                            local childOffsetY = -children[j].offsetY;
                            self:drawTextureOutlines(childTexture, x, y + childOffsetY);
                        end
                    end
                end
            else
                if utils:isDrainPipeSprite(texture:getName()) then
                    self:drawTextureIso(texture, x, y + offsetY, 1);
                else
                    self:drawTextureIso(texture, x, y + offsetY, 0.5);
                end
            end
        end
    end

    -- Draw after textures to ensure icon is on top
    if self.container then
        if self.isGutterConnected then
            local iconW = 16;
            local iconH = 16;
            local iconX = self.x + 1;
            local iconY = self.containerBox.y + UI_BORDER_SPACING;
            -- local iconX = (self.containerBox.x - UI_BORDER_SPACING) / 2; --  - iconW
            -- local iconY = self.height - (5*UI_BORDER_SPACING) - iconH;
            self:drawTextureScaledStatic(self.gutterConnectedTexture, iconX, iconY, iconW, iconH, 1, 1, 1, 1);
        end

        -- container overlay icon
        -- local iconW = 24;
        -- local iconH = 24;
        -- local iconX = self.x + 1;
        -- local iconY = self.containerBox.y + UI_BORDER_SPACING;
        -- -- local iconX = (self.containerBox.x - UI_BORDER_SPACING - iconW) / 2;
        -- -- local iconY = self.y - (self.height - iconH) / 2;
        -- local iconTexture = self.isGutterConnected and self.gutterConnectedTexture2 or self.gutterDisconnectedTexture;
        -- self:drawTextureScaledStatic(iconTexture, iconX, iconY, iconW, iconH, 1, 1, 1, 1);
    end
end

function FG_UI_CollectorInfoPanel:renderCollectorInfo()
    local baseRainFactor = self.baseRainFactor
    if self.containerInfo.baseRainFactor.cache~=baseRainFactor then
        self.containerInfo.baseRainFactor.cache = baseRainFactor;
        self.containerInfo.baseRainFactor.value = (not baseRainFactor or baseRainFactor == 0.0) and "0.0" or tostring(round(baseRainFactor, 2));
    end

    local totalRainFactor = self.totalRainFactor;
    if self.containerInfo.totalRainFactor.cache~=totalRainFactor then
        self.containerInfo.totalRainFactor.cache = totalRainFactor;
        self.containerInfo.totalRainFactor.value = (not totalRainFactor or totalRainFactor == 0.0) and "0.0" or tostring(round(totalRainFactor, 2));
    end

    -- local tagWid = math.max(
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.baseRainFactor.tag),
    --     getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.totalRainFactor.tag)
    -- )

    local x = self.width - (3 * UI_BORDER_SPACING) - 2;
    local y = self.containerBox.y + self.containerBox.h + UI_BORDER_SPACING;
    local tagX = x
    local valX = tagX + UI_BORDER_SPACING;

    local c = self.tagColor;
    self:renderText(self.containerInfo.baseRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.containerInfo.baseRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.containerInfo.totalRainFactor.tag, tagX, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.isGutterConnected and self.goodColor or self.textColor;
    self:renderText(self.containerInfo.totalRainFactor.value, valX, y, c.r,c.g,c.b,c.a, UIFont.Small);
end

function FG_UI_CollectorInfoPanel:render()
    ISPanel.render(self);

    local c;

    if self.doTitle and self.title then
        c = self.textColor;
        self:renderText(self.title, self.width/2,UI_BORDER_SPACING+1, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextCentre);
    end

    local name = false

    local x = self.containerBox.x + UI_BORDER_SPACING+1;
    local y = self.containerBox.y + UI_BORDER_SPACING+1;

    c = self.textColor;
    local containerNameRight = x
    if self.containerName then
        self:renderText(self.containerName, x,y+3, c.r,c.g,c.b,c.a,UIFont.Small);
        containerNameRight = x + getTextManager():MeasureStringX(UIFont.Small, self.containerName)
    else
        --try to get containerName automatically.
        if self.container and self.container:getFluidContainer() then
            name = self.container:getFluidContainer():getTranslatedContainerName();
        end

        if name then
            local tx = x
            self:renderText(name, tx, y+3, c.r,c.g,c.b,c.a,UIFont.Small);
            containerNameRight = tx + getTextManager():MeasureStringX(UIFont.Small, name)
        else
            containerNameRight = x + getTextManager():MeasureStringX(UIFont.Small, "Test Name")
        end
    end

    local container = self:getContainer()
    if container then
        local capacity = container:getCapacity();
        local stored = container:getAmount();
        local free = capacity-stored;
        if self.containerInfo then
            if self.containerInfo.capacity.cache~=capacity then
                self.containerInfo.capacity.cache = capacity;
                self.containerInfo.capacity.value = FluidUtil.getAmountFormatted(capacity);
				if container:isHiddenAmount() then
					self.containerInfo.capacity.value = getText("Fluid_Unknown");
				end
            end
            if self.containerInfo.stored.cache~=stored then
                self.containerInfo.stored.cache = stored;
                self.containerInfo.stored.value = FluidUtil.getAmountFormatted(stored);
				if container:isHiddenAmount() then
					self.containerInfo.stored.value = getText("Fluid_Unknown");
				end
            end
            if self.containerInfo.free.cache~=free then
                self.containerInfo.free.cache = free;
                self.containerInfo.free.value = FluidUtil.getAmountFormatted(free);
				if container:isHiddenAmount() then
					self.containerInfo.free.value = getText("Fluid_Unknown");
				end
            end

            local tagWid = math.max(
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.capacity.tag),
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.stored.tag),
                    getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.free.tag)
            )
            local tagx = self.containerBox.x + UI_BORDER_SPACING + 1 + tagWid
            local valx = tagx + UI_BORDER_SPACING;

            y = self.containerBox.y + self.containerBox.h - FONT_HGT_SMALL - UI_BORDER_SPACING - 4;

            c = self.tagColor;
            self:renderText(self.containerInfo.free.tag, tagx,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight);
            c = self.textColor;
            self:renderText(self.containerInfo.free.value, valx,y, c.r,c.g,c.b,c.a,UIFont.Small);

            y = y - BUTTON_HGT;
            c = self.tagColor;
            self:renderText(self.containerInfo.stored.tag, tagx,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight);
            c = self.textColor;
            self:renderText(self.containerInfo.stored.value, valx,y, c.r,c.g,c.b,c.a,UIFont.Small);

            y = y - BUTTON_HGT;
            c = self.tagColor;

            self:renderText(self.containerInfo.capacity.tag, tagx,y, c.r,c.g,c.b,c.a,UIFont.Small, self.drawTextRight);
            c = self.textColor;
            self:renderText(self.containerInfo.capacity.value, valx,y, c.r,c.g,c.b,c.a,UIFont.Small);

            local valRight = valx + math.max(
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.capacity.value),
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.stored.value),
                getTextManager():MeasureStringX(UIFont.Small, self.containerInfo.free.value),
                getTextManager():MeasureStringX(UIFont.Small, "599.9 L") -- prevent panel shifting when the amount includes a decimal point
            );

            self.containerBox.w = math.max(valRight - self.containerBox.x, containerNameRight - self.containerBox.x) + UI_BORDER_SPACING + 1;
            self.fluidBar:setX(self.containerBox.x + self.containerBox.w + UI_BORDER_SPACING);
            -- self:setWidth( math.max(self.containerBox.x + self.containerBox.w, self.fluidBar:getRight()) + UI_BORDER_SPACING+1 );
        end

        self:renderCollectorInfo();
	end

    c = self.borderOuterColor;
    self:drawRectBorder(0, 0, self.width, self.height, c.a, c.r, c.g, c.b);

    c = self.borderColor;
    self:drawRectBorder(self.containerBox.x, self.containerBox.y, self.containerBox.w, self.containerBox.h, c.a, c.r, c.g, c.b);
end

function FG_UI_CollectorInfoPanel:renderText(_s, _x, _y, _r, _g, _b, _a, _font, _func)
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

function FG_UI_CollectorInfoPanel:setInvalid(_b)
    self.isInvalid = _b;
end

function FG_UI_CollectorInfoPanel:setTitle(_title)
    self.customTitle = _title;
end

function FG_UI_CollectorInfoPanel:setContainerName(_name)
    self.containerName = _name;
end

function FG_UI_CollectorInfoPanel:getContainer()
    if self.container and self.container:getFluidContainer() then
        return self.container:getFluidContainer();
    end
    return nil;
end

function FG_UI_CollectorInfoPanel:getContainerOwner()
    if self.container then
        return self.container:getOwner();
    end
    return nil;
end

function FG_UI_CollectorInfoPanel:getIsoObjectTextures()
    self.textureList = {};

    if (not self.owner) or (not instanceof(self.owner, "IsoObject")) or (not self.owner:getTextureName()) then
        return;
    end

    self.ownerTexture = getTexture( self.owner:getTextureName() );
    if not self.ownerTexture then
        return;
    end
    local square = self.gutter:getSquare();
    if not square then return end

    if square then
        if square:getFloor() and square:getFloor():getTextureName() and getTexture(square:getFloor():getTextureName()) then
            local t = { texture = getTexture(square:getFloor():getTextureName()), offsetY = 0 }
            table.insert( self.textureList, t );
        end

        for i = 1, square:getObjects():size()-1 do
            local obj = square:getObjects():get(i);
            if obj and obj:getTextureName() and getTexture(obj:getTextureName()) then
                local t = { texture = getTexture(obj:getTextureName()), offsetY = obj:getRenderYOffset() * Core.getTileScale() }
                table.insert(self.textureList, t);

                local sprList = obj:getChildSprites();
                if sprList and (not instanceof(obj,"IsoBarbecue")) then
                    local list_size 	= sprList:size();
                    if list_size > 0 then
                        t.children = {};
                        for l=list_size-1, 0, -1 do
                            local sprite = sprList:get(l):getParentSprite();
                            if sprite:getName() and getTexture(sprite:getName()) then
                                local child = { texture = getTexture(sprite:getName()), offsetY = obj:getRenderYOffset() * Core.getTileScale() }
                                table.insert(t.children, child);
                            end
                        end
                    end
                end
            end
        end
    end

    return self.textureList;
end

function FG_UI_CollectorInfoPanel:hasValidContainer()
    if self.container then
        --check if iso still has square
        return ISFluidUtil.validateContainer(self.container);
    end
end

function FG_UI_CollectorInfoPanel:onClose()
    if self.containerCopy then
        FluidContainer.DisposeContainer(self.containerCopy);
        self.containerCopy = nil;
    end
end

function FG_UI_CollectorInfoPanel:reloadInfo(full)
    if self.collector then
        self.baseRainFactor = utils:getModDataBaseRainFactor(self.collector);

        local fluidContainer = self.collector:getFluidContainer();
        if fluidContainer then
            self.totalRainFactor = fluidContainer:getRainCatcher();
        else
            self.totalRainFactor = 0.0;
        end
        self.isGutterConnected = utils:getModDataIsGutterConnected(self.collector, nil);

        if self.isInvalid then
            self:setInvalid(false);
        end
    else
        self.baseRainFactor = 0.0;
        self.totalRainFactor = 0.0;
        self.isGutterConnected = false;
        self:setInvalid(true);
    end

    if full then
        self.container = self.collector and ISFluidContainer:new(self.collector:getFluidContainer()) or nil;
        if self.container then
            self.owner = self.container:getOwner();
            self.containerCopy = self.container:getFluidContainer():copy();
        else
            self.owner = self.gutter;
            self.containerCopy = nil;
        end
        self:clearChildren();
        self:createChildren();
    end
end

function FG_UI_CollectorInfoPanel:new(x, y, _player, _gutter, _collector)
    local width = 300;
    local height = BUTTON_HGT*5+UI_BORDER_SPACING*5+FONT_HGT_SMALL;
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = false;
    o.backgroundColor = {r=0, g=0, b=0, a=0.0};
    o.borderColor = {r=0.6, g=0.6, b=0.6, a=1};
    o.borderOuterColor = {r=0.6, g=0.6, b=0.6, a=1};
    o.detailInnerColor = {r=0,g=0,b=0,a=1};
    o.textColor = {r=1,g=1,b=1,a=1}
    o.tagColor = {r=0.8,g=0.8,b=0.8,a=1}
    o.invalidColor = {r=0.6,g=0.2,b=0.2,a=1}
    o.goodColor = {r=GOOD_COLOR:getR(), g=GOOD_COLOR:getG(), b=GOOD_COLOR:getB(), a=1}
    o.width = width;
    o.height = height;
    o.anchorLeft = false;
    o.anchorRight = false;
    o.anchorTop = false;
    o.anchorBottom = false;
    o.missingCollectorTexture = getTexture("carpentry_02_124");
    o.missingIconTexture = getTexture("media/ui/Entity/BTN_Missing_Icon_48x48.png");
    o.gutterConnectedTexture = getTexture("media/ui/craftingMenus/BuildProperty_Drain.png")
    -- o.gutterConnectedTexture2 = getTexture("media/ui/Entity/icon_transfer_fluids.png")
    -- o.gutterDisconnectedTexture = getTexture("media/ui/Entity/icon_clear_fluids.png")
    -- media/ui/Entity/fluid_drop_icon.png

    o.player = _player;
    o.gutter = _gutter;
    o.collector = _collector;

    -- Generate ISFluidContainer from the collector iso object
    o.container = o.collector and ISFluidContainer:new(o.collector:getFluidContainer()) or nil;
    if o.container then
        o.owner = o.container:getOwner();
        o.containerCopy = o.container:getFluidContainer():copy(); -- TODO remove container copy
    else
        o.owner = o.gutter;
        o.containerCopy = nil;
    end

    -- if true add a title.
    o.doTitle = false; -- TODO 
    o.title = ""; -- TODO
    o.customTitle = false;

    o.funcTarget = false;
    o.onContainerAdd = false;
    o.overrideAddFull = false;
    o.onContainerRemove = false;
    o.overrideRemoveFull = false;
    o.onContainerVerify = false;

    o.doOwnerOutlines = false;
    o.outlineColor = {r=0.85,g=0.82,b=0.78,a=1};
    o.containerName = false;

    --if set invalid draws invalid background color
    o.isInvalid = false;

    o.containerInfo = {
        capacity = { tag = getText("Fluid_Capacity")..": ", value = "0", cache = 0 },
        stored = { tag = getText("Fluid_Stored")..": ", value = "0", cache = 0 },
        free = { tag = getText("Fluid_Free")..": ", value = "0", cache = 0 },
        baseRainFactor = { tag = "Base Rain Factor"..": ", value = "0.0", cache = 0.0 }, -- TODO translate
        totalRainFactor = { tag = "Total Rain Factor"..": ", value = "0.0", cache = 0.0 }, -- TODO translate
    }

    return o
end