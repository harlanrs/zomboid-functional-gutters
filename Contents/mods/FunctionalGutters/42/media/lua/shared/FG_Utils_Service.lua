local enums = require("FG_Enums")
local utils = require("FG_Utils")
local options = require("FG_Options")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

local table_insert = table.insert

local serviceUtils = {}

function serviceUtils:isFluidContainerObject(containerObject)
    return instanceof(containerObject, "IsoObject") and containerObject:getFluidContainer() ~= nil
end

function serviceUtils:isValidContainerObject(containerObject)
    return troughUtils:isTrough(containerObject) or self:isFluidContainerObject(containerObject)
end

function serviceUtils:getObjectBaseRainFactor(object)
    -- Note: trough objects don't have an initial FluidContainer and the rain factor is hard coded on initial creation
    if troughUtils:isTrough(object) then
        return enums.troughBaseRainFactor
    end

    -- Check object's GameEntityScript
    local baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Check object's modData
    baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

function serviceUtils:setDrainPipeModData(square, squareModData)
    -- Calculate the number of 'roof' tiles above the drain pipe
    utils:modPrint("Setting drain pipe mod data for square: "..tostring(square))
    squareModData[enums.modDataKey.roofArea] = isoUtils:getGutterRoofArea(square)
end

function serviceUtils:cleanupDrainPipeModData(square, squareModData)
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing drain pipe mod data for square: "..tostring(square))
    -- The square no longer has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.roofArea] = nil
end

function serviceUtils:syncSquareRoofModData(square, squareModData)
    -- Re-evaluate if the square is still valid as a roof tile
    if not squareModData then
        squareModData = square:getModData()
    end

    local isRoofSquare = utils:getModDataIsRoofSquare(square, squareModData)
    if isRoofSquare and not isoUtils:isValidPlayerBuiltFloor(square) then
        squareModData[enums.modDataKey.isRoofSquare] = nil
    end

    return squareModData
end

function serviceUtils:syncSquarePipeModData(square, reload)
    local squareModData = square:getModData()
    local roofArea = utils:getModDataRoofArea(square, squareModData)
    local hasDrainPipe = utils:isDrainPipeSquare(square)
    if hasDrainPipe and (reload or not roofArea) then
        self:setDrainPipeModData(square, squareModData)
    end

    -- Cleanup square mod data if pipes were removed
    -- TODO should this be explicitly called from the event handler instead?
    if not hasDrainPipe and roofArea then
        self:cleanupDrainPipeModData(square, squareModData)
    end

    return squareModData
end

function serviceUtils:getAverageGutterCapacity()
    -- Meters of roof's perimeter covered effectively by a single gutter drain for a standard house
    -- Realistically this is between 6 and 9 meters
    local averageGutterPerimeterCoverage = enums.gutterSegmentPerimeterLength

    -- Ratio of perimeter side length to max surface area covered by a single gutter
    local averageGutterCapacityRatio = enums.gutterSegmentCapacityRatio

    -- Meters of roof's area covered effectively by a single gutter for a standard house
    -- Don't want to simply take the square of the perimeter coverage as this wouldn't be very accurate for a real roof and would over-emphasize the gutter perimeter value
    -- ex: 6 -> 36 vs 9 -> 81 (exponential)
    -- Instead aiming for a ratio that produces a reasonable 'rectangle' of tiles covered relative to the perimeter coverage
    -- ex: 6 -> 24 vs 9 -> 36 (linear)
    return averageGutterPerimeterCoverage / averageGutterCapacityRatio
end

function serviceUtils:getLocalDrainPipes(square, radius)
    -- Grab all nearby squares with a drain pipe object
    if not radius then
        radius = enums.defaultDrainPipeSearchRadius
    end
    local drainPipes = isoUtils:findAllDrainsInRadius(square, radius)
    if not drainPipes or #drainPipes == 0 then
        return nil
    end

    -- Determine if square has a pre-built building or is a player-built structure
    local buildingDef = isoUtils:getAttachedBuilding(square)
    if not buildingDef then
       -- No building found - assume player-built structure and return all drain pipes
       return drainPipes
    end

    -- Reduce the list of drain pipes to only those relevant to the building mode
    -- TODO eventually check modData if we allow for players to 'convert' buildings to use manually placed gutters
    local associatedDrainPipes = table.newarray()
    for i=1, #drainPipes do
        local drainPipe = drainPipes[i]
        local attachedBuildingDef = isoUtils:getAttachedBuilding(drainPipe:getSquare())
        if buildingDef then
            -- Vanilla building mode
            -- Check if the drain pipe is attached to the same building
            if attachedBuildingDef and attachedBuildingDef:getID() == buildingDef:getID() then
                table_insert(associatedDrainPipes, drainPipe)
            end
        else
            -- Custom building mode
            -- Check if the drain is not attached to any building
            if not attachedBuildingDef then
                table_insert(associatedDrainPipes, drainPipe)
            end
        end
    end

    return associatedDrainPipes
