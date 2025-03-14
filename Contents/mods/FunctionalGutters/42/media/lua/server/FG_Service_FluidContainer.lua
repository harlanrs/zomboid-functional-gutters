if isClient() then return end

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local BaseContainerServiceInterface = require("FG_Service_BaseContainer")

local FluidContainerService = BaseContainerServiceInterface:derive("FluidContainerService")
local localLuaUtils = luautils

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
    -- 1 tile is 1 meter squared
    -- 
    -- 1 millimeter (mm) of rain means 1 liter of water falling on every square meter of area
    --
    -- Drizzle: Less than 2 mm/hr 
    -- Light Rain: 2-4 mm/hr 
    -- Moderate Rain: 4-7.6 mm/hr 
    -- Heavy Rain: Greater than 7.6 mm/hr 

    -- unadjusted that means for 1 tile, 
    -- 1-2 liters of water per hour for a slight drizzle
    -- 2-4 liters of water per hour for light rain
    -- 4-7.6 liters of water per hour for moderate rain
    -- 7.6+ liters of water per hour for heavy rain

    -- Rain intensity is already factored into base game systems so we need to decide an efficiency multiplier
    -- with a goal of aiming somewhere in the middle/middle low range to be useful but not make water trivial while still giving reason to expand the system

    local baseRainFactor = serviceUtils:getObjectBaseRainFactorHeavy(object)

    -- TODO aim for this value to be 1.0 with mod options between 0.0 and 2.0
    local roofTileRainFactor = options:getGutterRainFactor() -- TODO rename to "gutterTileRainFactor"
    local gutterEfficiencyFactor = 0.70 -- TODO each gutter pipe can has its own factor based on 'quality' up to 95% efficiency

    -- TODO
    local averageGutterPerimeterCoverage = 6 -- meters of roof's perimeter covered effectively by a single gutter for a standard house
    local averageGutterCapacityRatio = 0.15 -- ratio of perimeter side length to max surface area covered by a single gutter
    local averageGutterCapacity = averageGutterPerimeterCoverage / averageGutterCapacityRatio -- meters

    local estimatedGutterCount = roofArea / averageGutterCapacity
    local gutterTileCount = averageGutterCapacity

    if estimatedGutterCount > 2.6 then
        estimatedGutterCount = 4
    elseif estimatedGutterCount > 1.3 then
        estimatedGutterCount = 2
    else
        -- roof area under gutter capacity covered by 1
        -- means all roof area is covered by gutter
        if estimatedGutterCount < 1 then
            gutterTileCount = roofArea
        end

        estimatedGutterCount = 1
    end

    -- TODO get current gutter count
    -- ATM assume 1
    utils:modPrint("total gutter count: "..tostring(estimatedGutterCount))
    utils:modPrint("initial gutter tile count: "..tostring(gutterTileCount))

    if estimatedGutterCount > 1 then
        local roofSegment = roofArea / estimatedGutterCount
        local remainingArea = roofSegment - averageGutterCapacity
        gutterTileCount = roofSegment
        utils:modPrint("Remaining area: "..tostring(remainingArea))
        if remainingArea >= estimatedGutterCount then
            -- Divide the remaining area among each estimated gutter
            local gutterCapacityOverflow = remainingArea / estimatedGutterCount
            utils:modPrint("gutter Overflow Capacity: "..tostring(gutterCapacityOverflow))
            local gutterOverflowEfficiency = 0.15
            local gutterOverflowTileCount = gutterCapacityOverflow * gutterOverflowEfficiency
            utils:modPrint("gutter Overflow Tile Count: "..tostring(gutterOverflowTileCount))
            gutterTileCount = gutterTileCount + gutterOverflowTileCount
        end
    end
    
    utils:modPrint("total gutter tile count: "..tostring(gutterTileCount))
   
    -- Effective tiles covered by the gutter system
    -- local gutterTileRainFactor = roofTileRainFactor * gutterTileCount

    -- The total factor for the specific pipe based on it's own gutter efficiency
    local gutterSegmentRainFactor = gutterTileCount * gutterEfficiencyFactor / 10 * roofTileRainFactor

    -- The total factor for the entire gutter system including the base container
    local totalUpgradedRainFactor = baseRainFactor + gutterSegmentRainFactor
    utils:modPrint("Base object rain factor: "..tostring(baseRainFactor))
    utils:modPrint("Gutter tile rain factor: "..tostring(roofTileRainFactor))
    utils:modPrint("Roof area: "..tostring(roofArea))
    utils:modPrint("Gutter efficiency factor: "..tostring(gutterEfficiencyFactor))
    utils:modPrint("Estimated gutter count: "..tostring(estimatedGutterCount))
    utils:modPrint("Gutter segment rain factor: "..tostring(gutterSegmentRainFactor))
    utils:modPrint("Total upgraded factor: "..tostring(totalUpgradedRainFactor))
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