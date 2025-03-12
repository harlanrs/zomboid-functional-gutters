require "FluidType"

local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local FluidContainerService = require("FG_Service_FluidContainer")

local TroughService = FluidContainerService:derive("TroughService")

local fluidType = FluidType

function TroughService:isObjectType(object)
    return troughUtils:isTrough(object)
end

function TroughService:connectContainer(containerObject)
    if troughUtils:isTroughSprite(containerObject:getSpriteName()) and not troughUtils:isTroughObject(containerObject) then
        -- Trough is still an IsoObject and needs to be converted to IsoFeedingTrough with a global object
        local primaryTrough = troughUtils:getPrimaryTroughFromDef(containerObject)
        if not primaryTrough then return false end

        local success = troughUtils:upgradeTroughToGlobalObject(primaryTrough)
        if not success then
            utils:modPrint("Failed to convert placed object to global trough: "..tostring(containerObject))
            return false
        end
    end

    -- Ensure the 'primary' trough object is being used for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTroughFromDef(containerObject)
    if not primaryContainerObject then
        return false
    end

    local success = FluidContainerService:connectContainer(primaryContainerObject)

    -- Add a small amount of water to 'lock' the trough in fluid mode and prevent the FluidContainer from resetting in rare situations
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
    local primaryContainerObject = troughUtils:getPrimaryTroughFromDef(containerObject)
    if not primaryContainerObject then
        return false
    end

    return FluidContainerService:disconnectContainer(primaryContainerObject)
end

return TroughService