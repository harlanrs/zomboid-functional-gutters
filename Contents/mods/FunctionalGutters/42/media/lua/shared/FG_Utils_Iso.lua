local enums = require("FG_Enums")
local utils = require("FG_Utils")

local isoUtils = {}

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType
local table_insert = table.insert

---@param square IsoGridSquare
---@param north boolean
---@return integer x, integer y, integer z
function isoUtils:getSquare2Pos(square, north)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    if north then
        x = x - 1
    else
        y = y - 1
    end
    return x, y, z
end

---@param square IsoGridSquare
---@param north boolean
---@return integer x, integer y, integer z
function isoUtils:getSquare2PosReverse(square, north)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    if north then
        x = x + 1
    else
        y = y + 1
    end
    return x, y, z
end

---@param square IsoGridSquare
---@param north boolean
---@return IsoGridSquare
function isoUtils:getSquare2(square, north, reverse)
    local x, y, z
    if reverse then
        x, y, z = self:getSquare2PosReverse(square, north)
    else
        x, y, z = self:getSquare2Pos(square, north)
    end
    return getCell():getGridSquare(x, y, z)
end

---@param square IsoGridSquare
---@return boolean
function isoUtils:isValidRoofSquare(square)
    -- Ensure is not covered by a roof
    if not square:isOutside() then
        return false
    end

    -- Ensure not occupied by a solidTrans or solid object
    -- Ex: don't want to count a square that has a rain catcher already on it
    local isOccupied = square:isSolid() or square:isSolidTrans()
    if isOccupied then
        return false
    end

    return true
end

---@param square IsoGridSquare
---@return boolean|nil
function isoUtils:isValidPlayerBuiltFloor(square)
    -- Ensure has player-built floor
    local hasPlayerBuiltFloor = square:getPlayerBuiltFloor()
    if not hasPlayerBuiltFloor then
        return nil
    end

    return isoUtils:isValidRoofSquare(square)
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasDoorWindowN(square, props)
    if not props then
        props = square:getProperties()
    end
    return props:Is(localIsoFlagType.DoorWallN) or props:Is("WindowN") -- IsoFlagType has "windowN" not "WindowN" which is a bug
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasDoorWindowW(square, props)
    if not props then
        props = square:getProperties()
    end
    return props:Is(localIsoFlagType.DoorWallW) or props:Is("WindowW") -- IsoFlagType has "windowW" not "WindowW" which is a bug
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasWallW(square, props)
    if not props then
        props = square:getProperties()
    end

    if props:Is(localIsoFlagType.WallW) or props:Is(localIsoFlagType.WallNW) or props:Is(localIsoFlagType.WallWTrans) then
        return true
    end

    if self:hasDoorWindowW(square, props) then
        return true
    end

    return false
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasWallN(square, props)
    if not props then
        props = square:getProperties()
    end

    if props:Is(localIsoFlagType.WallN) or props:Is(localIsoFlagType.WallNW) or props:Is(localIsoFlagType.WallNTrans) then
        return true
    end

    if self:hasDoorWindowN(square, props) then
        return true
    end

    return false
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasDoorWindowNW(square, props)
    if not props then
        props = square:getProperties()
    end
    return self:hasDoorWindowN(square, props) or self:hasDoorWindowW(square, props)
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasWallNW(square, props)
    if not props then
        props = square:getProperties()
    end
    if self:hasWallN(square, props) or self:hasWallW(square, props) then
        return true
    end

    return false
end

---@param square IsoGridSquare
---@param directions table<IsoDirections>|nil
---@return IsoBuilding|nil
function isoUtils:getAdjacentBuilding(square, directions)
    if not directions then
        -- South & East tiles are least likely
        directions = table.newarray(
            localIsoDirections.N,
            localIsoDirections.W,
            localIsoDirections.NW,
            localIsoDirections.SW,
            localIsoDirections.NE,
            localIsoDirections.S,
            localIsoDirections.E,
            localIsoDirections.SE
        )
    end

    for i=1, #directions do
        local adjacentSquare = square:getAdjacentSquare(directions[i])
        if adjacentSquare then
            local adjacentBuilding = adjacentSquare:getBuilding()
            if adjacentBuilding then
                return adjacentBuilding
            end
        end
    end

    return nil
