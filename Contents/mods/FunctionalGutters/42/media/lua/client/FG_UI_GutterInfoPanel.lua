require "ISUI/ISPanel"

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local serviceUtils = require("FG_Utils_Service")

FG_UI_GutterInfoPanel = ISPanel:derive("FG_UI_GutterInfoPanel");

-- local eyeOn = getTexture("media/ui/foraging/eyeconOn.png")
-- local eyeOff = getTexture("media/ui/foraging/eyeconOff.png")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local OBJECT_HIGHLIGHT_COLOR = ColorInfo.new(getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB(),1);

function FG_UI_GutterInfoPanel:initialise()
    ISPanel.initialise(self);
    -- self:create();
    -- self:setVisible(true);
    -- self:addToUIManager();
end

function FG_UI_GutterInfoPanel:prerender() -- Call before render, it's for harder stuff that need init, ect
    ISPanel.prerender(self);
end

function FG_UI_GutterInfoPanel:renderPipeInfo()
    local x = UI_BORDER_SPACING + 1;
    local y = UI_BORDER_SPACING + 1;

    local c = self.textColor;
    self:renderText("Pipes", x, y, c.r, c.g, c.b, c.a, UIFont.Small);

    local drainCount = #self.gutterMap[enums.pipeType.drain]
    if self.pipeInfo.drain.cache~=drainCount then
        self.pipeInfo.drain.cache = drainCount;
        self.pipeInfo.drain.value = tostring(drainCount);
    end

    local verticalCount = #self.gutterMap[enums.pipeType.vertical]
    if self.pipeInfo.vertical.cache~=verticalCount then
        self.pipeInfo.vertical.cache = verticalCount;
        self.pipeInfo.vertical.value = tostring(verticalCount);
    end

    local gutterCount = #self.gutterMap[enums.pipeType.gutter]
    if self.pipeInfo.gutter.cache~=gutterCount then
        self.pipeInfo.gutter.cache = gutterCount;
        self.pipeInfo.gutter.value = tostring(gutterCount);
    end

    local pipeContainerW = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
    local tagWid = math.max(
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.drain.tag),
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.vertical.tag),
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.gutter.tag)
    )
    local tagx = UI_BORDER_SPACING + 1 + tagWid
    local valx = tagx + UI_BORDER_SPACING;

    -- y = FONT_HGT_SMALL - UI_BORDER_SPACING - 4;

    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING + 1
    c = self.tagColor;
    self:renderText(self.pipeInfo.drain.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.pipeInfo.drain.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.pipeInfo.vertical.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.pipeInfo.vertical.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.pipeInfo.gutter.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.pipeInfo.gutter.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);
end

