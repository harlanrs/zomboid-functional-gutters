if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local FluidContainerService = require("FG_Service_FluidContainer")
local TroughService = require("FG_Service_Trough")

local gutterService = {}

gutterService.containerInterfaceMap = {
    [enums.containerType.fluidContainer] = FluidContainerService,
    [enums.containerType.trough] = TroughService,
}

function gutterService:getContainerService(containerObject)
    -- Filter out IsoWorldInventoryObjects for now
    if instanceof(containerObject, "IsoWorldInventoryObject") then
        utils:modPrint("IsoWorldInventoryObjects not supported yet")
        return nil
    end

    if TroughService:isObjectType(containerObject) then
        return TroughService
    elseif FluidContainerService:isObjectType(containerObject) then
        return FluidContainerService
    end

    utils:modPrint("No service interface found for container object: "..tostring(containerObject))
    return nil
end

function gutterService:connectContainer(containerObject, roofArea)
    local containerService = self:getContainerService(containerObject)
    if not containerService then
        return
    end

    -- TODO Need to get the connected tile if the object is a multi-tile trough
    -- Get the square's roofArea
    local square = containerObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square, nil)
    local gutterRoofArea = utils:getModDataRoofArea(square, squareModData)

    containerService:connectContainer(containerObject, gutterRoofArea)

    -- Temp patch
    utils:patchModData(containerObject, false)
end

function gutterService:disconnectContainer(containerObject)
    local containerService = self:getContainerService(containerObject)
    if not containerService then
        return
    end

    containerService:disconnectContainer(containerObject)

    -- Temp patch
    utils:patchModData(containerObject, false)
end

return gutterService