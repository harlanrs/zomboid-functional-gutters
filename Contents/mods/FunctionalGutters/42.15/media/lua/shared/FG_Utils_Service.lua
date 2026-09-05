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

    return troughUtils:isTroughObject(object) or self:isFluidContainerObject(object)
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
        -- TODO MULTI - will need to iterate through all connected troughs to find the drain pipe square
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
    -- utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

---@param square IsoGridSquare
---@param player IsoPlayer|nil
function serviceUtils:handlePostCollectorConnected(square, player)
    local _, drainPipe, _, _ = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.drain)
    if not drainPipe then
        return
    end

    local drainModData = drainPipe:getModData()
    if not utils:getModDataDrainCleared(drainPipe, drainModData) then
        -- Roll dice for easter egg & update mod data
        drainModData[enums.modDataKey.drainCleared] = true
        local easterEggRoll = player and localRandom:random(1, 10) or 0
        if easterEggRoll == 10 then
            local adjacentFreeSquare = AdjacentFreeTileFinder.Find(square, player)
            if adjacentFreeSquare then
                local spider = instanceItem("Base.RubberSpider")
                spider:setName("Itsy Betsy")
                adjacentFreeSquare:AddWorldInventoryItem(spider, 0.5, 0.5, 0)
            end
        end

        drainPipe:sync()
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

    return drainPipes
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
    local z = square:getZ()
    for i = 1, zRadius do
        -- Check up zRadius levels
        local upZ = z + i
        local upSquare = square:getCell():getGridSquare(x, y, upZ)
        if upSquare then
            local zDrainPipes = self:getLocalDrainPipes(upSquare, radius)
            if zDrainPipes then
                for iter = 1, #zDrainPipes do
                    table_insert(drainPipes, zDrainPipes[iter])
                end
            end
        end
    end

    if z > 0 then
        -- Check down zRadius levels
        for i = 1, zRadius do
            local downZ = z - i
            if downZ < 0 then
                break
            end
            local downSquare = square:getCell():getGridSquare(x, y, downZ)
            if downSquare then
                local zDrainPipes = self:getLocalDrainPipes(downSquare, radius)
                if zDrainPipes then
                    for iter = 1, #zDrainPipes do
                        table_insert(drainPipes, zDrainPipes[iter])
                    end
                end
            end
        end
    end

    return drainPipes
end

