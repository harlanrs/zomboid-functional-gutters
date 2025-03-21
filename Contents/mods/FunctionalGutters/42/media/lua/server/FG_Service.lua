if isClient() then return end

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local serviceUtils = require("FG_Utils_Service")
local FluidContainerService = require("collector/FG_Collector_FluidContainer")
local TroughService = require("collector/FG_Collector_Trough")
local DrainPipeService = require("pipe/FG_Pipe_Drain")
local VerticalPipeService = require("pipe/FG_Pipe_Vertical")
local GutterPipeService = require("pipe/FG_Pipe_Gutter")

require("FG_Utils_MapObjects")

local gutterService = {}

gutterService.collectorServiceMap = {
    [enums.collectorType.fluidContainer] = FluidContainerService,
    [enums.collectorType.trough] = TroughService,
}

gutterService.pipeServiceMap = {
    [enums.pipeType.drain] = DrainPipeService,
    [enums.pipeType.vertical] = VerticalPipeService,
    [enums.pipeType.gutter] = GutterPipeService,
    [enums.pipeType.horizontal] = nil,
}

function gutterService:getCollectorService(collectorObject)
    -- Filter out IsoWorldInventoryObjects for now
    if instanceof(collectorObject, "IsoWorldInventoryObject") then
        utils:modPrint("IsoWorldInventoryObjects not supported yet")
        return nil
    end

    if TroughService:isObjectType(collectorObject) then
        return TroughService
    elseif FluidContainerService:isObjectType(collectorObject) then
        return FluidContainerService
    end

    utils:modPrint("No collector service interface found for object: "..tostring(collectorObject))
    return nil
end

function gutterService:getPipeService(pipeObject)
    local objectSprite = pipeObject:getSpriteName()
    if not objectSprite then
        utils:modPrint("No sprite name found for object: "..tostring(pipeObject))
        return nil
    end

    local pipeType = utils:getSpriteCategory(objectSprite)
    if not pipeType then
        utils:modPrint("No pipe type not found for object: "..tostring(pipeObject))
        return nil
    end

    local pipeService = self.pipeServiceMap[pipeType]
    if not pipeService then
        utils:modPrint("No pipe service interface found for object: "..tostring(objectSprite).." with type: "..tostring(pipeType))
        return nil
    end

    return pipeService
end

function gutterService:connectCollector(collectorObject)
    local containerService = self:getCollectorService(collectorObject)
    if not containerService then
        return
    end

    -- TODO make distinction between containerService and pipeService with gutterService as orchestrator
    -- TODO consolidate into pipe service
    -- TODO Need to get the connected tile if the object is a multi-tile trough
    -- TODO do full pipe system check and generate the gutterSystemRainFactor to pass into the connect method (the collector shouldn't know or care about gutter system details)

    -- Calculate the rain factor for the gutter system routed from the collector's tile
    local square = collectorObject:getSquare()
    local gutterSystemRainFactor = serviceUtils:calculateGutterSystemRainFactor(square)

    local success = containerService:connectCollector(collectorObject, gutterSystemRainFactor)
    if success then
        -- TODO trigger a re-crawl of the pipe system to upscale a connected collector's rain factor
        local closeDrains = isoUtils:findAllPipesInRadius(square, 16, enums.pipeType.drain)
        if closeDrains and #closeDrains > 0 then
            for i=1, #closeDrains do
                local drainSquare = closeDrains[i]:getSquare()
                if drainSquare then
                    utils:modPrint("Close drain found on square: "..tostring(drainSquare:getX())..","..tostring(drainSquare:getY())..","..tostring(drainSquare:getZ()))
                end
                -- local drainService = self:getPipeService(drain)
                -- if drainService then
                --     utils:modPrint("Close drain found on square: "..tostring(drain))
                --     -- TODO recrawl and sync the pipes
                --     -- drainService:recalculateRainFactor(drain)
                -- end
            end
        end
    end

    -- Temp patch
    utils:patchModData(collectorObject, false)
end

function gutterService:disconnectCollector(collectorObject)
    local containerService = self:getCollectorService(collectorObject)
    if not containerService then
        return
    end

    containerService:disconnectCollector(collectorObject)

    -- Temp patch
    utils:patchModData(collectorObject, false)
end

return gutterService