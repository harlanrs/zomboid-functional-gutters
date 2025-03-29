require "ISUI/ISPanel"

local enums = require("FG_Enums")
local utils = require("FG_Utils")

FG_UI_GutterInfoPanel = ISPanel:derive("FG_UI_GutterInfoPanel");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local OBJECT_HIGHLIGHT_COLOR = ColorInfo.new(getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB(),1);

function FG_UI_GutterInfoPanel:initialise()
    ISPanel.initialise(self);

    self:reloadInfo()
end

function FG_UI_GutterInfoPanel:prerender() -- Call before render, it's for harder stuff that need init, ect
    ISPanel.prerender(self);
end

function FG_UI_GutterInfoPanel:renderPipeInfo()
    local x = UI_BORDER_SPACING + 1;
    local y = UI_BORDER_SPACING + 1;

    local c = self.textColor;
    self:renderText(getText("UI_panel_FunctionalGutters_section_Pipes_title"), x, y, c.r, c.g, c.b, c.a, UIFont.Small);

    if not self.gutterSegment or not self.gutterSegment.pipeMap == nil then
        return
    end
    local pipeMap = self.gutterSegment.pipeMap
    local drainCount = #pipeMap[enums.pipeType.drain]
    if self.pipeInfo.drain.cache~=drainCount then
        self.pipeInfo.drain.cache = drainCount;
        self.pipeInfo.drain.value = tostring(drainCount);
    end

    local verticalCount = #pipeMap[enums.pipeType.vertical]
    if self.pipeInfo.vertical.cache~=verticalCount then
        self.pipeInfo.vertical.cache = verticalCount;
        self.pipeInfo.vertical.value = tostring(verticalCount);
    end

    local gutterCount = #pipeMap[enums.pipeType.gutter]
    if self.pipeInfo.gutter.cache~=gutterCount then
        self.pipeInfo.gutter.cache = gutterCount;
        self.pipeInfo.gutter.value = tostring(gutterCount);
    end

    local tagWid = math.max(
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.drain.tag),
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.vertical.tag),
            getTextManager():MeasureStringX(UIFont.Small, self.pipeInfo.gutter.tag)
    )
    local tagx = UI_BORDER_SPACING + 1 + tagWid
    local valx = tagx + UI_BORDER_SPACING;

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
    self:renderText(getText("UI_panel_FunctionalGutters_section_Roof_title"), x, y, c.r, c.g, c.b, c.a, UIFont.Small);

    local roofArea = self.gutterSegment.roofArea
    if self.roofInfo.area.cache~=roofArea then
        self.roofInfo.area.cache = roofArea;
        self.roofInfo.area.value = tostring(roofArea);
    end

    local systemDrainCount = self.gutterSegment.drainCount;
    if self.roofInfo.drainCount.cache~=systemDrainCount then
        self.roofInfo.drainCount.cache = systemDrainCount;
        self.roofInfo.drainCount.value = tostring(systemDrainCount);
    end

    local optimalDrainCount = self.gutterSegment.optimalDrainCount;
    if self.roofInfo.optimalDrainCount.cache~=optimalDrainCount then
        self.roofInfo.optimalDrainCount.cache = optimalDrainCount;
        self.roofInfo.optimalDrainCount.value = tostring(optimalDrainCount);
    end

    local gutterTileCount = self.gutterSegment.tileCount;
    if self.roofInfo.gutterTileCount.cache~=gutterTileCount then
        self.roofInfo.gutterTileCount.cache = gutterTileCount;
        self.roofInfo.gutterTileCount.value = (not gutterTileCount or gutterTileCount == 0) and "0" or tostring(round(gutterTileCount, 2));
    end

    local tagWid = math.max(
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.area.tag),
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.gutterTileCount.tag),
        getTextManager():MeasureStringX(UIFont.Small, self.roofInfo.drainCount.tag)
    )
    local tagx = x + tagWid
    local valx = tagx + UI_BORDER_SPACING;

    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING + 1
    c = self.tagColor;
    self:renderText(self.roofInfo.area.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = self.textColor;
    self:renderText(self.roofInfo.area.value, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

    y = y + BUTTON_HGT;
    c = self.tagColor;
    self:renderText(self.roofInfo.drainCount.tag, tagx, y, c.r,c.g,c.b,c.a, UIFont.Small, self.drawTextRight);
    c = systemDrainCount > optimalDrainCount and self.invalidColor or self.textColor;
    local drainCountText = self.roofInfo.drainCount.value.."/"..self.roofInfo.optimalDrainCount.value
    self:renderText(drainCountText, valx, y, c.r,c.g,c.b,c.a, UIFont.Small);

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
end


function FG_UI_GutterInfoPanel:createChildren() -- Use to make the elements
    local btnW = (self:getWidth() - (3 * UI_BORDER_SPACING)) / 2;
    local btnX = UI_BORDER_SPACING + 1
    local btnY = self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT
    local btnPipesText = getText("UI_panel_FunctionalGutters_section_Pipes_btn");
    self.btnPipes = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, btnPipesText, self, self.onPipes);
    self.btnPipes.internal = "PIPES";
    self.btnPipes:initialise();
    self:addChild(self.btnPipes);

    local roofBtnText = getText("UI_panel_FunctionalGutters_section_Roof_btn");
    btnX = btnX + btnW + UI_BORDER_SPACING + 1
    self.btnRoof = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, roofBtnText, self, self.onRoof);
    self.btnRoof.internal = "ROOF";
    self.btnRoof:initialise();
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
        end
    end
