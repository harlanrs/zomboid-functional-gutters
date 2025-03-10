local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local BaseContainerServiceInterface = require("FG_Service_BaseContainer")

local FluidContainerService = BaseContainerServiceInterface:derive("FluidContainerService")

function FluidContainerService:isObjectType(object)
    return instanceof(object, "IsoObject") and object:getFluidContainer() ~= nil
end

function FluidContainerService:connectContainer(object)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Fluid container not found for object: "..tostring(object))
        return
    end

    local baseRainFactor = serviceUtils:getObjectBaseRainFactor(object)
    local gutterRainFactor = options:getGutterRainFactor()
    utils:modPrint("Setting rain factor from "..tostring(baseRainFactor).." to "..tostring(gutterRainFactor))
    fluidContainer:setRainCatcher(gutterRainFactor)

    utils:setModDataIsGutterConnected(object, true)
    utils:setModDataBaseRainFactor(object, baseRainFactor)
end

function FluidContainerService:disconnectContainer(object)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Fluid container not found for object: "..tostring(object))
        return
    end

    local baseRainFactor = serviceUtils:getObjectBaseRainFactor(object)
    utils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)

    utils:setModDataIsGutterConnected(object, nil)
    utils:setModDataBaseRainFactor(object, baseRainFactor)
end

return FluidContainerService