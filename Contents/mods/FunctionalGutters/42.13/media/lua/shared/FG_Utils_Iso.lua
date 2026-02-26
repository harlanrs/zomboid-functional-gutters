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

    -- IsoFlagType has "windowN" not "WindowN" which is a bug
    return props:has(localIsoFlagType.DoorWallN) or props:has("WindowN")
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasDoorWindowW(square, props)
    if not props then
        props = square:getProperties()
    end

    -- IsoFlagType has "windowW" not "WindowW" which is a bug
    return props:has(localIsoFlagType.DoorWallW) or props:has("WindowW")
end

---@param square IsoGridSquare
---@param props PropertyContainer|nil
---@return boolean
function isoUtils:hasWallW(square, props)
    if not props then
        props = square:getProperties()
    end

    if props:has(localIsoFlagType.WallW) or props:has(localIsoFlagType.WallNW) or props:has(localIsoFlagType.WallWTrans) then
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

    if props:has(localIsoFlagType.WallN) or props:has(localIsoFlagType.WallNW) or props:has(localIsoFlagType.WallNTrans) then
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
---@return boolean
function isoUtils:hasPole(square)
    local squareObjects = square:getObjects()
    for i = 0, squareObjects:size() - 1 do
        local object = squareObjects:get(i)
        if utils:isAnyPole(object) then
            return true
        end
    end
    return false
end

---Checks if a square has a valid wall or pole attachment point for pipes
---Checks current square, adjacent N, W, NW, E, and S squares for walls/poles
---@param square IsoGridSquare
---@return boolean
function isoUtils:hasValidPipeAttachment(square)
    -- Check current square for walls NW or pole
    if self:hasWallNW(square) or self:hasPole(square) then
        return true
    end

    -- Check if the square to the north exists and has a wall on the west or pole
    local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
    if not adjacentSquareN then
        return false
    end
    if self:hasWallW(adjacentSquareN) or self:hasPole(adjacentSquareN) then
        return true
    end

    -- Check if the square to the west exists and has a wall on the north or pole
    local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
    if not adjacentSquareW then
        return false
    end
    if self:hasWallN(adjacentSquareW) or self:hasPole(adjacentSquareW) then
        return true
    end

    -- Check adjacent north-west square for pole
    local adjacentSquareNW = square:getAdjacentSquare(localIsoDirections.NW)
    if adjacentSquareNW and self:hasPole(adjacentSquareNW) then
        return true
    end

    -- Check if the square to the east has a pole (covers NE corner)
    local adjacentSquareE = square:getAdjacentSquare(localIsoDirections.E)
    if adjacentSquareE and self:hasPole(adjacentSquareE) then
        return true
    end

    -- Check if the square to the south has a pole (covers SW corner)
    local adjacentSquareS = square:getAdjacentSquare(localIsoDirections.S)
    if adjacentSquareS and self:hasPole(adjacentSquareS) then
        return true
    end

    return false
end

---Checks if a square has a valid floor attachment point above adjacent N or W squares
---Used for gutter pipes which can attach to the underside of floors/roofs
---@param square IsoGridSquare
---@return boolean
function isoUtils:hasValidFloorAttachment(square)
    -- Check for floor on the square above adjacent N
    local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
    if adjacentSquareN then
        local adjacentSquareNUp = getCell():getGridSquare(
            adjacentSquareN:getX(), adjacentSquareN:getY(), adjacentSquareN:getZ() + 1)
        if adjacentSquareNUp and adjacentSquareNUp:hasFloor() then
            return true
        end
    end

    -- Check for floor on the square above adjacent W
    local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
    if adjacentSquareW then
        local adjacentSquareWUp = getCell():getGridSquare(
            adjacentSquareW:getX(), adjacentSquareW:getY(), adjacentSquareW:getZ() + 1)
        if adjacentSquareWUp and adjacentSquareWUp:hasFloor() then
            return true
        end
    end

    return false
end