end

function FG_UI_GutterInfoPanel:highlightCoveredRoof(square, highlight)
    if not square then return end
    local highlightObject
    if self.gutterSegment.buildingType == enums.buildingType.vanilla then
        -- If vanilla building, try to find the square's roof object
        if utils:hasRoofProp(square) then
            local squareObjects = square:getObjects()
            for i = 0, squareObjects:size() - 1 do
                local object = squareObjects:get(i)
                if utils:isRoofObject(object) then
                    highlightObject = object
                    break
                end
            end
        end
    end

    if not highlightObject then
        -- Use the square's floor as the roof object
        local floor = square:getFloor()
        if floor then
            highlightObject = floor
        end
    end

    if not highlightObject then
        -- Might still be a 'valid roof' but nothing to highlight (ex: multi-level roof) but also could indicate over counting of roof area
        utils:modPrint("No roof object found for square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return
    end

    highlightObject:setHighlighted(highlight, false);
    if highlight then
        highlightObject:setHighlightColor(OBJECT_HIGHLIGHT_COLOR);
        highlightObject:setBlink(true);
    end
end

function FG_UI_GutterInfoPanel:highlightGutterObjects(highlight)
    if not self.gutterSegment.pipeMap then return end

    for _, gutterPipeType in pairs(self.gutterSegment.pipeMap) do
        for _, pipeSquare in ipairs(gutterPipeType) do
            self:highlightGutterObject(pipeSquare, highlight)
        end
    end
    self.gutterHighlight = highlight;
end

function FG_UI_GutterInfoPanel:highlightRoofArea(highlight)
    if not self.gutterSegment.roofMap then return end

    for _, roofSquare in pairs(self.gutterSegment.roofMap) do
        self:highlightCoveredRoof(roofSquare, highlight)
    end
    self.roofAreaHighlight = highlight;
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
end

function FG_UI_GutterInfoPanel:new(x, y, width, height, gutter, gutterSegment)
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

    o.gutter = gutter;
    o.gutterSegment = gutterSegment;

    o.gutterHighlight = false;
    o.roofAreaHighlight = false;
    o.btnPipes = nil;
    o.btnRoof = nil;
    o.disableBtnPipes = false;
    o.disableBtnRoof = false;

    o.pipeInfo = {
        [enums.pipeType.drain] = { tag = getText("UI_panel_FunctionalGutters_section_Pipes_item_Drain")..": ", value = "0", cache = 0 },
        [enums.pipeType.vertical] = { tag = getText("UI_panel_FunctionalGutters_section_Pipes_item_Vertical")..": ", value = "0", cache = 0 },
        [enums.pipeType.gutter] = { tag = getText("UI_panel_FunctionalGutters_section_Pipes_item_Gutter")..": ", value = "0", cache = 0 },
    }
    o.roofInfo = {
        area = { tag = getText("UI_panel_FunctionalGutters_section_Roof_item_TotalArea")..": ", value = "0", cache = 0 },
        drainCount = { tag = getText("UI_panel_FunctionalGutters_section_Roof_item_DrainSections")..": ", value = "0", cache = 0 },
        optimalDrainCount = { tag = "Optimal Drain Sections"..": ", value = "0", cache = 0 },
        gutterTileCount = { tag = getText("UI_panel_FunctionalGutters_section_Roof_item_DrainArea")..": ", value = "0", cache = 0 },
    }

    return o;
end