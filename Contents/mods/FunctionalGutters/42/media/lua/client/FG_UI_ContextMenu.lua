local utils = require("FG_Utils")

require "FG_TA_OpenGutterPanel"

local function DoOpenGutterPanel(playerObject, drainObject)
    if luautils.walkAdj(playerObject, drainObject:getSquare(), false) then
        ISTimedActionQueue.add(FG_TA_OpenGutterPanel:new(playerObject, drainObject, FG_UI_GutterPanel, nil))
    end
end

local function AddGutterSystemPanelOption(player, context, drainObject)
    local playerObject = getSpecificPlayer(player)
    context:addOption(getText("UI_context_menu_FunctionalGutters_GutterSubMenu"), playerObject, DoOpenGutterPanel, drainObject)
end

local function AddGutterSystemContext(player, context, worldobjects, test)
    for i=1, #worldobjects do
        local worldObject = worldobjects[i]
        if worldObject then
            if utils:isDrainPipe(worldObject) then
                AddGutterSystemPanelOption(player, context, worldObject)
                break
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(AddGutterSystemContext)