local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local FluidContainerService = require("FG_Service_FluidContainer")

local TroughService = FluidContainerService:derive("TroughService")

function TroughService:isObjectType(object)
    return troughUtils:isTrough(object)
end

function TroughService:connectContainer(containerObject)
    if not self:isObjectType(containerObject) then
        utils:modPrint("Object is not a trough: "..tostring(containerObject))
        return
    end

    -- Ensure the primary trough object is being used instead of the "secondary" object for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTroughObject(containerObject)
    FluidContainerService:connectContainer(primaryContainerObject)
end

function TroughService:disconnectContainer(containerObject)
    if not self:isObjectType(containerObject) then
        utils:modPrint("Object is not a trough: "..tostring(containerObject))
        return
    end

    -- Ensure the primary trough object is being used instead of the "secondary" object for multi-tile troughs
    local primaryContainerObject = troughUtils:getPrimaryTroughObject(containerObject)
    FluidContainerService:disconnectContainer(primaryContainerObject)
end

return TroughService