function FG_UI_GutterInfoPanel:renderRoofInfo()
    local roofContainerW = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
    local x = UI_BORDER_SPACING + 1 + roofContainerW + UI_BORDER_SPACING + 1;
    local y = UI_BORDER_SPACING + 1;

    local c = self.textColor;
    self:renderText("Roof", x, y, c.r, c.g, c.b, c.a, UIFont.Small);

    local roofArea = self.roofArea
    if self.roofInfo.area.cache~=roofArea then
        self.roofInfo.area.cache = roofArea;
        self.roofInfo.area.value = tostring(roofArea);
    end

    local maxGutterCapacity = self.maxGutterTileCount;
    if self.roofInfo.maxGutterTileCount.cache~=maxGutterCapacity then
        self.roofInfo.maxGutterTileCount.cache = maxGutterCapacity;
        self.roofInfo.maxGutterTileCount.value = tostring(maxGutterCapacity);
    end

    local estimatedGutterCount = self.estimatedDrainCount;
    if self.roofInfo.estimatedDrainCount.cache~=estimatedGutterCount then
        self.roofInfo.estimatedDrainCount.cache = estimatedGutterCount;
        self.roofInfo.estimatedDrainCount.value = tostring(estimatedGutterCount);
    end

    local gutterTileCount = self.gutterTileCount;
    if self.roofInfo.gutterTileCount.cache~=gutterTileCount then
        self.roofInfo.gutterTileCount.cache = gutterTileCount;
        self.roofInfo.gutterTileCount.value = tostring(gutterTileCount);
    end

    local tagWid = math.max(
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.area.tag),
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.maxGutterTileCount.tag),
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.estimatedDrainCount.tag),
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.gutterTileCount.tag)
    )
    local tagx = x + tagWid
    local valx = tagx + UI_BORDER_SPACING;

    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING + 1
    c = self.tagColor;
    self:renderText(self.roofInfo.area.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.roofInfo.area.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    -- y = y + BUTTON_HGT;
    -- c = self.tagColor;
    -- self:renderText(self.roofInfo.maxGutterTileCount.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    -- c = self.textColor;
    -- self:renderText(self.roofInfo.maxGutterTileCount.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.roofInfo.estimatedDrainCount.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.roofInfo.estimatedDrainCount.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.roofInfo.gutterTileCount.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.roofInfo.gutterTileCount.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);
end

function FG_UI_GutterInfoPanel:render() -- Use to render text and other
    self:renderPipeInfo()
    self:renderRoofInfo()
end

function FG_UI_GutterInfoPanel:onPipes()
    local highlight = not self.gutterHighlight
    self:highlightGutterObjects(highlight)
    if highlight then
        self.btnPipes:enableAcceptColor()   
    else
        local bgC = self.btnDefault.backgroundColor
        local bgCMO = self.btnDefault.backgroundColorMouseOver
        local bC = self.btnDefault.borderColor
        self.btnPipes:setBackgroundRGBA(bgC.r, bgC.g, bgC.b, bgC.a)
        self.btnPipes:setBackgroundColorMouseOverRGBA(bgCMO.r, bgCMO.g, bgCMO.b, bgCMO.a)
        self.btnPipes:setBorderRGBA(bC.r, bC.g, bC.b, bC.a)
    end

    -- self.btnPipes:setImage(highlight and eyeOn or eyeOff)
end

function FG_UI_GutterInfoPanel:onRoof()
    local highlight = not self.roofAreaHighlight
    self:highlightRoofArea(highlight)

    if highlight then
        self.btnRoof:enableAcceptColor()
    else
        local bgC = self.btnDefault.backgroundColor
        local bgCMO = self.btnDefault.backgroundColorMouseOver
        local bC = self.btnDefault.borderColor
        self.btnRoof:setBackgroundRGBA(bgC.r, bgC.g, bgC.b, bgC.a)
        self.btnRoof:setBackgroundColorMouseOverRGBA(bgCMO.r, bgCMO.g, bgCMO.b, bgCMO.a)
        self.btnRoof:setBorderRGBA(bC.r, bC.g, bC.b, bC.a)
    end

    -- self.btnRoof:setImage(highlight and eyeOn or eyeOff)
end


function FG_UI_GutterInfoPanel:createChildren() -- Use to make the elements
    local btnW = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
    local btnX = UI_BORDER_SPACING + 1
    local btnY = self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT
    local btnPipesText = "View Pipes";  -- TODO translate
    self.btnPipes = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, btnPipesText, self, self.onPipes);
    self.btnPipes.internal = "PIPES";
    -- self.btnPipes:setImage(self.gutterHighlight and eyeOn or eyeOff)
    self.btnPipes:initialise();
    self.btnPipes:instantiate();
    self:addChild(self.btnPipes);
    utils:modPrint("button pipes: "..tostring(self.btnPipes))

    local roofBtnText = "View Roof"; -- TODO translate
    btnX = btnX + btnW + UI_BORDER_SPACING + 1
    self.btnRoof = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, roofBtnText, self, self.onRoof);
    self.btnRoof.internal = "ROOF";
    -- self.btnRoof:setImage(self.roofAreaHighlight and eyeOn or eyeOff)
    self.btnRoof:initialise();
    self.btnRoof:instantiate();
    self:addChild(self.btnRoof);
end