---@param square IsoGridSquare
---@param directions table<IsoDirections>|nil
---@param metaGrid MetaGrid|nil
---@return BuildingDef|nil
function isoUtils:getAdjacentBuilding(square, directions, metaGrid)
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

    if not metaGrid then
        metaGrid = getWorld():getMetaGrid()
    end

    local adjacentBuildingDef = nil
    for i = 1, #directions do
        local adjacentSquare = square:getAdjacentSquare(directions[i])
        if adjacentSquare then
            adjacentBuildingDef = metaGrid:getAssociatedBuildingAt(adjacentSquare:getX(), adjacentSquare:getY())
            if adjacentBuildingDef then
                break
            end
        end
    end

    return adjacentBuildingDef
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
    for i = 0, buildingDefRooms:size() - 1 do
        local roomDef = buildingDefRooms:get(i)
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
        local drainMap = pipeMap[enums.pipeType.drain]
        if not drainMap.squares[squareID] then
            drainMap.squares[squareID] = square
            drainMap.count = drainMap.count + 1

            if rootZ > drainMap.maxZ then
                drainMap.maxZ = rootZ
            end
        end

        -- Drain pipes only connect to other pipes above
        local topSquare = rootCell:getGridSquare(rootX, rootY, rootZ + 1)
        if topSquare then
            neighborSquares[topSquare:getID()] = topSquare
        end
    end

    if hasVerticalPipe then
        -- Record in vertical pipe map
        local verticalMap = pipeMap[enums.pipeType.vertical]
        if not verticalMap.squares[squareID] then
            verticalMap.squares[squareID] = square
            verticalMap.count = verticalMap.count + 1

            if rootZ > verticalMap.maxZ then
                verticalMap.maxZ = rootZ
            end
        end

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
        local gutterMap = pipeMap[enums.pipeType.gutter]
        if not gutterMap.squares[squareID] then
            gutterMap.squares[squareID] = square
            gutterMap.count = gutterMap.count + 1

            if rootZ > gutterMap.maxZ then
                gutterMap.maxZ = rootZ
            end
        end

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

    if not pipeMap.all.squares[squareID] then
        -- Add square to all squares map
        pipeMap.all.squares[squareID] = square
        pipeMap.all.count = pipeMap.all.count + 1

        if rootZ > pipeMap.all.maxZ then
            pipeMap.all.maxZ = rootZ
        end
    end

    return neighborSquares
end

---@param square IsoGridSquare
---@param roofMap GutterRoofMap
---@param dir IsoDirections|nil
---@param crawlSteps integer|nil
---@return IsoGridSquare|nil
function isoUtils:crawlCustomBuildingRoofSquare(square, roofMap, dir, crawlSteps)
    if not square then
        utils:modPrint("No square found")
        return nil
    end

    local squareZ = square:getZ()
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
        local squareID = square:getID()
        if not roofMap.squares[squareID] then
            roofMap.squares[squareID] = square
            roofMap.count = roofMap.count + 1

            if squareZ > roofMap.maxZ then
                roofMap.maxZ = squareZ
            end
        end

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
        nextSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, squareZ)
    else
        nextSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), squareZ)
    end
    local crawlNext = self:crawlCustomBuildingRoofSquare(nextSquare, roofMap, dir, crawlSteps) -- TODO up dir?
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
        [enums.pipeType.drain] = {
            squares = {},
            count = 0,
            maxZ = 0
        },
        [enums.pipeType.vertical] = {
            squares = {},
            count = 0,
            maxZ = 0
        },
        [enums.pipeType.gutter] = {
            squares = {},
            count = 0,
            maxZ = 0
        },
        all = {
            squares = {},
            count = 0,
            maxZ = 0
        },
    }
    local crawlSteps = 0
    local visited = {}
    local queue = { startSquare }
    local queued = { [startSquare:getID()] = true } -- Track queued squares to avoid duplicates

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
            utils:modPrint("Crawl steps exceeded maximum: " .. tostring(enums.maxGutterCrawlSteps))
            break
        end
    end

    return gutterPipeMap
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap
---@return boolean
function isoUtils:isSquareInGutterPipeMap(square, pipeMap)
    local squareID = square:getID()

    if pipeMap.all.squares[squareID] then
        return true
    end

    return false
end

---@param pipeMap GutterPipeMap
---@return GutterRoofMap roofMap
function isoUtils:crawlCustomBuildingRoof(pipeMap)
    ---@type GutterRoofMap
    local roofMap = {
        squares = {},
        count = 0,
        maxZ = 0
    }

    local gutterMap = pipeMap[enums.pipeType.gutter]
    for _, gutterSquare in pairs(gutterMap.squares) do
        local _, _, spriteName, _ = utils:getSpriteCategoryMemberOnTile(gutterSquare, enums.pipeType.gutter)
        if not spriteName then
            -- Shouldn't happen but check just in case
            utils:modPrint("No gutter sprite found on square: " ..
                tostring(gutterSquare:getX()) ..
                "," .. tostring(gutterSquare:getY()) .. "," .. tostring(gutterSquare:getZ()))
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
            self:crawlCustomBuildingRoofSquare(attachedRoofSquare, roofMap, IsoDirections.N, squareCrawlSteps)
        end

        if spriteDef.position == IsoDirections.W or fullCornerSprite then
            -- Crawl west roof squares
            local attachedRoofX = gutterSquare:getX() - 1
            local attachedRoofY = gutterSquare:getY()
            local attachedRoofSquare = getCell():getGridSquare(attachedRoofX, attachedRoofY, gutterSquare:getZ() + 1)
            self:crawlCustomBuildingRoofSquare(attachedRoofSquare, roofMap, IsoDirections.W, squareCrawlSteps)
        end
    end

    return roofMap
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap|nil
---@return GutterRoofMap roofMap
function isoUtils:getCustomBuildingRoofMap(square, pipeMap)
    if not pipeMap then
        pipeMap = self:crawlGutterPipes(square)
    end

    return self:crawlCustomBuildingRoof(pipeMap)
