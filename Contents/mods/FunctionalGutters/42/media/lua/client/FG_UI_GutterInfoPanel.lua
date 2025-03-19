require "ISUI/ISPanel"

local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")

FG_UI_GutterInfoPanel = ISPanel:derive("FG_UI_GutterInfoPanel");

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


    -- self:drawText("Hello world",0,0,1,1,1,1, UIFont.Small); -- You can put it in render() too

    -- local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING + 1;

    -- self:drawText("Gutter System", x, y, 1, 1, 1, 1, UIFont.Medium);

    -- y = y + BUTTON_HGT * 2;
    -- self:drawText("Drain Pipes = "..tostring(#self.gutterMap.drain), x, y, 1, 1, 1, 1, UIFont.Small);

    -- y = y + BUTTON_HGT;
    -- self:drawText("Vertical Pipes = "..tostring(#self.gutterMap.vertical), x, y, 1, 1, 1, 1, UIFont.Small);

    -- y = y + BUTTON_HGT;
    -- self:drawText("Gutter Pipes = "..tostring(#self.gutterMap.gutter), x, y, 1, 1, 1, 1, UIFont.Small);

    -- y = y + BUTTON_HGT;
    -- self:drawText("Roof Area = "..tostring(self.roofArea), x, y, 1, 1, 1, 1, UIFont.Small);
end

function FG_UI_GutterInfoPanel:render() -- Use to render text and other
    local x, y = UI_BORDER_SPACING+1, UI_BORDER_SPACING + 1;

    self:drawText("Gutter System", x, y, 1, 1, 1, 1, UIFont.Medium);

    y = y + BUTTON_HGT * 2;
    self:drawText("Drain Pipes = "..tostring(#self.gutterMap.drain), x, y, 1, 1, 1, 1, UIFont.Small);

    y = y + BUTTON_HGT;
    self:drawText("Vertical Pipes = "..tostring(#self.gutterMap.vertical), x, y, 1, 1, 1, 1, UIFont.Small);

    y = y + BUTTON_HGT;
    self:drawText("Gutter Pipes = "..tostring(#self.gutterMap.gutter), x, y, 1, 1, 1, 1, UIFont.Small);

    y = y + BUTTON_HGT;
    self:drawText("Roof Area = "..tostring(self.roofArea), x, y, 1, 1, 1, 1, UIFont.Small);

    -- TODO recalculate button

    -- TODO highlight gutter system button

    -- TODO highlight roof area button
end

function FG_UI_GutterInfoPanel:onButton(_btn)
    if _btn.internal=="PIPES" then
        local highlight = not self.gutterHighlight
        self:highlightGutterObjects(highlight)
        if highlight then
            self.btnPipes:enableCancelColor()
        else
            self.btnPipes:enableAcceptColor()
        end
    elseif _btn.internal=="ROOF" then
        local highlight = not self.roofAreaHighlight
        self:highlightRoofArea(highlight)

        if highlight then
            self.btnRoof:enableCancelColor()
        else
            self.btnRoof:enableAcceptColor()
        end
    end
end

function FG_UI_GutterInfoPanel:onPipes()
    local highlight = not self.gutterHighlight
    self:highlightGutterObjects(highlight)
    if highlight then
        self.btnPipes:enableCancelColor()
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
        self.btnRoof:enableCancelColor()
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
    local btnY = self:getBottom() - (2 * UI_BORDER_SPACING) - BUTTON_HGT

    local btnPipesText = "Pipes";  -- TODO translate
    self.btnPipes = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, btnPipesText, self, self.onPipes);
    self.btnPipes.internal = "PIPES";
    self.btnPipes:initialise();
    self.btnPipes:instantiate();
    self:addChild(self.btnPipes);
    utils:modPrint("button pipes: "..tostring(self.btnPipes))

    local roofBtnText = "Roof"; -- TODO translate
    btnX = btnX + btnW + UI_BORDER_SPACING
    self.btnRoof = ISButton:new(btnX, btnY, btnW, BUTTON_HGT, roofBtnText, self, self.onRoof);
    self.btnRoof.internal = "ROOF";
    self.btnRoof:initialise();
    self.btnRoof:instantiate();
    self:addChild(self.btnRoof);

    -- self:setHeight(self.btnPipes:getBottom() + UI_BORDER_SPACING+1);
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

function FG_UI_GutterInfoPanel:new(x, y, width, height, gutterDrain)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = {r=0, g=0, b=0, a=0.9};

    -- o.isInvalid = false;
    o.btnDefault = {
        borderColor = {r=0.7, g=0.7, b=0.7, a=1};
	    backgroundColor = {r=0, g=0, b=0, a=1.0};
	    backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0};
    }

    o.gutter = gutterDrain;
    o.square = o.gutter:getSquare()
    o.gutterMap = isoUtils:crawlGutterSystem(o.square)
    o.coveredFloors = isoUtils:getGutterCoveredFloors(o.gutterMap)
    o.roofArea = utils:getModDataRoofArea(o.square)
    o.gutterHighlight = false;
    o.roofAreaHighlight = false;
    o.btnPipes = nil;
    o.btnRoof = nil;
    -- TODO 
    -- o.info = {
    --     capacity = { tag = getText("Fluid_Capacity")..": ", value = "0", cache = 0 },
    --     stored = { tag = getText("Fluid_Stored")..": ", value = "0", cache = 0 },
    --     free = { tag = getText("Fluid_Free")..": ", value = "0", cache = 0 },
    -- }

    return o;
end