end

---@param building IsoBuilding
---@param z integer
---@return integer|nil
function isoUtils:getBuildingRoofRoomID(building, z)
    local buildingDef = building:getDef()
    local roofRoomId = buildingDef:getRoofRoomID(z)
    if roofRoomId < 0 then
        return nil
    end
    return roofRoomId
end

---@param buildingDef BuildingDef
---@param z integer
---@return integer|nil
function isoUtils:getBuildingFloorArea(buildingDef, z)
    local maxZ = buildingDef:getMaxLevel()
    if z == nil then
        z = maxZ
    elseif z > maxZ then
        return nil
    end

    local area = 0
    local buildingDefRooms = buildingDef:getRooms()
    for i=0, buildingDefRooms:size() - 1 do
        local roomDef  = buildingDefRooms:get(i)
        if roomDef:getZ() == z then
            local roomSize = roomDef:getArea()
            -- TODO verify area is completely inside? or just best estimate atm?
            area = area + roomSize
        end
    end

    return area
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap
---@return table<string, IsoGridSquare>|nil
function isoUtils:crawlGutterSquare(square, pipeMap)
    local squareProps = square:getProperties()

    local hasGutterPipe = utils:isGutterPipeSquare(square, squareProps)
    local hasVerticalPipe = utils:isVerticalPipeSquare(square, squareProps)
    local hasDrainPipe = utils:isDrainPipeSquare(square, squareProps)
    -- local hasHorizontalPipe = utils:isHorizontalPipeSquare(square, squareProps) -- NOTE: horizontal pipes don't currently exist beyond gutters

    if not hasGutterPipe and not hasVerticalPipe and not hasDrainPipe then
        return nil
    end

    ---@type table<string, IsoGridSquare>
    local neighborSquares = {}
    local squareID = square:getID()
    local rootCell = square:getCell()
    local rootX, rootY, rootZ = square:getX(), square:getY(), square:getZ()

    if hasDrainPipe then
        -- Record in drain pipe map
        pipeMap[enums.pipeType.drain][squareID] = square

        -- Drain pipes only connect to other pipes above
        local topSquare = rootCell:getGridSquare(rootX, rootY, rootZ + 1)
        if topSquare then
            neighborSquares[topSquare:getID()] = topSquare
        end
    end

    if hasVerticalPipe then
        -- Record in vertical pipe map
        pipeMap[enums.pipeType.vertical][squareID] = square

        -- Vertical pipes only connect to other pipes above and below
        local topSquare = rootCell:getGridSquare(rootX, rootY, rootZ + 1)
        if topSquare then
            neighborSquares[topSquare:getID()] = topSquare
        end

        local bottomSquare = rootCell:getGridSquare(rootX, rootY, rootZ - 1)
        if bottomSquare then
            neighborSquares[bottomSquare:getID()] = bottomSquare
        end
    end

    if hasGutterPipe then
        -- Record in gutter pipe map
        pipeMap[enums.pipeType.gutter][squareID] = square

        -- Gutter pipes connect to other pipes in the same z level 
        -- TODO verify above once we allow gutters to connect/support vertical pipes on next z level
        local northSquare = rootCell:getGridSquare(rootX, rootY - 1, rootZ)
        if northSquare then
            neighborSquares[northSquare:getID()] = northSquare
        end

        local southSquare = rootCell:getGridSquare(rootX, rootY + 1, rootZ)
        if southSquare then
            neighborSquares[southSquare:getID()] = southSquare
        end

        local eastSquare = rootCell:getGridSquare(rootX + 1, rootY, rootZ)
        if eastSquare then
            neighborSquares[eastSquare:getID()] = eastSquare
        end

        local westSquare = rootCell:getGridSquare(rootX - 1, rootY, rootZ)
        if westSquare then
            neighborSquares[westSquare:getID()] = westSquare
        end
    end

    return neighborSquares