end

function serviceUtils:getLocalDrainPipes3D(square, radius, zRadius)
    if not radius then
        radius = enums.defaultDrainPipeSearchRadius
    end
    if not zRadius then
        zRadius = enums.defaultDrainPipeSearchHeight
    end
    local drainPipes = self:getLocalDrainPipes(square, radius)
    if not drainPipes then
        drainPipes = table.newarray()
    end

    local x = square:getX()
    local y = square:getY()
    local z =  square:getZ()
    for i=1, zRadius + 1 do -- TODO can't remember why +1?
        -- Check up zRadius levels
        local upZ = z + i
        local upSquare = square:getCell():getGridSquare(x, y, upZ)
        if upSquare then
            local zDrainPipes = self:getLocalDrainPipes(upSquare, radius)
            if zDrainPipes then
                for iter=1, #zDrainPipes do
                    table_insert(drainPipes, zDrainPipes[iter])
                end
            end
        end
    end

    if z > 0 then
        -- Check down zRadius levels
        for i=1, zRadius do
            local downZ = z - i
            if downZ < 0 then
                break
            end
            local downSquare = square:getCell():getGridSquare(x, y, downZ)
            if downSquare then
                local zDrainPipes = self:getLocalDrainPipes(downSquare, radius)
                if zDrainPipes then
                    for iter=1, #zDrainPipes do
                        table_insert(drainPipes, zDrainPipes[iter])
                    end
                end
            end
        end
    end

    return drainPipes
end

function serviceUtils:getActualGutterDrainCount(square)
    local drainPipes = self:getLocalDrainPipes3D(square, enums.defaultDrainPipeSearchRadius, enums.defaultDrainPipeSearchHeight)
    if not drainPipes then
        return 0
    end

    return #drainPipes
end

function serviceUtils:getEstimatedGutterDrainCount(roofArea, averageGutterCapacity)
    -- Light representation of the gutter system as a whole
    -- Gutters are typically designed to work together as a unit to cover the entire roof (ex: one on each "side" of a roof slant direction or one on each corner)
    -- Here we are estimating the number of gutter drain systems needed relative to the roof's surface area (flat)
    -- Once a single gutter drain's coverage capacity is exceeded by 30% we add another expected gutter drain 'slot'
    -- This allows us to set up a single gutter on a small building for full coverage but the same gutter on a larger building might not be 100% as effective
    -- ex: 1 gutter can cover all 40 tiles on a small house but when added to a 'medium' house of 60 tiles the one gutter will only cover 30 tiles since it is expected to have another gutter covering the other side
    if not averageGutterCapacity then
        averageGutterCapacity = self:getAverageGutterCapacity()
    end

    local estimatedGutterCount = roofArea / averageGutterCapacity

    if estimatedGutterCount > 3.9 then
        estimatedGutterCount = 4
    elseif estimatedGutterCount > 2.6 then
        estimatedGutterCount = 3
    elseif estimatedGutterCount > 1.3 then
        estimatedGutterCount = 2
    else
        estimatedGutterCount = 1
    end

    return estimatedGutterCount
end

