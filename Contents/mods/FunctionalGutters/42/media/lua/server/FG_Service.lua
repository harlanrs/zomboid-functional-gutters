if isClient() then return end

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local FluidContainerService = require("collector/FG_Collector_FluidContainer")
local TroughService = require("collector/FG_Collector_Trough")

require("FG_Utils_MapObjects")

local gutterService = {}

gutterService.collectorServiceMap = {
    [enums.collectorType.fluidContainer] = FluidContainerService,
    [enums.collectorType.trough] = TroughService,
}

-- TODO
gutterService.pipeServiceMap = {
    [enums.pipeType.drain] = nil,
    [enums.pipeType.vertical] = nil,
    [enums.pipeType.horizontal] = nil,
}

-- TODO gutterService:getPipeService(pipeObject)

-- TODO move into pipe service once created
function gutterService:calculateGutterSystemRainFactor(square)
    -- TEMP playground to test stuff
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

    -- Rain intensity is already factored into base game systems so we need to balance the generated rain factor to be useful but not trivial or too powerful
    -- Realistically a roof gutter system would produce nearly an entire rain barrel's worth of water (600l) in just a few hours when considering the area of the roof

    local squareModData = serviceUtils:syncSquareModData(square, true)
    local roofArea = utils:getModDataRoofArea(square, squareModData)
    if not roofArea then
        utils:modPrint("No roof area found for square: "..tostring(square))
        return 0.0
    end

    -- Aim for this value to be 1.0 with mod options between 0.0 and 2.0
    local roofTileRainFactor = options:getGutterRainFactor() -- TODO rename to "gutterTileRainFactor"
    local gutterEfficiencyFactor = 0.70 -- TODO each gutter pipe can has its own factor based on 'quality' up to 95% efficiency
    -- TODO should take an average of quality across all connected gutter pipes but maybe save that for later

    -- Meters of roof's perimeter covered effectively by a single gutter for a standard house
    -- Realistically this is between 6 and 9 meters
    local averageGutterPerimeterCoverage = 6

    -- Meters of roof's area covered effectively by a single gutter for a standard house
    -- Don't want to simply take the square of the perimeter coverage as this wouldn't be very accurate for a real roof and would overload the influence of the gutter perimeter value
    -- ex: 6 -> 36 vs 9 -> 81 - should be aiming for linear ratio not exponential
    -- Instead aiming for a ratio that produces a reasonable rectangle of tiles covered relative to the perimeter coverage
    local averageGutterCapacityRatio = 0.15 -- ratio of perimeter side length to max surface area covered by a single gutter
    local averageGutterCapacity = averageGutterPerimeterCoverage / averageGutterCapacityRatio -- meters
    -- ex: 6 -> 40 vs 9 -> 60

    local estimatedGutterCount = roofArea / averageGutterCapacity
    local gutterTileCount = averageGutterCapacity

    -- Light representation of the gutter system as a whole
    -- Gutters are typically designed to work together as a unit to cover the entire roof (ex: one on each "side" of a roof slant direction or one on each corner)
    -- Here we are estimating the number of gutter drain systems needed relative to the roof's area
    -- Once a single gutter's coverage capacity is exceeded by 30% we add another expected gutter system 'slot'
    -- Since these usually work in pairs we only really care about 1, 2, and 4.
    -- This allows us to set up a single gutter on a small building for full coverage but the same gutter on a larger building might not be 100% as effective
    -- ex: 1 gutter can cover all 40 tiles on a small house but when added to a 'medium' house of 60 tiles the one gutter will only cover 30 tiles since it is expected to have another gutter covering the other side
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

    -- TODO get current existing gutter count
    -- ATM assume 1
    utils:modPrint("total gutter count: "..tostring(estimatedGutterCount))
    utils:modPrint("initial gutter tile count: "..tostring(gutterTileCount))

    -- Divides up the area of the roof into segments for each estimated gutter and calculates the effective tiles covered by each gutter
    -- Ex: 70 tile roof with 2 gutter capacity would have 35 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Ex: 110 tile roof with 4 estimated gutters would have 27.5 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Additionally since we stop at 4 gutter capacity, any leftover area is divided up among the estimated gutter capacity but at a highly reduced efficiency
    -- Ex: 180 tile roof with 4 estimated gutters would have 40 tiles covered by each gutter and 5 "overflow" tiles covered by each gutter at 15% efficiency
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
    utils:modPrint("Gutter tile rain factor: "..tostring(roofTileRainFactor))
    utils:modPrint("Roof area: "..tostring(roofArea))
    utils:modPrint("Gutter efficiency factor: "..tostring(gutterEfficiencyFactor))
    utils:modPrint("Estimated gutter count: "..tostring(estimatedGutterCount))
    utils:modPrint("Gutter segment rain factor: "..tostring(gutterSegmentRainFactor))
    return gutterSegmentRainFactor
end

function gutterService:getCollectorService(collectorObject)
    -- Filter out IsoWorldInventoryObjects for now
    if instanceof(collectorObject, "IsoWorldInventoryObject") then
        utils:modPrint("IsoWorldInventoryObjects not supported yet")
        return nil
    end

    if TroughService:isObjectType(collectorObject) then
        return TroughService
    elseif FluidContainerService:isObjectType(collectorObject) then
        return FluidContainerService
    end

    utils:modPrint("No collector service interface found for object: "..tostring(collectorObject))
    return nil
end


function gutterService:connectCollector(collectorObject)
    local containerService = self:getCollectorService(collectorObject)
    if not containerService then
        return
    end

    -- TODO make distinction between containerService and pipeService with gutterService as orchestrator
    -- TODO consolidate into pipe service
    -- TODO Need to get the connected tile if the object is a multi-tile trough
    -- TODO do full pipe system check and generate the gutterSystemRainFactor to pass into the connect method (the collector shouldn't know or care about gutter system details)

    -- Calculate the rain factor for the gutter system routed from the collector's tile
    local square = collectorObject:getSquare()
    local gutterSystemRainFactor = self:calculateGutterSystemRainFactor(square)

    containerService:connectCollector(collectorObject, gutterSystemRainFactor)

    -- Temp patch
    utils:patchModData(collectorObject, false)
end

function gutterService:disconnectCollector(collectorObject)
    local containerService = self:getCollectorService(collectorObject)
    if not containerService then
        return
    end

    containerService:disconnectCollector(collectorObject)

    -- Temp patch
    utils:patchModData(collectorObject, false)
end

return gutterService