end

---@param square IsoGridSquare
---@param roofMap GutterRoofMap
---@param dir IsoDirections|nil
---@param crawlSteps integer|nil
---@return IsoGridSquare|nil
function isoUtils:crawlPlayerBuildingRoofSquare(square, roofMap, dir, crawlSteps)
    if not square then
        utils:modPrint("No square found")
        return nil
    end

    local squareModData = square:getModData()
    local isValidPlayerBuiltFloor = self:isValidPlayerBuiltFloor(square)
    if not isValidPlayerBuiltFloor then
        -- Add/sync the square's mod data
        squareModData[enums.modDataKey.isRoofSquare] = nil
        if isValidPlayerBuiltFloor == nil then
            return nil
        end
    else
        -- Add square to roof map
        roofMap[square:getID()] = square

        -- Add/sync the square's mod data
        squareModData[enums.modDataKey.isRoofSquare] = true
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps >= enums.maxRoofCrawlSteps then
        return square
    end

    -- Crawl to the next square
    local nextSquare
    if dir == IsoDirections.N then
        nextSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
    else
        nextSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
    end
    local crawlNext = self:crawlPlayerBuildingRoofSquare(nextSquare, roofMap, dir, crawlSteps) -- TODO up dir?
    if crawlNext then
        return crawlNext
    end

    -- TODO rethink response now that we check forked paths and won't have a singular final square
    return square
end

---@param startSquare IsoGridSquare
---@return GutterPipeMap gutterPipeMap
function isoUtils:crawlGutterPipes(startSquare)
    ---@type GutterPipeMap
    local gutterPipeMap = {
        [enums.pipeType.drain] = {},
        [enums.pipeType.vertical] = {},
        [enums.pipeType.gutter] = {},
        _all = {}, -- All squares that are part of the gutter system
        _count = 0, -- Total count of squares in the gutter system
        _drain_count = 0, -- Count of drain squares
        _vertical_count = 0, -- Count of vertical squares
        _gutter_count = 0, -- Count of gutter squares
    }
    local crawlSteps = 0
    local visited = {}
    local queue = {startSquare}
    local queued = {[startSquare:getID()] = true} -- Track queued squares to avoid duplicates

    -- NOTE: deep nesting if because no 'continue' in lua 5.2
    while #queue > 0 do
        local square = table.remove(queue, 1) -- Remove from queue list
        if square then
            local squareID = square:getID()
            queued[squareID] = nil -- Remove from queued ref dict
            if not visited[squareID] then
                -- Mark square as visited
                visited[squareID] = true

                -- NOTE: crawl fn returns nil if square doesn't have any pipes
                local nextSquares = self:crawlGutterSquare(square, gutterPipeMap)
                if nextSquares ~= nil then
                    -- Update meta
                    crawlSteps = crawlSteps + 1
                    gutterPipeMap._all[squareID] = square

                    -- Add the next squares to the queue if they haven't been visited yet and don't already exist in the queue
                    for _, nextSquare in pairs(nextSquares) do
                        local nextSquareID = nextSquare:getID()
                        if not visited[nextSquareID] and not queued[nextSquareID] then
                            table_insert(queue, nextSquare)
                        end
                    end
                end
            end
        end

        if crawlSteps > enums.maxGutterCrawlSteps then
            -- Shouldn't hit unless player builds a large system with more gutter objects
            -- adding as failsafe against runaway recursion which also shouldn't occur but just in case
            utils:modPrint("Crawl steps exceeded maximum: "..tostring(enums.maxGutterCrawlSteps))
            break
        end
    end

    -- Calculate metadata now that we have all the squares
    gutterPipeMap._count = utils:getDictSize(gutterPipeMap._all)
    gutterPipeMap._drain_count = utils:getDictSize(gutterPipeMap[enums.pipeType.drain]) ---@diagnostic disable-line:param-type-mismatch
    gutterPipeMap._vertical_count = utils:getDictSize(gutterPipeMap[enums.pipeType.vertical]) ---@diagnostic disable-line:param-type-mismatch
    gutterPipeMap._gutter_count = utils:getDictSize(gutterPipeMap[enums.pipeType.gutter]) ---@diagnostic disable-line:param-type-mismatch

    return gutterPipeMap
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap
---@return boolean
function isoUtils:isSquareInGutterPipeMap(square, pipeMap)
    local squareID = square:getID()

    if pipeMap._all[squareID] then
        return true
    end

    return false