---@param primaryDrainPipe IsoObject
---@param drainPipes table<string, IsoObject>
---@param sourcePipeMap GutterPipeMap
---@param sourceRoofMap GutterRoofMap
---@return table<string, IsoObject> relatedDrains
function serviceUtils:filterGutterDrainsBySharedComponents(primaryDrainPipe, drainPipes, sourcePipeMap, sourceRoofMap)
    -- Filter the list of drain pipes by flood fill
    -- This is a more complex check that will take into account the connectedness of the drain pipes
    -- and their relationship to the primary drain pipe
    local sourceDrainId = primaryDrainPipe:getEntityNetID()

    if not sourcePipeMap then
        sourcePipeMap = isoUtils:crawlGutterPipes(primaryDrainPipe:getSquare())
    end

    local drainPipeMap = {
        [sourceDrainId] = sourcePipeMap
    }

    if not sourceRoofMap then
        sourceRoofMap, _ = isoUtils:getGutterRoofMap(primaryDrainPipe:getSquare(), drainPipeMap[sourceDrainId])
    end

    local drainRoofMap = {
        [sourceDrainId] = sourceRoofMap
    }

    for candidateDrainId, candidateDrain in pairs(drainPipes) do
        local candidateSquare = candidateDrain:getSquare()
        local isSourceDrain = candidateDrainId == sourceDrainId
        if isSourceDrain and sourcePipeMap then
            drainPipeMap[candidateDrainId] = sourcePipeMap
        else
            drainPipeMap[candidateDrainId] = isoUtils:crawlGutterPipes(candidateSquare)
        end

        if isSourceDrain and sourceRoofMap then
            drainRoofMap[candidateDrainId] = sourceRoofMap
        else
            local candidateRoofMap, _ = isoUtils:getGutterRoofMap(candidateSquare, drainPipeMap[candidateDrainId])
            drainRoofMap[candidateDrainId] = candidateRoofMap
        end
    end

    -- Cross-check each drain's pipeMap & roofMap for shared tiles
    local visited = {}
    local relatedDrains = {}
    local queue = { primaryDrainPipe } -- Start with the primary drain pipe
    while #queue > 0 do
        local currentDrain = table.remove(queue, 1)
        local drainId = currentDrain:getEntityNetID()

        -- Skip if already visited
        if not visited[drainId] then
            visited[drainId] = true

            -- Add the current drain to the related drains if it is not the source drain
            if drainId ~= sourceDrainId then
                relatedDrains[drainId] = currentDrain
            end

            -- Get the pipe network for this drain
            local pipeMap = drainPipeMap[drainId]
            local roofMap = drainRoofMap[drainId]

            -- Find all other drains connected through this network
            -- NOTE: implicit self-check since currentDrain already added to visited
            for _, candidateDrain in pairs(drainPipes) do
                local candidateDrainId = candidateDrain:getEntityNetID()
                if not visited[candidateDrainId] then
                    local candidatePipeMap = drainPipeMap[candidateDrainId]
                    local candidateRoofMap = drainRoofMap[candidateDrainId]

                    -- TODO maybe redundant now that we pre-filter siblings from the drainPipes param
                    -- Check for shared pipes
                    local hasSharedPipe = false
                    local candidatePipeSquares = candidatePipeMap.all.squares
                    local sourcePipeSquares = pipeMap.all.squares
                    for candidatePipeSquareId, _ in pairs(candidatePipeSquares) do
                        if sourcePipeSquares[candidatePipeSquareId] then
                            -- Both drain systems share a pipe square
                            hasSharedPipe = true
                            table_insert(queue, candidateDrain)
                            break
                        end
                    end

                    -- Check for shared roof tiles
                    if not hasSharedPipe then
                        for candidateRoofSquareId, _ in pairs(candidateRoofMap.squares) do
                            if roofMap.squares[candidateRoofSquareId] then
                                -- Both drain systems share a roof tile
                                table_insert(queue, candidateDrain)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return relatedDrains
end

---@param sourceDrainSquare IsoGridSquare
---@param sourcePipeMap GutterPipeMap
---@param sourceRoofMap GutterRoofMap
---@return table<string, IsoObject>|nil drainPipes
function serviceUtils:getAssociatedGutterDrains(sourceDrainSquare, sourcePipeMap, sourceRoofMap)
    local _, sourceDrainPipe, _, _ = utils:getSpriteCategoryMemberOnTile(sourceDrainSquare, enums.pipeType.drain)
    if not sourceDrainPipe then
        utils:modPrint("No drain pipe found on square: " .. tostring(sourceDrainSquare))
        return nil
    end

    -- Map drains connected to the primary drain
    -- NOTE: includes the primary drain itself
    local siblingDrainMap = {}
    local siblingDrainSquares = sourcePipeMap[enums.pipeType.drain].squares
    for _, siblingDrainSquare in pairs(siblingDrainSquares) do
        -- Get the drain pipe object on the sibling square
        local _, siblingDrainPipe, _, _ = utils:getSpriteCategoryMemberOnTile(siblingDrainSquare, enums.pipeType.drain)
        if siblingDrainPipe then
            siblingDrainMap[siblingDrainPipe:getEntityNetID()] = siblingDrainPipe
        end
    end

    -- Get all drains in 3d radius
    local localDrainPipes = self:getLocalDrainPipes3D(sourceDrainSquare, enums.defaultDrainPipeSearchRadius,
        enums.defaultDrainPipeSearchHeight)
    if not localDrainPipes then
        return nil
    end

    -- Map local drains that are not siblings
    local neighborDrainMap = {}
    local neighborDrainCount = 0
    for _, localDrainPipe in ipairs(localDrainPipes) do
        local neighborDrainID = localDrainPipe:getEntityNetID()
        if not siblingDrainMap[neighborDrainID] then
            neighborDrainMap[neighborDrainID] = localDrainPipe
            neighborDrainCount = neighborDrainCount + 1
        end
    end

    -- If there are no neighbor drains, return the sibling drains early
    if neighborDrainCount == 0 then
        return siblingDrainMap
    end

    -- Check if neighboring gutter systems collect from overlapping roof tiles
    local associatedDrainMap = self:filterGutterDrainsBySharedComponents(sourceDrainPipe,
        neighborDrainMap, sourcePipeMap, sourceRoofMap)

    -- Combine the sibling drains with the associated neighbor drains
    for drainID, drainPipe in pairs(associatedDrainMap) do
        siblingDrainMap[drainID] = drainPipe
    end

    return siblingDrainMap
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
function serviceUtils:calculateGutterSectionTileCount(roofArea, optimalDrainCount, actualDrainCount,
                                                      averageGutterCapacity)
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

        -- Overflow 'tile' is only 25% as effective since the system is overloaded
        local gutterOverflowTileCount = gutterCapacityOverflow * enums.gutterSectionOverflowEfficiency

        -- Prevent the overflow capacity from exceeding 25% of the average gutter capacity
        local maxOverflowArea = averageGutterCapacity * enums.gutterSectionOverflowEfficiency
        if gutterOverflowTileCount > maxOverflowArea then
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
    local gutterEfficiencyFactor = 1 -- Potentially introduce material tiers in the future (ex: clay vs metal)

    -- The total factor for the specific pipe based on it's own gutter efficiency
    return gutterTileCount * gutterEfficiencyFactor / 10 * roofTileRainFactor