function serviceUtils:calculateGutterSegmentTileCount(roofArea, optimalDrainCount, actualDrainCount, averageGutterCapacity)
    -- Divides up the area of the roof into segments for each estimated gutter and calculates the effective tiles covered by each gutter
    -- Ex: 70 tile roof with 2 gutter capacity would have 35 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Ex: 110 tile roof with 4 estimated gutters would have 27.5 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Additionally since we stop at 4 gutter capacity, any leftover area is divided up among the estimated gutter capacity but at a highly reduced efficiency
    -- Ex: 180 tile roof with 4 estimated gutters would have 40 tiles covered by each gutter and 5 "overflow" tiles covered by each gutter at 25% efficiency
    if not averageGutterCapacity then
        averageGutterCapacity = self:getAverageGutterCapacity()
    end

    local gutterTileCount = roofArea / optimalDrainCount
    local remainingArea = gutterTileCount - averageGutterCapacity
    if remainingArea >= 1 then
        -- Set the gutter tile count to the average (max) capacity and calculate remainder as overflow
        gutterTileCount = averageGutterCapacity
        local gutterCapacityOverflow = remainingArea
        utils:modPrint("Gutter overflow capacity: "..tostring(gutterCapacityOverflow))

        -- Overflow 'tile' is only 25% as effective since the system is overloaded
        local gutterOverflowEfficiency = 0.25
        local gutterOverflowTileCount = gutterCapacityOverflow * gutterOverflowEfficiency
        utils:modPrint("Gutter overflow tile count: "..tostring(gutterOverflowTileCount))

        -- Prevent the overflow capacity from exceeding 25% of the average gutter capacity
        local maxOverflowArea = averageGutterCapacity * gutterOverflowEfficiency
        if gutterOverflowTileCount > maxOverflowArea then
            utils:modPrint("Gutter overflow capacity exceeds max: "..tostring(maxOverflowArea))
            gutterOverflowTileCount = maxOverflowArea
        end

        gutterTileCount = gutterTileCount + gutterOverflowTileCount
    end

    if actualDrainCount > optimalDrainCount then
        -- Reduce the tile count for each gutter based on the actual number of drain pipes
        local overdraftTileCount = gutterTileCount / actualDrainCount
        gutterTileCount = gutterTileCount - overdraftTileCount
    end

    return gutterTileCount
end

function serviceUtils:calculateGutterSegmentRainFactor(gutterTileCount)
    -- Aim for this value to be 1.0 with mod options between 0.0 and 2.0
    local roofTileRainFactor = options:getGutterRainFactor() -- TODO rename to "gutterTileRainFactor"
    local gutterEfficiencyFactor = 1
    -- TODO each gutter pipe can has its own factor based on 'quality' up to 95% efficiency
    -- TODO should take an average of quality across all connected gutter pipes but maybe save that for later

    -- The total factor for the specific pipe based on it's own gutter efficiency
    local gutterSegmentRainFactor = gutterTileCount * gutterEfficiencyFactor / 10 * roofTileRainFactor
    return gutterSegmentRainFactor
end

function serviceUtils:calculateGutterSegment(square)
    -- Notes:
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
    local gutterSegment = {
        roofArea = 0,
        tileCount = 0,
        optimalDrainCount = 1,
        drainCount = 1,
        rainFactor = 0.0,
        pipeMap = nil,
        roofMap = nil
    }

    if not utils:isDrainPipeSquare(square) then
        -- Check most likely already occurred in external context but just in case
        -- Drain pipes are essentially the main 'nodes' in a gutter system so have to start from their specific squares
        utils:modPrint("Square is not a drain pipe: "..tostring(square))
        return gutterSegment
    end

    gutterSegment.pipeMap = isoUtils:crawlGutterSystem(square)
    local roofArea, roofMap = isoUtils:getGutterRoofArea(square, gutterSegment.pipeMap)
    if not roofArea then
        utils:modPrint("No roof area found for square: "..tostring(square))
        return gutterSegment
    end

    local squareModData = square:getModData()
    squareModData[enums.modDataKey.roofArea] = roofArea
    gutterSegment.roofArea = roofArea
    gutterSegment.roofMap = roofMap

    local averageGutterCapacity = self:getAverageGutterCapacity()
    gutterSegment.optimalDrainCount = self:getEstimatedGutterDrainCount(roofArea, averageGutterCapacity)
    gutterSegment.drainCount = self:getActualGutterDrainCount(square)
    gutterSegment.tileCount = self:calculateGutterSegmentTileCount(roofArea, gutterSegment.optimalDrainCount, gutterSegment.drainCount, averageGutterCapacity)
    gutterSegment.rainFactor = self:calculateGutterSegmentRainFactor(gutterSegment.tileCount)

    utils:modPrint("Roof area: "..tostring(roofArea))
    utils:modPrint("Optimal drain count: "..tostring(gutterSegment.optimalDrainCount))
    utils:modPrint("Actual drain count: "..tostring(gutterSegment.drainCount))
    utils:modPrint("Segment tile count: "..tostring(gutterSegment.tileCount))
    utils:modPrint("Segment rain factor: "..tostring(gutterSegment.rainFactor))
    return gutterSegment
end

return serviceUtils