end

---@param pipeMap GutterPipeMap
---@return GutterRoofMap roofMap
function isoUtils:getPlayerBuildingRoofSquares(pipeMap)
    local validRoofSquares = {}

    for _, gutterSquare in pairs(pipeMap[enums.pipeType.gutter]) do
        local _, _, spriteName, _ = utils:getSpriteCategoryMemberOnTile(gutterSquare, enums.pipeType.gutter)
        if not spriteName then
            -- Shouldn't happen but check just in case
            utils:modPrint("No gutter sprite found on square: "..tostring(gutterSquare:getX())..","..tostring(gutterSquare:getY())..","..tostring(gutterSquare:getZ()))
            break
        end

        local spriteDef = enums.pipes[spriteName]
        local squareCrawlSteps = 0
        local fullCornerSprite = spriteDef.position == IsoDirections.NW and spriteDef.roofDirection == IsoDirections.NW
        if spriteDef.position == IsoDirections.N or fullCornerSprite then
            -- Crawl north roof squares
            local attachedRoofX = gutterSquare:getX()
            local attachedRoofY = gutterSquare:getY() - 1
            local attachedRoofSquare = getCell():getGridSquare(attachedRoofX, attachedRoofY, gutterSquare:getZ() + 1)
            self:crawlPlayerBuildingRoofSquare(attachedRoofSquare, validRoofSquares, IsoDirections.N, squareCrawlSteps)
        end

        if spriteDef.position == IsoDirections.W or fullCornerSprite then
            -- Crawl west roof squares
            local attachedRoofX = gutterSquare:getX() - 1
            local attachedRoofY = gutterSquare:getY()
            local attachedRoofSquare = getCell():getGridSquare(attachedRoofX, attachedRoofY, gutterSquare:getZ() + 1)
            self:crawlPlayerBuildingRoofSquare(attachedRoofSquare, validRoofSquares, IsoDirections.W, squareCrawlSteps)
        end
    end

    return validRoofSquares
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap|nil
---@return integer roofArea, GutterRoofMap roofSquares
function isoUtils:getPlayerBuildingRoofArea(square, pipeMap)
    if not pipeMap then
        pipeMap = self:crawlGutterSystem(square)
    end

    local roofSquares = self:getPlayerBuildingRoofSquares(pipeMap)

    local totalArea = 0
    for _, _ in pairs(roofSquares) do
        totalArea = totalArea + 1
    end

    return totalArea, roofSquares
end

---@param square IsoGridSquare
---@return integer topLevel
function isoUtils:findGutterTopLevel(square)
    local cell = square:getCell()
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    -- Check 5 max; maybe increase if needed
    for i=1, 4 do
        local nextFloor = z + 1
        local nextSquare = cell:getGridSquare(x, y, nextFloor)
        if not nextSquare then
            utils:modPrint("Next square level not found: "..tostring(nextFloor))
            break
        elseif not utils:isVerticalPipeSquare(nextSquare) then
            break
        end

        z = nextFloor
    end

    return z
end

---@param square IsoGridSquare
---@return IsoBuilding|nil
function isoUtils:getAttachedBuilding(square)
    -- Check square directly
    local squareBuilding = square:getBuilding()
    if squareBuilding then
        return squareBuilding
    end

    -- Check adjacent squares
    return self:getAdjacentBuilding(square)