end

---@param square IsoGridSquare
---@return integer topLevel
function isoUtils:findGutterTopLevel(square)
    local cell = square:getCell()
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    -- Check 5 max; maybe increase if needed
    for i = 1, 4 do
        local nextFloor = z + 1
        local nextSquare = cell:getGridSquare(x, y, nextFloor)
        if not nextSquare then
            utils:modPrint("Next square level not found: " .. tostring(nextFloor))
            break
        elseif not utils:isVerticalPipeSquare(nextSquare) then
            break
        end

        z = nextFloor
    end

    return z
end

---@param square IsoGridSquare
---@return BuildingDef|nil
function isoUtils:getAttachedBuilding(square)
    -- Check square directly
    local metaGrid = getWorld():getMetaGrid()
    local squareBuilding = metaGrid:getAssociatedBuildingAt(square:getX(), square:getY())
    -- local squareBuilding = square:getBuilding()
    if squareBuilding then
        return squareBuilding
    end

    -- Check adjacent squares
    local adjacentBuilding = self:getAdjacentBuilding(square, nil, metaGrid)
    return adjacentBuilding
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

    for _, pipeSquare in pairs(pipeMap.all.squares) do
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
---@param buildingDef BuildingDef
---@return GutterRoofMap roofMap
function isoUtils:getVanillaBuildingRoofMap(square, pipeMap, buildingDef)
    if not pipeMap then
        pipeMap = self:crawlGutterPipes(square)
    end

    local topGutterFloor = pipeMap.all.maxZ
    local buildingDefId = buildingDef:getID()
    local maxZ = buildingDef:getMaxLevel()
    local roofZ = topGutterFloor > maxZ and maxZ + 1 or topGutterFloor + 1

    -- Initialize flood fill
    ---@type GutterRoofMap
    local roofMap = {
        squares = {},
        count = 0,
        maxZ = roofZ
    }
    local visited = {}
    local queue = {}
    local queued = {}

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
                roofMap.squares[queuedSquareId] = queuedSquare
                roofMap.count = roofMap.count + 1

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
        if roofMap.count > enums.maxRoofArea then
            utils:modPrint("Roof flood fill exceeded maximum area")
            break
        end
    end

    return roofMap
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap
---@return GutterRoofMap roofMap, BuildingType buildingType
function isoUtils:getGutterRoofMap(square, pipeMap)
    local buildingDef = self:getAttachedBuilding(square)
    local roofMap, buildingType
    if buildingDef then
        -- Vanilla building mode
        buildingType = enums.buildingType.vanilla
        roofMap = self:getVanillaBuildingRoofMap(square, pipeMap, buildingDef)
    else
        -- Custom building mode
        buildingType = enums.buildingType.custom
        roofMap = self:getCustomBuildingRoofMap(square, pipeMap)
    end

    utils:modPrint("Getting roof map for building: " .. tostring(buildingType) .. " on square: " ..
        tostring(square:getX()) .. ", " .. tostring(square:getY()) .. ", " .. tostring(square:getZ()))

    return roofMap, buildingType
end

---@param square IsoGridSquare
---@param radius integer
---@param pipeType PipeType
---@return IsoObject|nil
function isoUtils:findPipeInRadius(square, radius, pipeType)
    local sx, sy, sz = square:getX(), square:getY(), square:getZ();
    for x = sx - radius, sx + radius do
        for y = sy - radius, sy + radius do
            local sq = getCell():getGridSquare(x, y, sz);
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
    local sx, sy, sz = square:getX(), square:getY(), square:getZ();
    for x = sx - radius, sx + radius do
        for y = sy - radius, sy + radius do
            local sq = getCell():getGridSquare(x, y, sz);
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
