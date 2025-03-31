local enums = require("FG_Enums")
local utils = require("FG_Utils")
local options = require("FG_Options")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

local table_insert = table.insert
local localRandom = newrandom()

local serviceUtils = {}

---@param object IsoObject
---@return boolean
function serviceUtils:isWorldInventoryObject(object)
    return instanceof(object, "IsoWorldInventoryObject")
end

---@param object IsoObject
---@return boolean
function serviceUtils:isFluidContainerObject(object)
    return instanceof(object, "IsoObject") and object:getFluidContainer() ~= nil
end

---@param object IsoObject
---@return boolean
function serviceUtils:isValidCollectorObject(object)
    if self:isWorldInventoryObject(object) then
        return false
    end

    return troughUtils:isTrough(object) or self:isFluidContainerObject(object)
end

---@param object IsoObject
---@return IsoObject|nil primaryCollector
function serviceUtils:getPrimaryCollector(object)
    -- Finds the 'primary' fluid container object for multi-tile objects
    -- primarily for trough objects atm but could be expanded to other multi-tile objects
    if not object then
        return nil
    end

    if self:isWorldInventoryObject(object) then
        return nil
    end

    if troughUtils:isTrough(object) then
        local primaryTrough = troughUtils:getPrimaryTrough(object)
        if primaryTrough then
            return primaryTrough
        end
    end

    if self:isFluidContainerObject(object) then
        return object
    end

    return nil
end

---@param square IsoGridSquare
---@return IsoObject|nil connectedCollector
function serviceUtils:getConnectedCollectorFromSquare(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local collectorObject = self:getPrimaryCollector(object)
        if collectorObject and utils:getModDataIsGutterConnected(collectorObject) then
            -- Usually object & collectorObject are the same but for cases where multi-tile trough's secondary object is on the drain pipe square 
            -- we want to return the object that is considered 'primary' for interacting with the proper fluid container
            return collectorObject
        end
    end
    return nil
end

---@param collectorObject IsoObject 
---@return IsoGridSquare|nil drainSquare
function serviceUtils:getDrainPipeSquareFromCollector(collectorObject)
    local square = collectorObject:getSquare()
    if not square then
        return nil
    end

    if utils:isDrainPipeSquare(square) then
        return square
    end

    if troughUtils:isTrough(collectorObject) then
        -- Check if the other trough object is located on a square with a drain pipe
        local otherTroughObject = troughUtils:getOtherTroughObject(collectorObject)
        if not otherTroughObject then
            return nil
        end

        local otherSquare = otherTroughObject:getSquare()
        if not otherSquare then
            return nil
        end

        if utils:isDrainPipeSquare(otherSquare) then
            return otherSquare
        end
    end

    return nil
end

---@param object IsoObject
---@return number
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

---@param square IsoGridSquare
function serviceUtils:handlePostCollectorConnected(square)
    local _, drainPipe, _, _ = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.drain)
    if not drainPipe then
        return
    end

    local drainModData = drainPipe:getModData()
    if not utils:getModDataDrainCleared(drainPipe, drainModData) then
        -- Roll dice for easter egg & update mod data
        drainModData[enums.modDataKey.drainCleared] = true
        local easterEggRoll = localRandom:random(1, 10)
        if easterEggRoll == 10 then
            local adjacentFreeSquare = AdjacentFreeTileFinder.Find(square, getPlayer())
            if adjacentFreeSquare then
                local spider = adjacentFreeSquare:AddWorldInventoryItem("Base.RubberSpider", 0.5, 0.5, 0)
                spider:setName("Itsy Betsy")
            end
        end
    end
end

---@param square IsoGridSquare
---@param squareModData table|nil
---@return table squareModData
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

---@return integer averageGutterCapacity
function serviceUtils:getAverageGutterCapacity()
    -- Meters of roof's perimeter covered effectively by a single gutter drain for a standard house
    -- Realistically this is between 6 and 9 meters
    local averageGutterPerimeterCoverage = enums.gutterSectionPerimeterLength

    -- Ratio of perimeter side length to max surface area covered by a single gutter
    local averageGutterCapacityRatio = enums.gutterSectionCapacityRatio

    -- Meters of roof's area covered effectively by a single gutter for a standard house
    -- Don't want to simply take the square of the perimeter coverage as this wouldn't be very accurate for a real roof and would over-emphasize the gutter perimeter value
    -- ex: 6 -> 36 vs 9 -> 81 (exponential)
    -- Instead aiming for a ratio that produces a reasonable 'rectangle' of tiles covered relative to the perimeter coverage
    -- ex: 6 -> 24 vs 9 -> 36 (linear)
    return averageGutterPerimeterCoverage / averageGutterCapacityRatio
