local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local BaseContainerServiceInterface = require("FG_Service_BaseContainer")

local FluidContainerService = BaseContainerServiceInterface:derive("FluidContainerService")

function FluidContainerService:isObjectType(object)
    return serviceUtils:isFluidContainerObject(object)
end

function FluidContainerService:connectContainer(object)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Unable to connect an object without a FluidContainer: "..tostring(object))
        return false
    end

    local baseRainFactor = serviceUtils:getObjectBaseRainFactorDeep(object)
    local gutterRainFactor = options:getGutterRainFactor()
    utils:modPrint("Setting rain factor from "..tostring(baseRainFactor).." to "..tostring(gutterRainFactor))
    fluidContainer:setRainCatcher(gutterRainFactor)

    local objectModData = object:getModData()
    objectModData[enums.modDataKey.isGutterConnected] = true
    objectModData[enums.modDataKey.baseRainFactor] = baseRainFactor

    return true
end

function FluidContainerService:disconnectContainer(object)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Unable to disconnect an object without a FluidContainer: "..tostring(object))
        return false
    end

    local baseRainFactor = serviceUtils:getObjectBaseRainFactorDeep(object)
    utils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)

    local objectModData = object:getModData()
    objectModData[enums.modDataKey.isGutterConnected] = nil
    objectModData[enums.modDataKey.baseRainFactor] = baseRainFactor

    return true
end

return FluidContainerService