if isClient() then return end

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local FluidContainerService = require("collector/FG_Collector_FluidContainer")
local TroughService = require("collector/FG_Collector_Trough")

require("FG_Utils_MapObjects")

local gutterService = {}

gutterService.collectorServiceMap = {
    [enums.collectorType.fluidContainer] = FluidContainerService,
    [enums.collectorType.trough] = TroughService,
}

-- TODO
gutterService.pipeServiceMap = {
    [enums.pipeType.drain] = nil,
    [enums.pipeType.vertical] = nil,
    [enums.pipeType.horizontal] = nil,
}

-- TODO gutterService:getPipeService(pipeObject)

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

    containerService:connectCollector(collectorObject, gutterSystemRainFactor)

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