end

---@param square IsoGridSquare
---@param radius integer|nil
---@return table<IsoObject>|nil drainPipes
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
    local squareBuilding = isoUtils:getAttachedBuilding(square)

    local maxLevel = utils:getModDataMaxLevel(square)

    -- Reduce the list of drain pipes to only those relevant to the building mode
    local associatedDrainPipes = table.newarray()
    for i=1, #drainPipes do
        local drainPipe = drainPipes[i]
        local drainBuilding = isoUtils:getAttachedBuilding(drainPipe:getSquare())
        if squareBuilding then
            -- Vanilla building mode
            -- Check if the drain pipe is attached to the same building
            if drainBuilding and drainBuilding:getID() == squareBuilding:getID() then
                -- Check if drains on the same building are getting water from the same level
                if maxLevel then
                    local drainPipeSquare = drainPipe:getSquare()
                    local pipeMaxLevel = utils:getModDataMaxLevel(drainPipeSquare)
                    if pipeMaxLevel then
                        if pipeMaxLevel == maxLevel then
                            -- Add the drain pipe to the list of associated pipes
                            table_insert(associatedDrainPipes, drainPipe)
                        end
                    else
                        -- If the drain pipe doesn't have a max level, go ahead an add it to the list of associated pipes
                        -- Would rather over estimate than under estimate
                        table_insert(associatedDrainPipes, drainPipe)
                    end
                else
                    -- If for some reason the maxLevel is nil, go ahead an add it to the list of associated pipes
                    -- Would rather over estimate than under estimate
                    table_insert(associatedDrainPipes, drainPipe)
                end
            end
        else
            -- Custom building mode
            -- Check if the drain is not attached to any building
            if not drainBuilding then
                table_insert(associatedDrainPipes, drainPipe)
            end
        end
    end

    return associatedDrainPipes
end

---@param square IsoGridSquare
---@param radius integer|nil
---@param zRadius integer|nil
---@return table<IsoObject>|nil drainPipes
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

---@param square IsoGridSquare
---@return integer drainCount
function serviceUtils:getActualGutterDrainCount(square)
    local drainPipes = self:getLocalDrainPipes3D(square, enums.defaultDrainPipeSearchRadius, enums.defaultDrainPipeSearchHeight)
    if not drainPipes then
        return 0
    end

    return #drainPipes
end

---@param roofArea integer
---@param averageGutterCapacity integer|nil
---@return integer optimalDrainCount
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

---@param roofArea integer
---@param optimalDrainCount integer
---@param actualDrainCount integer
---@param averageGutterCapacity integer|nil
---@return number gutterTileCount, number overflowArea
function serviceUtils:calculateGutterSectionTileCount(roofArea, optimalDrainCount, actualDrainCount, averageGutterCapacity)
    -- Divides up the area of the roof into sections for each estimated gutter drain and calculates the effective tiles covered by each section
    -- Ex: 70 tile roof with 2 gutter capacity would have 35 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Ex: 110 tile roof with 4 estimated gutters would have 27.5 tiles covered by each gutter despite a single gutter being able to cover up to 40 tiles
    -- Additionally since we stop at 4 gutter capacity, any leftover area is divided up among the estimated gutter capacity but at a highly reduced efficiency
    -- Ex: 180 tile roof with 4 estimated gutters would have 40 tiles covered by each gutter and 5 "overflow" tiles covered by each gutter at 25% efficiency
    if not averageGutterCapacity then
        averageGutterCapacity = self:getAverageGutterCapacity()
    end

    local gutterTileCount = roofArea / optimalDrainCount
    local overflowArea = gutterTileCount - averageGutterCapacity
    if overflowArea >= 1 then
        -- Set the gutter tile count to the average (max) capacity and calculate remainder as overflow
        gutterTileCount = averageGutterCapacity
        local gutterCapacityOverflow = overflowArea
        utils:modPrint("Gutter overflow capacity: "..tostring(gutterCapacityOverflow))

        -- Overflow 'tile' is only 25% as effective since the system is overloaded
        local gutterOverflowTileCount = gutterCapacityOverflow * enums.gutterSectionOverflowEfficiency
        utils:modPrint("Gutter overflow tile count: "..tostring(gutterOverflowTileCount))

        -- Prevent the overflow capacity from exceeding 25% of the average gutter capacity
        local maxOverflowArea = averageGutterCapacity * enums.gutterSectionOverflowEfficiency
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

    return gutterTileCount, overflowArea