function FG_UI_GutterInfoPanel:update()
    local w = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
    self.btnPipes:setWidth(w);
    self.btnRoof:setWidth(w);
end

function FG_UI_GutterInfoPanel:highlightGutterObject(square, highlight)
    if not square then return end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if utils:isAnyPipe(object) then
            object:setHighlighted(highlight, false);
            if highlight then
                object:setHighlightColor(OBJECT_HIGHLIGHT_COLOR);
                object:setBlink(true);
            end
            self.gutterHighlight = highlight;
        end
    end
end

function FG_UI_GutterInfoPanel:highlightCoveredFloor(square, highlight)
    if not square then return end

    local floor = square:getFloor()
    if floor then
        floor:setHighlighted(highlight, false);
        if highlight then
            floor:setHighlightColor(OBJECT_HIGHLIGHT_COLOR);
            floor:setBlink(true);
        end
        self.roofAreaHighlight = highlight;
    end
end


function FG_UI_GutterInfoPanel:highlightGutterObjects(highlight)
    for _, gutterMapValue in pairs(self.gutterMap) do
        for _, square in ipairs(gutterMapValue) do
            self:highlightGutterObject(square, highlight)
        end
    end
end

function FG_UI_GutterInfoPanel:highlightRoofArea(highlight)
    for _, square in pairs(self.coveredFloors) do
        self:highlightCoveredFloor(square, highlight)
    end
end

function FG_UI_GutterInfoPanel:close()
    -- Cleanup any active highlights
    if self.gutterHighlight then
        self:highlightGutterObjects(false)
    end

    if self.roofAreaHighlight then
        self:highlightRoofArea(false)
    end

    self:setVisible(false);
    self:removeFromUIManager();
end

function FG_UI_GutterInfoPanel:renderText(_s, _x, _y, _r, _g, _b, _a, _font, _func)
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

function FG_UI_GutterInfoPanel:reloadInfo()
    self.square = self.gutter:getSquare()
    self.gutterMap = isoUtils:crawlGutterSystem(self.square)
    self.coveredFloors = isoUtils:getGutterCoveredFloors(self.gutterMap)
    self.roofArea = utils:getModDataRoofArea(self.square)
    self.maxGutterTileCount = serviceUtils:getAverageGutterCapacity()
    self.estimatedDrainCount, self.gutterTileCount = serviceUtils:getEstimatedGutterDrainCount(self.roofArea, self.maxGutterTileCount)
end

function FG_UI_GutterInfoPanel:new(x, y, width, height, gutterDrain)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.backgroundColor = {r=0, g=0, b=0, a=0.9};
    o.btnDefault = {
        borderColor = {r=0.7, g=0.7, b=0.7, a=1};
	    backgroundColor = {r=0, g=0, b=0, a=1.0};
	    backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0};
    }
    o.textColor = {r=1,g=1,b=1,a=1}
    o.tagColor = {r=0.8,g=0.8,b=0.8,a=1}
    o.invalidColor = {r=0.6,g=0.2,b=0.2,a=1}

    o.gutter = gutterDrain;

    o.gutterHighlight = false;
    o.roofAreaHighlight = false;
    o.btnPipes = nil;
    o.btnRoof = nil;
    o.disableBtnPipes = false;
    o.disableBtnRoof = false;

    o.reloadInfo(o);
    o.pipeInfo = {
        [enums.pipeType.drain] = { tag = "Drain"..": ", value = "0", cache = 0 },
        [enums.pipeType.vertical] = { tag = "Vertical"..": ", value = "0", cache = 0 },
        [enums.pipeType.gutter] = { tag = "Gutter"..": ", value = "0", cache = 0 },
    }
    o.roofInfo = {
        area = { tag = "Total Area"..": ", value = "0", cache = 0 },
        estimatedDrainCount = { tag = "Drain Sections"..": ", value = "0", cache = 0 },
        maxGutterTileCount = { tag = "Max Area"..": ", value = "0", cache = 0 },
        gutterTileCount = { tag = "Drain Area"..": ", value = "0", cache = 0 },
    }

    return o;
end