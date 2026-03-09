local enums = require("FG_Enums")
local utils = require("FG_Utils")

require "FG_TA_OpenGutterPanel"

local function DoOpenGutterPanel(playerObject, drainObject)
    if luautils.walkAdj(playerObject, drainObject:getSquare(), false) then
        ISTimedActionQueue.add(FG_TA_OpenGutterPanel:new(playerObject, drainObject, FG_UI_GutterPanel, nil))
    end
end

local function AddGutterSystemPanelOption(player, context, drainObject)
    local playerObject = getSpecificPlayer(player)
    local option = context:addOption(getText("ContextMenu_FunctionalGutters_GutterSubMenu"), playerObject,
        DoOpenGutterPanel, drainObject)
    option.iconTexture = getTexture("media/ui/FG_Plumb_Icon.png")
end

local function AddGutterSystemContext(player, context, worldObjects, test)
    if not worldObjects or #worldObjects == 0 then
        return
    end

    -- Not all objects are provided to worldObjects
    -- Instead, we get the square for the first object and iterate over all objects on that square
    local firstObject = worldObjects[1]
    local square = firstObject:getSquare()
    if not utils:isDrainPipeSquare(square) then
        return
    end

    local _, drainPipe, _, _ = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.drain)
    if drainPipe then
        AddGutterSystemPanelOption(player, context, drainPipe)
    end
end

Events.OnFillWorldObjectContextMenu.Add(AddGutterSystemContext)
