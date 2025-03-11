require "FluidType"

local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local mapObjectUtils = require("FG_Utils_MapObject")
local FluidContainerService = require("FG_Service_FluidContainer")

local TroughService = FluidContainerService:derive("TroughService")

local fluidType = FluidType

function TroughService:isObjectType(object)
    return troughUtils:isTrough(object)
end

function TroughService:connectContainer(containerObject)
    if troughUtils:isTroughSprite(containerObject:getSpriteName()) and not troughUtils:isTroughObject(containerObject) then
        -- The provided object is still an IsoObject and needs to be converted to a global IsoFeedingTrough object
        containerObject = mapObjectUtils:loadTrough(containerObject)
    end

    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTrough(containerObject)
    if not primaryContainerObject then
        return false
    end

    local success = FluidContainerService:connectContainer(primaryContainerObject)

    -- Add a small amount of water to prevent the FluidContainer from resetting when isoObject is converted to IsoFeedingTrough global object
    local fluidContainer = primaryContainerObject:getFluidContainer()
    if success and fluidContainer:isEmpty() then
        utils:modPrint("Adding water to trough container: "..tostring(primaryContainerObject))
        if troughUtils:isTroughObject(containerObject) then
            -- Note: using IsoFeedingTrough object wrapper for addWater instead of FluidContainer
            primaryContainerObject:addWater(fluidType.TaintedWater, 0.1)
        end
    end

    return success
end

function TroughService:disconnectContainer(containerObject)
    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTrough(containerObject)
    local success = FluidContainerService:disconnectContainer(primaryContainerObject)

    return success
end

return TroughService