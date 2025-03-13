if isClient() then return end

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local BaseContainerServiceInterface = require("FG_Service_BaseContainer")

local FluidContainerService = BaseContainerServiceInterface:derive("FluidContainerService")

function FluidContainerService:isObjectType(object)
    return serviceUtils:isFluidContainerObject(object)
end

function FluidContainerService:connectContainer(object, roofArea)
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then
        utils:modPrint("Unable to connect an object without a FluidContainer: "..tostring(object))
        return false
    end

    if not roofArea then
        utils:modPrint("Roof area not provided for object: "..tostring(object))
        roofArea = 0
    end

    -- TEMP playground
    local baseRainFactor = serviceUtils:getObjectBaseRainFactorHeavy(object)

    -- TODO aim for this value to be 1.0 with mod options between 0.0 and 2.0
    local gutterRainFactor = options:getGutterRainFactor() -- TODO rename to "gutterTileRainFactor"
    -- TODO 
    local gutterEfficiencyFactory = 0.25 -- options:getGutterEfficiencyFactory() -- TODO each gutter pipe can has its own factor based on 'quality' tbd
    local maxGutterCount = 4 -- pretending that there is a gutter drain pipe on each corner for houses over X size
    local averageGutterCoverage = 9 -- meters per gutter for a standard house
    local estimatedGutterCount = roofArea / averageGutterCoverage -- total gutter pipes needed to properly cover the roof
    -- if estimatedGutterCount > maxGutterCount then
    --     estimatedGutterCount = maxGutterCount
    -- end
    if estimatedGutterCount < 1 then
        estimatedGutterCount = 1
    end

    -- Total water falling on the roof
    local gutterSystemFactor = gutterRainFactor * roofArea
    -- Total per gutter pipes for proper "coverage"
    local gutterSystemPipePortion = gutterSystemFactor / estimatedGutterCount
    -- The total factor for the specific pipe based on it's own gutter efficiency
    local totalGutterPipeFactor = gutterSystemPipePortion * gutterEfficiencyFactory
    local totalUpgradedRainFactor = baseRainFactor + totalGutterPipeFactor
    utils:modPrint("Base object rain factor: "..tostring(baseRainFactor))
    utils:modPrint("Gutter tile rain factor: "..tostring(gutterRainFactor))
    utils:modPrint("Roof area: "..tostring(roofArea))
    utils:modPrint("Gutter efficiency factor: "..tostring(gutterEfficiencyFactory))
    utils:modPrint("Estimated gutter count: "..tostring(estimatedGutterCount))
    utils:modPrint("Gutter system factor: "..tostring(gutterSystemFactor))
    utils:modPrint("Gutter system pipe portion: "..tostring(gutterSystemPipePortion))
    utils:modPrint("Total gutter pipe factor: "..tostring(totalGutterPipeFactor))
    utils:modPrint("Setting rain factor from "..tostring(baseRainFactor).." to "..tostring(totalUpgradedRainFactor))
    fluidContainer:setRainCatcher(totalUpgradedRainFactor)

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

    local baseRainFactor = serviceUtils:getObjectBaseRainFactorHeavy(object)
    utils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)

    local objectModData = object:getModData()
    objectModData[enums.modDataKey.isGutterConnected] = nil
    objectModData[enums.modDataKey.baseRainFactor] = baseRainFactor

    return true
end

return FluidContainerService