end

---@param gutterTileCount integer
---@return number gutterRainFactor
function serviceUtils:calculateGutterSectionRainFactor(gutterTileCount)
    -- Aim for this value to be 1.0 with mod options between 0.0 and 2.0
    local roofTileRainFactor = options:getRoofRainFactor()
    local gutterEfficiencyFactor = 1
    -- TODO each gutter pipe can has its own factor based on 'quality' up to 95% efficiency
    -- TODO should take an average of quality across all connected gutter pipes

    -- The total factor for the specific pipe based on it's own gutter efficiency
    return gutterTileCount * gutterEfficiencyFactor / 10 * roofTileRainFactor
end

---@param square IsoGridSquare
---@return table|nil gutterSection
function serviceUtils:calculateGutterSection(square)
    -- Notes:
    -- 1 tile is 1 meter squared
    -- 1 millimeter (mm) of rain means 1 liter of water falling on every square meter of area

    -- Drizzle: Less than 2 mm/hr 
    -- Light Rain: 2-4 mm/hr 
    -- Moderate Rain: 4-7.6 mm/hr 
    -- Heavy Rain: Greater than 7.6 mm/hr 

    -- Unadjusted that means for 1 tile: 
    -- 1-2 liters of water per hour for a slight drizzle
    -- 2-4 liters of water per hour for light rain
    -- 4-7.6 liters of water per hour for moderate rain
    -- 7.6+ liters of water per hour for heavy rain

    -- Rain intensity is already factored into base game systems so we need to balance the generated rain factor to be useful but not trivial or too powerful
    -- Realistically a roof gutter system would produce nearly an entire rain barrel's worth of water (600l) in just a few hours when considering the area of the roof
    local gutterSection = {
        roofArea = 0,
        tileCount = 0,
        optimalDrainCount = 1,
        drainCount = 1,
        rainFactor = 0.0,
        pipeMap = nil,
        roofMap = nil,
        buildingType = nil,
        maxLevel = nil,
        averageGutterCapacity = 0,
        overflowArea = 0,
        overflowEfficiency = enums.gutterSectionOverflowEfficiency,
    }

    if not utils:isDrainPipeSquare(square) then
        -- Check most likely already occurred in externally but just in case
        -- Drain pipes are essentially the main 'nodes' in a gutter system so have to start from their specific squares
        utils:modPrint("Square is not a drain pipe: "..tostring(square))
        return nil
    end

    gutterSection.pipeMap = isoUtils:crawlGutterSystem(square)
    local roofArea, roofMap, buildingType = isoUtils:getGutterRoofArea(square, gutterSection.pipeMap)
    if not roofArea then
        utils:modPrint("No roof area found for square: "..tostring(square))
        return gutterSection
    end

    gutterSection.roofArea = roofArea
    gutterSection.roofMap = roofMap
    gutterSection.buildingType = buildingType
    gutterSection.maxLevel = isoUtils:getGutterTopLevel(gutterSection.pipeMap) + 1

    -- Persist some data on the square for quick checks
    local squareModData = square:getModData()
    squareModData[enums.modDataKey.roofArea] = gutterSection.roofArea
    squareModData[enums.modDataKey.buildingType] = gutterSection.buildingType
    squareModData[enums.modDataKey.maxLevel] = gutterSection.maxLevel

    gutterSection.averageGutterCapacity = self:getAverageGutterCapacity()
    gutterSection.optimalDrainCount = self:getEstimatedGutterDrainCount(gutterSection.roofArea, gutterSection.averageGutterCapacity)
    gutterSection.drainCount = self:getActualGutterDrainCount(square)
    gutterSection.tileCount, gutterSection.overflowArea = self:calculateGutterSectionTileCount(gutterSection.roofArea, gutterSection.optimalDrainCount, gutterSection.drainCount, gutterSection.averageGutterCapacity)
    gutterSection.rainFactor = self:calculateGutterSectionRainFactor(gutterSection.tileCount)

    utils:modPrint("Roof area: "..tostring(gutterSection.roofArea))
    utils:modPrint("Optimal drain count: "..tostring(gutterSection.optimalDrainCount))
    utils:modPrint("Actual drain count: "..tostring(gutterSection.drainCount))
    utils:modPrint("Section tile count: "..tostring(gutterSection.tileCount))
    utils:modPrint("Section rain factor: "..tostring(gutterSection.rainFactor))
    return gutterSection
end

return serviceUtils