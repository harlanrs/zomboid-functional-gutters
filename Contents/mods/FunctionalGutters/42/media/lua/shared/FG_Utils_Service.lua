local enums = require("FG_Enums")
local utils = require("FG_Utils")
local options = require("FG_Options")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

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

    -- Check object's modData
    local baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Check object's GameEntityScript
    baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

function serviceUtils:getObjectBaseRainFactorHeavy(object)
    -- Swap the order of checks to prioritize the GameEntityScript over the modData
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


function serviceUtils:setDrainPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting drain pipe mod data for square: "..tostring(square))
    -- The square has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = true

    -- TODO
    -- Test setting object property
    -- local pipeSpriteProps = pipeObject:getSprite():getProperties()
    -- -- if not pipeObjectProps:Is("IsDrainPipe") then
    -- pipeSpriteProps:Set("IsDrainPipe", "", true)
    -- -- end

    -- -- Calculate the number of 'roof' tiles above the drain pipe
    if full or not utils:getModDataRoofArea(square, squareModData) then
        squareModData[enums.modDataKey.roofArea] = isoUtils:getGutterRoofArea(square)
    end
end

function serviceUtils:cleanupDrainPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing drain pipe mod data for square: "..tostring(square))
    -- The square no longer has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = nil
    squareModData[enums.modDataKey.roofArea] = nil
end

function serviceUtils:setVerticalPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting vertical pipe mod data for square: "..tostring(square))
    -- The square has a vertical pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = true

    -- local pipeSpriteProps = pipeObject:getSprite():getProperties()
    -- if not pipeObjectProps:Is("IsVerticalPipe") then
    -- pipeSpriteProps:Set("IsVerticalPipe", "", true)
    -- end
end

function serviceUtils:cleanupVerticalPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing vertical pipe mod data for square: "..tostring(square))
    -- The square no longer has a vertical pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = nil
end

function serviceUtils:setGutterPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting gutter pipe mod data for square: "..tostring(square))
    -- The square has a gutter pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutterPipe] = true

    -- TODO gutterWest, gutterEast, gutterNorth, gutterSouth
    local spriteName = pipeObject:getSpriteName()
    local pipeDef = enums.pipes[spriteName]
    if not pipeDef then
        utils:modPrint("Pipe definition not found for sprite: "..tostring(spriteName))
        return
    end

    -- TODO move to dedicated section
    -- if pipeDef.position == localIsoDirections.N then
    --     -- TODO check for sloped roof north
    --     local upNorthSquare = square:getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ() + 1)
    --     utils:modPrint('Up north square: '..tostring(upNorthSquare:getX())..','..tostring(upNorthSquare:getY())..','..tostring(upNorthSquare:getZ()))
    --     local hasSlopedRoofNorth = square:Has(IsoObjectType.WestRoofB) or square:Has(IsoObjectType.WestRoofM) or square:Has(IsoObjectType.WestRoofT)
    --     local hasSlopedRoofNorth2 = square:HasSlopedRoofNorth()
    --     utils:modPrint("Has sloped roof north: "..tostring(hasSlopedRoofNorth))
    -- elseif pipeDef.position == localIsoDirections.W then
    --     -- TODO check for sloped roof west
    --     local upWestSquare = square:getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ() + 1)
    --     utils:modPrint('Up west square: '..tostring(upWestSquare:getX())..','..tostring(upWestSquare:getY())..','..tostring(upWestSquare:getZ()))
    --     local hasSlopedRoofWest = square:Has(IsoObjectType.WestRoofB) or square:Has(IsoObjectType.WestRoofM) or square:Has(IsoObjectType.WestRoofT)
    --     local hasSlopedRoofWest2 = square:HasSlopedRoofWest()
    --     utils:modPrint("Has sloped roof west: "..tostring(hasSlopedRoofWest))
    -- end
end

