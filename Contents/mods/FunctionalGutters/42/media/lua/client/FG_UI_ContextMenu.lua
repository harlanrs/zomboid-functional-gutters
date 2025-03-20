local enums = require("FG_Enums")
local utils = require("FG_Utils")
local options = require("FG_Options")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")
local serviceUtils = require("FG_Utils_Service")

require "FG_TA_ConnectContainer"
require "FG_TA_DisconnectContainer"
require "FG_TA_OpenGutterPanel"

local debugMode = false

local function DoConnectContainer(playerObject, collectorObject)
    if luautils.walkAdj(playerObject, collectorObject:getSquare(), true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(playerObject:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(playerObject, playerObject:getPrimaryHandItem(), wrench, true)
                ISTimedActionQueue.add(FG_TA_ConnectContainer:new(playerObject, collectorObject, wrench))
            end
        else
            ISTimedActionQueue.add(FG_TA_ConnectContainer:new(playerObject, collectorObject, nil))
        end
    end
end

local function DoDisconnectContainer(playerObject, collectorObject)
    if luautils.walkAdj(playerObject, collectorObject:getSquare(), true) then
        if options:getRequireWrench() then
            local wrench = utils:playerGetItem(playerObject:getInventory(), "PipeWrench")
            if wrench then
                ISWorldObjectContextMenu.equip(playerObject, playerObject:getPrimaryHandItem(), wrench, true)
                ISTimedActionQueue.add(FG_TA_DisconnectContainer:new(playerObject, collectorObject, wrench))
            end
        else
            ISTimedActionQueue.add(FG_TA_DisconnectContainer:new(playerObject, collectorObject, nil))
        end
    end
end

local function DoOpenGutterPanel(playerObject, drainObject, connectedContainer, linkedSquare)
    if luautils.walkAdj(playerObject, drainObject:getSquare(), true) then
        ISTimedActionQueue.add(FG_TA_OpenGutterPanel:new(playerObject, drainObject, connectedContainer, FG_UI_GutterPanel, nil))
    end
end

local function AddGutterSystemContext(player, context, square, drainObject)
    -- Check square for valid container
    local squareObjects = square:getObjects()
    local squareCollector = nil
    for i = 0, squareObjects:size() - 1 do
        local object = squareObjects:get(i)
        if serviceUtils:isValidContainerObject(object) then
            squareCollector = object
            break
        end
    end

    -- Conditionally build primary gutter context menu
    local primaryContainer = squareCollector
    local linkedSquare
    if primaryContainer and troughUtils:isTrough(primaryContainer) then
        -- Check the 2nd tile if multi-tile trough
        local primaryTrough = troughUtils:getPrimaryTroughFromDef(squareCollector)
        utils:modPrint("Primary trough object: "..tostring(primaryTrough))
        if not primaryTrough then
            return
        end

        local primaryTroughSprite = primaryTrough:getSprite()
        local troughSpriteGrid = primaryTroughSprite:getSpriteGrid()
        if troughSpriteGrid and (troughSpriteGrid:getWidth() > 0 or troughSpriteGrid:getHeight() > 0) then
            local secondaryTrough = troughUtils:getSecondaryTroughFromDef(primaryTrough)
            utils:modPrint("Secondary trough object: "..tostring(secondaryTrough))
            if secondaryTrough then
                linkedSquare = secondaryTrough:getSquare()
            end
        end

        -- Ensure the primary trough object is used for context menu interacts
        primaryContainer = primaryTrough
    end

    -- Build context menu
    local playerObject = getSpecificPlayer(player)
    local gutterSubMenu = context:getNew(context)
    local gutterSubMenuOption = context:addOption(getText("UI_context_menu_FunctionalGutters_GutterSubMenu"), playerObject, nil);
    context:addSubMenu(gutterSubMenuOption, gutterSubMenu)

    local notAvailable = false
    local requireWrench = options:getRequireWrench()
    if requireWrench then
        local wrench = utils:playerGetItem(playerObject:getInventory(), "PipeWrench")
        if not wrench then
            notAvailable = true
        end
    end

    -- Quick connect/disconnect option for primary container
    if primaryContainer then
        local containerName = utils:getObjectDisplayName(primaryContainer)
        local isGutterConnected = utils:getModDataIsGutterConnected(primaryContainer, nil)
        if isGutterConnected then
            local disconnectGutterOption = gutterSubMenu:addOption(getText("UI_context_menu_FunctionalGutters_DisconnectContainer").." "..containerName, playerObject, DoDisconnectContainer, primaryContainer);
            disconnectGutterOption.notAvailable = notAvailable
            if notAvailable then
                disconnectGutterOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                disconnectGutterOption.toolTip.description = getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench"))
            end
        else
            local connectGutterOption = gutterSubMenu:addOption(getText("UI_context_menu_FunctionalGutters_ConnectContainer").." "..containerName, playerObject, DoConnectContainer, primaryContainer);
            connectGutterOption.notAvailable = notAvailable
            if notAvailable then
                connectGutterOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                connectGutterOption.toolTip.description = getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench"))
            end
        end
    end

    -- Gutter System Panel
    local openGutterPanelOption = gutterSubMenu:addOption("Show Info", playerObject, DoOpenGutterPanel, drainObject, primaryContainer, linkedSquare);
end

local function AddDebugContainerContext(player, context, square, containerObject, fluidContainer)
    -- Conditionally build debug container context menu
    if debugMode then
        local playerObject = getSpecificPlayer(player)
        local containerName = utils:getObjectDisplayName(containerObject)
        local containerSubMenuOption = context:addOption("["..enums.modName.."] "..containerName, playerObject, nil);
        local containerSubMenu = context:getNew(context)
        context:addSubMenu(containerSubMenuOption, containerSubMenu)

        local rainFactor = fluidContainer:getRainCatcher()
        containerSubMenu:addOption("Current Rain Factor: " .. tostring(rainFactor), playerObject, nil)

        local baseRainFactor = serviceUtils:getObjectBaseRainFactor(containerObject)
        containerSubMenu:addOption("Base Rain Factor: " .. tostring(baseRainFactor), playerObject, nil)

        local tileHasGutter = utils:getModDataHasGutter(square, nil)
        containerSubMenu:addOption("Tile Gutter: " .. tostring(tileHasGutter), playerObject, nil)

        local isGutterConnected = utils:getModDataIsGutterConnected(containerObject, nil)
        containerSubMenu:addOption("Gutter Connected: " .. tostring(isGutterConnected), playerObject, nil)


        -- if tileHasGutter then
        --     local gutterRoofArea = utils:getModDataRoofArea(square, nil)
        --     if not gutterRoofArea then
        --         gutterRoofArea = isoUtils:getGutterRoofArea(square)
        --     end

        --     local topGutterFloor = isoUtils:findGutterTopLevel(square)
        --     containerSubMenu:addOption("Top Gutter Floor: " .. tostring(topGutterFloor), playerObject, nil)

        --     containerSubMenu:addOption("Gutter Roof Area: " .. tostring(gutterRoofArea), playerObject, nil)
        -- else
        --     local building = square:getBuilding()
        --     utils:modPrint("Tile in building: "..tostring(building))

        --     local roofBuilding = square:getRoofHideBuilding()
        --     if roofBuilding then
        --         utils:modPrint("Roof Building: "..tostring(roofBuilding))
        --     end

        --     local buildingSquare = square
        --     if not building then
        --         building, buildingSquare = isoUtils:getAdjacentBuilding(square)
        --         utils:modPrint("Adjacent Building: "..tostring(building))
        --         if buildingSquare then
        --             roofBuilding = buildingSquare:getRoofHideBuilding()
        --             utils:modPrint("Adjacent Roof Building: "..tostring(roofBuilding))
        --         end
        --     end

        --     if building then
        --         -- Calculate area of top-floor assuming it's 1-1 square -> roof
        --         local area = isoUtils:getBuildingFloorArea(building, nil)
        --         containerSubMenu:addOption("Building Roof Size: " .. tostring(area), playerObject, nil)
        --     else
        --         containerSubMenu:addOption("No Connected Building", playerObject, nil)
        --     end
        -- end
    end
end

local function AddWaterContainerContext(player, context, worldobjects, test)
    for _,worldObject in ipairs(worldobjects) do
        if worldObject then
            if utils:isDrainPipe(worldObject) then
                local square = worldObject:getSquare()
                AddGutterSystemContext(player, context, square, worldObject)
                break

                -- local fluidContainer = worldObject:getFluidContainer()
                -- if fluidContainer then
                --     local square = worldObject:getSquare()
                --     if fluidContainer and square and serviceUtils:isValidContainerObject(worldObject) then
                --         AddGutterContainerContext(player, context, square, worldObject, fluidContainer)

                --         -- AddDebugContainerContext(player, context, square, worldObject, fluidContainer)
                --         break
                --     end
                -- end
            end
        end
    end
end

local function checkDebugMode()
    debugMode = options:getDebug()
end

Events.OnLoad.Add(checkDebugMode)

Events.OnFillWorldObjectContextMenu.Add(AddWaterContainerContext)