end

---@param pipeMap GutterPipeMap
---@return integer topLevel
function isoUtils:getGutterTopLevel(pipeMap)
    local topLevel = 0

    for _, pipeSquare in pairs(pipeMap._all) do
        local squareZ = pipeSquare:getZ()
        if squareZ > topLevel then
            topLevel = squareZ
        end
    end

    return topLevel
end

---@param pipeMap GutterPipeMap
---@param roofZ integer
---@return table<string, IsoGridSquare> roofSeedSquares
function isoUtils:findGutterRoofSeedSquares(pipeMap, roofZ)
    -- Find all 'neighbor' squares for pipes that collect from roofZ level
    -- NOTE: roofZ is the level above the gutter z level
    local roofSeedSquares = {}

    local neighborDirections = {
        localIsoDirections.N,
        localIsoDirections.S,
        localIsoDirections.E,
        localIsoDirections.W,
        localIsoDirections.NE,
        localIsoDirections.NW
    }

    for _, pipeSquare in pairs(pipeMap._all) do
        if pipeSquare:getZ() + 1 == roofZ then
            -- Check if the square is valid for starting the flood fill
            local aboveSquare = getCell():getGridSquare(pipeSquare:getX(), pipeSquare:getY(), roofZ)
            if aboveSquare then
                for _, direction in ipairs(neighborDirections) do
                    local neighborSquare = aboveSquare:getAdjacentSquare(direction)
                    if neighborSquare then
                        roofSeedSquares[neighborSquare:getID()] = neighborSquare
                    end
                end
            end
        end
    end

    return roofSeedSquares
end

---@param square IsoGridSquare
---@return table<IsoGridSquare>
function isoUtils:findRoofNeighborSquares(square)
    -- Find all neighbors of the square at the specified roof level
    local roofNeighborSquares = {}
    local neighborDirections = {
        localIsoDirections.N,
        localIsoDirections.S,
        localIsoDirections.E,
        localIsoDirections.W,
    }

    for _, direction in ipairs(neighborDirections) do
        local neighborSquare = square:getAdjacentSquare(direction)
        if neighborSquare then
            table_insert(roofNeighborSquares, neighborSquare)
        end
    end

    return roofNeighborSquares
end

---@param square IsoGridSquare
---@param buildingDefId integer
---@return boolean
function isoUtils:isValidVanillaRoofSquare(square, buildingDefId)
    -- Verify square is 'associated' with the building
    -- Roof squares are not in the bounds of the IsoBuilding but will still be associated with it from a meta grid perspective
    -- Additionally, building bounds might intersect or overlap so we need to ensure roofs from other buildings are not included
    if not square then
        return false
    end

    local squareX = square:getX()
    local squareY = square:getY()
    local squareZ = square:getZ()
    local metaGrid = getWorld():getMetaGrid()
    local associatedBuilding = metaGrid:getAssociatedBuildingAt(squareX, squareY)
    if associatedBuilding and associatedBuilding:getID() == buildingDefId then
        -- Check if the square is valid to be considered a roof square
        if self:isValidRoofSquare(square) then
            -- If the square doesn't have a floor, it might still be a valid roof but requires additional checks
            if not square:getFloor() then
                -- Verify the square is associated with a room on the min z level of the building (generally the 'ground' floor has the largest area of rooms)
                -- TODO check if this is the best way to determine if a square is part of a room as there are some holes
                -- maybe just check the square directly below for being inside or outside? if outside then ignore it
                local downSquare = getCell():getGridSquare(squareX, squareY, squareZ - 1)
                if downSquare and not downSquare:isOutside() then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap|nil