function serviceUtils:cleanupGutterPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing gutter pipe mod data for square: "..tostring(square))
    -- The square no longer has a gutter pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutterPipe] = nil

    local hasGutterPipeProp = square:getProperties():Is("IsGutterPipe")
    utils:modPrint("Has gutter pipe prop: "..tostring(hasGutterPipeProp))

    -- TODO gutterWest, gutterEast, gutterNorth, gutterSouth
end



-- TODO try to replace all mod data with props checks when possible
function serviceUtils:syncSquareModData(square, full)
    local objects = square:getObjects()
    local pipeObjects = table.newarray()
    local squareModData = nil

    local hasDrainPipe
    local hasVerticalPipe
    local hasGutterPipe

    for i = 0, objects:size() - 1 do
        -- Check object for pipe sprite category
        local object = objects:get(i)
        local spriteName = object:getSpriteName()
        local spriteCategory = utils:getSpriteCategory(spriteName)
        if spriteCategory then
            table.insert(pipeObjects, object)
            if squareModData == nil then
                squareModData = square:getModData()
            end

            if spriteCategory == enums.pipeType.drain then
                hasDrainPipe = true
                self:setDrainPipeModData(square, squareModData, object, full)
            end

            if spriteCategory == enums.pipeType.vertical then
                hasVerticalPipe = true
                self:setVerticalPipeModData(square, squareModData, object, full)
            end

            if spriteCategory == enums.pipeType.gutter then
                hasGutterPipe = true
                self:setGutterPipeModData(square, squareModData, object,  full)
            end

            -- local hasHorizontalPipe = spriteCategory == enums.pipeType.horizontal
        end
    end

    -- Cleanup square mod data if pipes were removed
    if utils:getModDataHasGutter(square, squareModData) and not hasDrainPipe then
        self:cleanupDrainPipeModData(square, squareModData)
    end

    if utils:getModDataHasVerticalPipe(square, squareModData) and not hasVerticalPipe then
        self:cleanupVerticalPipeModData(square, squareModData)
    end

    if utils:getModDataHasGutterPipe(square, squareModData) and not hasGutterPipe then
        self:cleanupGutterPipeModData(square, squareModData)
    end

    return squareModData
end

function serviceUtils:getAverageGutterCapacity()
    -- Meters of roof's perimeter covered effectively by a single gutter drain for a standard house
    -- Realistically this is between 6 and 9 meters
    local averageGutterPerimeterCoverage = 9

    -- Meters of roof's area covered effectively by a single gutter for a standard house
    -- Don't want to simply take the square of the perimeter coverage as this wouldn't be very accurate for a real roof and would over-emphasize the gutter perimeter value
    -- ex: 6 -> 36 vs 9 -> 81 - need linear ratio not exponential
    -- Instead aiming for a ratio that produces a reasonable 'rectangle' of tiles covered relative to the perimeter coverage
    local averageGutterCapacityRatio = 0.25 -- ratio of perimeter side length to max surface area covered by a single gutter
    local averageGutterCapacity = averageGutterPerimeterCoverage / averageGutterCapacityRatio -- meters
    -- ex: 6 -> 24 vs 9 -> 36
    return averageGutterCapacity
end

function serviceUtils:getLocalDrainPipes(square)
    -- Grab all nearby squares with a drain pipe object
    local drainPipes = isoUtils:findAllDrainsInRadius(square, 16)
    if not drainPipes or #drainPipes == 0 then
        return nil
    end

    -- Determine if square has a pre-built building or is a player-built structure
    local buildingDef = isoUtils:getAttachedBuilding(square)
    utils:modPrint("Building def: "..tostring(buildingDef))
    if not buildingDef then
       -- No building found - assume player-built structure and return all drain pipes
       return drainPipes
    end

    -- Reduce the list of drain pipes to only those also attached to the same building
    local buildingDrainPipes = table.newarray()
    for i=1, #drainPipes do
        local drainPipe = drainPipes[i]
        local attachedBuildingDef = isoUtils:getAttachedBuilding(drainPipe:getSquare())
        if attachedBuildingDef and attachedBuildingDef:getID() == buildingDef:getID() then
            table.insert(buildingDrainPipes, drainPipe)
        end
    end

    return buildingDrainPipes
