if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local BaseCollectorServiceInterface = require("collector/FG_Collector_Base")

local FluidContainerService = BaseCollectorServiceInterface:derive("FluidContainerService")

function FluidContainerService:isObjectType(object)
    return serviceUtils:isFluidContainerObject(object)
end

function FluidContainerService:connectCollector(object, gutterRainFactor)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Unable to connect an object without a FluidContainer: "..tostring(object))
        return false
    end

    local baseCollectorRainFactor = serviceUtils:getObjectBaseRainFactorHeavy(object)
    local connectedCollectorRainFactor = baseCollectorRainFactor + gutterRainFactor
    utils:modPrint("Base collector rain factor: "..tostring(baseCollectorRainFactor))
    utils:modPrint("Upgraded collector rain factor: "..tostring(connectedCollectorRainFactor))
    utils:modPrint("Setting rain factor from "..tostring(baseCollectorRainFactor).." to "..tostring(connectedCollectorRainFactor))
    fluidContainer:setRainCatcher(connectedCollectorRainFactor)

    local objectModData = object:getModData()
    objectModData[enums.modDataKey.isGutterConnected] = true
    objectModData[enums.modDataKey.baseRainFactor] = baseCollectorRainFactor

    return true
end

function FluidContainerService:disconnectCollector(object)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Unable to disconnect an object without a FluidContainer: "..tostring(object))
        return false
    end

    local baseRainFactor = serviceUtils:getObjectBaseRainFactorHeavy(object)
    utils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)

    local objectModData = object:getModData()
    objectModData[enums.modDataKey.isGutterConnected] = nil
    objectModData[enums.modDataKey.baseRainFactor] = baseRainFactor

    return true
end

return FluidContainerService