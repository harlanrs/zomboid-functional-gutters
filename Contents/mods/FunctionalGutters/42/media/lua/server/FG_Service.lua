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

    -- TODO Need to get the connected tile if the object is a multi-tile trough

    -- Calculate the rain factor for the gutter system routed from the collector's tile
    local square = collectorObject:getSquare()
    local gutterSegment = serviceUtils:calculateGutterSegment(square)

    containerService:connectCollector(collectorObject, gutterSegment.rainFactor)
end

function gutterService:disconnectCollector(collectorObject)
    local containerService = self:getCollectorService(collectorObject)
    if not containerService then
        return
    end

    containerService:disconnectCollector(collectorObject)
end

return gutterService