end

function serviceUtils:getActualGutterDrainCount(square)
    local drainPipes = self:getLocalDrainPipes(square)
    if not drainPipes then
        return 0
    end

    -- Check 1 z above if ground floor or below if above ground floor as well
    local z =  square:getZ()
    local nextZ = z > 0 and z - 1 or z + 1
    local nextSquare = square:getCell():getGridSquare(square:getX(), square:getY(), nextZ)
    local additionalDrainPipes = self:getLocalDrainPipes(nextSquare)
    if additionalDrainPipes then
        for i=1, #additionalDrainPipes do
            table.insert(drainPipes, additionalDrainPipes[i])
        end
    end

    return #drainPipes
end

function serviceUtils:getEstimatedGutterDrainCount(roofArea, averageGutterCapacity)
    -- Light representation of the gutter system as a whole
    -- Gutters are typically designed to work together as a unit to cover the entire roof (ex: one on each "side" of a roof slant direction or one on each corner)
    -- Here we are estimating the number of gutter drain systems needed relative to the roof's surface area (flat)
    -- Once a single gutter drain's coverage capacity is exceeded by 30% we add another expected gutter drain 'slot'
    -- Since these usually work in pairs we only really care about 1, 2, and 4.
    -- This allows us to set up a single gutter on a small building for full coverage but the same gutter on a larger building might not be 100% as effective
    -- ex: 1 gutter can cover all 40 tiles on a small house but when added to a 'medium' house of 60 tiles the one gutter will only cover 30 tiles since it is expected to have another gutter covering the other side
    if not averageGutterCapacity then
        averageGutterCapacity = self:getAverageGutterCapacity()
    end

    local estimatedGutterCount = roofArea / averageGutterCapacity

    if estimatedGutterCount > 2.6 then
        estimatedGutterCount = 4
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
    if remainingArea >= optimalDrainCount then
        -- Divide the remaining area among each estimated gutter
        local gutterCapacityOverflow = remainingArea / optimalDrainCount
        local maxOverflowArea = averageGutterCapacity / 2
        if gutterCapacityOverflow > maxOverflowArea then
            -- Prevent the overflow capacity from exceeding half of the average gutter capacity
            gutterCapacityOverflow = maxOverflowArea
        end
        utils:modPrint("Gutter overflow capacity: "..tostring(gutterCapacityOverflow))
        -- Overflow 'tile' is only 25% as effective since the system is overloaded
        local gutterOverflowEfficiency = 0.25
        local gutterOverflowTileCount = gutterCapacityOverflow * gutterOverflowEfficiency
        utils:modPrint("Gutter overflow tile count: "..tostring(gutterOverflowTileCount))
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
    local gutterSegment = {
        roofArea = 0,
        tileCount = 0,
        optimalDrainCount = 1,
        drainCount = 1,
        rainFactor = 0.0
    }

    local squareModData = self:syncSquareModData(square, true)
    local roofArea = utils:getModDataRoofArea(square, squareModData)
    if not roofArea then
        utils:modPrint("No roof area found for square: "..tostring(square))
        return gutterSegment
    end

    gutterSegment.roofArea = roofArea

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

-- TODO used?
local function wrapSyncSquareModData(square, full)
    local squareModData = serviceUtils:syncSquareModData(square, full)
    if squareModData == nil then
        return false -- breaks
    end

    return nil -- continues
end

-- TODO used?
function serviceUtils:syncSquareStackModData(square, full)
    local z = isoUtils:applyToSquareStack(square, function(sq) return wrapSyncSquareModData(sq, full) end)
    utils:modPrint("Called syncSquareModData up to level: "..tostring(z))
end

return serviceUtils