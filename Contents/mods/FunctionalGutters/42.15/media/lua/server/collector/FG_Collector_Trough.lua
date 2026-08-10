if isClient() then return end

local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local FluidContainerService = require("collector/FG_Collector_FluidContainer")

local TroughService = FluidContainerService:derive("TroughService")

local fluidType = FluidType

function TroughService:isObjectType(object)
    return troughUtils:isTrough(object)
end

function TroughService:connectCollector(containerObject, gutterRainFactor)
    if not troughUtils:isTroughObject(containerObject) then
        utils:modPrint("Cannot connect non-IsoFeedingTrough object")
        return false
    end

    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTrough(containerObject)
    if not primaryContainerObject then
        return false
    end

    local success = FluidContainerService:connectCollector(primaryContainerObject, gutterRainFactor)

    -- Add a small amount of water to 'lock' the trough in fluid mode and prevent the FluidContainer from resetting in rare situations
    if success then
        local fluidContainer = primaryContainerObject:getFluidContainer()
        if fluidContainer:isEmpty() then
            utils:modPrint("Adding water to trough container: "..tostring(primaryContainerObject))
            primaryContainerObject:addWater(fluidType.TaintedWater, 0.42)
        end
    end

    return success
end

function TroughService:disconnectCollector(containerObject)
    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTrough(containerObject)
    if not primaryContainerObject then
        return false
    end

    return FluidContainerService:disconnectCollector(primaryContainerObject)
end

return TroughService