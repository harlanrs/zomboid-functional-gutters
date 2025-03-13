if isClient() then return end

require "FluidType"

local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local globalObjectUtils = require("FG_Utils_GlobalObject")
local FluidContainerService = require("FG_Service_FluidContainer")

local TroughService = FluidContainerService:derive("TroughService")

local fluidType = FluidType

function TroughService:isObjectType(object)
    return troughUtils:isTrough(object)
end

function TroughService:connectContainer(containerObject, roofArea)
    if troughUtils:isTroughSprite(containerObject:getSpriteName()) and not troughUtils:isTroughObject(containerObject) then
        -- Trough is still an IsoObject and needs to be converted to IsoFeedingTrough with a global object
        containerObject = globalObjectUtils:loadFullTrough(containerObject)
        if not containerObject then return false end
    end

    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTroughFromDef(containerObject)
    if not primaryContainerObject then
        return false
    end

    -- If roofArea is nil, check for secondary tile

    local success = FluidContainerService:connectContainer(primaryContainerObject, roofArea)

    -- Add a small amount of water to 'lock' the trough in fluid mode and prevent the FluidContainer from resetting in rare situations
    local fluidContainer = primaryContainerObject:getFluidContainer()
    if success and fluidContainer:isEmpty() then
        utils:modPrint("Adding water to trough container: "..tostring(primaryContainerObject))
        primaryContainerObject:addWater(fluidType.TaintedWater, 0.42)
    end

    return success
end

function TroughService:disconnectContainer(containerObject)
    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTroughFromDef(containerObject)
    if not primaryContainerObject then
        return false
    end

    return FluidContainerService:disconnectContainer(primaryContainerObject)
end

return TroughService