---@param building IsoBuilding
---@return integer roofArea, GutterRoofMap roofSquares
function isoUtils:getVanillaBuildingRoofAreaFloodFill(square, pipeMap, building)
    if not pipeMap then
        pipeMap = self:crawlGutterPipes(square)
    end

    local topGutterFloor = self:getGutterTopLevel(pipeMap)
    local buildingDef = building:getDef()
    local buildingDefId = buildingDef:getID()
    local maxZ = buildingDef:getMaxLevel()
    local roofZ = topGutterFloor > maxZ and maxZ + 1 or topGutterFloor + 1

    -- Initialize flood fill
    local roofSquares = {}
    local visited = {}
    local queue = {}
    local queued = {}
    local roofArea = 0

    -- Find starting point(s) around the roof-level pipes
    local seedSquares = self:findGutterRoofSeedSquares(pipeMap, roofZ)
    for seedSquareID, seedSquare in pairs(seedSquares) do
        table.insert(queue, seedSquare)
        queued[seedSquareID] = true
    end

    -- Flood fill to find connected roof area
    while #queue > 0 do
        local queuedSquare = table.remove(queue, 1)
        local queuedSquareId = queuedSquare:getID()

        if not visited[queuedSquareId] then
            visited[queuedSquareId] = true
            queued[queuedSquareId] = nil -- Remove from queued ref dict

            -- Validate square belongs to building and is valid roof
            if self:isValidVanillaRoofSquare(queuedSquare, buildingDefId) then
                roofArea = roofArea + 1
                roofSquares[queuedSquareId] = queuedSquare

                -- Add neighbors to queue
                local neighbors = self:findRoofNeighborSquares(queuedSquare)
                for _, neighbor in ipairs(neighbors) do
                    local neighborSquareId = neighbor:getID()
                    if not visited[neighborSquareId] and not queued[neighborSquareId] then
                        table_insert(queue, neighbor)
                        queued[neighborSquareId] = true
                    end
                end
            end
        end

        -- Safety limit to stop on huge roofs
        if roofArea > enums.maxRoofArea then
            utils:modPrint("Roof flood fill exceeded maximum area")
            break
        end
    end

    return roofArea, roofSquares
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap
---@return integer roofArea, GutterRoofMap roofSquares, BuildingType buildingType
function isoUtils:getGutterRoofArea(square, pipeMap)
    local building = self:getAttachedBuilding(square)
    local roofArea, roofSquares, buildingType
    if building then
        -- Vanilla building mode
        buildingType = enums.buildingType.vanilla
        roofArea, roofSquares = self:getVanillaBuildingRoofAreaFloodFill(square, pipeMap, building)
    else
        -- Custom building mode
        buildingType = enums.buildingType.custom
        roofArea, roofSquares = self:getPlayerBuildingRoofArea(square, pipeMap)
    end

    return roofArea, roofSquares, buildingType
end

---@param square IsoGridSquare
---@param radius integer
---@param pipeType PipeType
---@return IsoObject|nil
function isoUtils:findPipeInRadius(square, radius, pipeType)
    local sx,sy,sz = square:getX(), square:getY(), square:getZ();
    for x = sx-radius,sx+radius do
        for y = sy-radius,sy+radius do
            local sq = getCell():getGridSquare(x,y,sz);
            if sq then
                local _, pipeObject, _, _ = utils:getSpriteCategoryMemberOnTile(sq, pipeType)
                if pipeObject then
                    return pipeObject
                end
            end
        end
    end

    return nil
end

---@param square IsoGridSquare
---@param radius integer
---@return table<IsoObject>
function isoUtils:findAllDrainsInRadius(square, radius)
    local pipeObjects = table.newarray()
    local sx,sy,sz = square:getX(), square:getY(), square:getZ();
    for x = sx-radius,sx+radius do
        for y = sy-radius,sy+radius do
            local sq = getCell():getGridSquare(x,y,sz);
            if sq and utils:isDrainPipeSquare(sq) then
                local _, pipeObject, _, _ = utils:getSpriteCategoryMemberOnTile(sq, enums.pipeType.drain)
                if pipeObject then
                    table_insert(pipeObjects, pipeObject)
                end
            end
        end
    end

    return pipeObjects
end

return isoUtils