end

---@param square IsoGridSquare
---@return GutterSection|nil gutterSection
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
    ---@type GutterSection
    local gutterSection = {
        roofArea = 0,
        tileCount = 0,
        optimalDrainCount = 1,
        drainCount = 1,
        rainFactor = 0.0,
        pipeMap = nil,
        roofMap = nil,
        buildingType = nil,
        drains = nil,
        maxLevel = 0,
        averageGutterCapacity = 0,
        overflowArea = 0,
        overflowEfficiency = enums.gutterSectionOverflowEfficiency,
    }

    if not utils:isDrainPipeSquare(square) then
        -- Check most likely already occurred in externally but just in case
        -- Drain pipes are essentially the main 'nodes' in a gutter system so have to start from their specific squares
        utils:modPrint("Square is not a drain pipe: " .. tostring(square))
        return nil
    end

    gutterSection.pipeMap = isoUtils:crawlGutterPipes(square)
    gutterSection.roofMap, gutterSection.buildingType = isoUtils:getGutterRoofMap(square, gutterSection.pipeMap)
    gutterSection.roofArea = gutterSection.roofMap.count
    gutterSection.maxLevel = gutterSection.roofMap.maxZ -- TODO if no roof squares, need to handle that case

    gutterSection.drains = self:getAssociatedGutterDrains(square, gutterSection.pipeMap, gutterSection.roofMap)
    gutterSection.drainCount = gutterSection.drains and utils:getDictSize(gutterSection.drains) or
        0 -- NOTE: shouldn't ever be 0 since we already validate drain exists earlier in this function

    gutterSection.averageGutterCapacity = self:getAverageGutterCapacity()
    gutterSection.optimalDrainCount = self:getEstimatedGutterDrainCount(gutterSection.roofArea,
        gutterSection.averageGutterCapacity)
    gutterSection.tileCount, gutterSection.overflowArea = self:calculateGutterSectionTileCount(gutterSection.roofArea,
        gutterSection.optimalDrainCount, gutterSection.drainCount, gutterSection.averageGutterCapacity)
    gutterSection.rainFactor = self:calculateGutterSectionRainFactor(gutterSection.tileCount)

    -- Persist some data on the square for quick checks
    local squareModData = square:getModData()
    squareModData[enums.modDataKey.roofArea] = gutterSection.roofArea
    squareModData[enums.modDataKey.buildingType] = gutterSection.buildingType
    squareModData[enums.modDataKey.maxLevel] = gutterSection.maxLevel

    return gutterSection
end

return serviceUtils
