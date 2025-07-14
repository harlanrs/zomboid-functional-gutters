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
        local adjacentBuilding = adjacentSquare:getBuilding()
        if adjacentBuilding then
            return adjacentBuilding
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
---@param squareProps PropertyContainer
---@param gutterPipeMap GutterPipeMap
---@param prevDir IsoDirections|nil
---@param crawlSteps integer|nil
---@return IsoGridSquare|nil
function isoUtils:crawlHorizontalPipes(square, squareProps, gutterPipeMap, prevDir, crawlSteps)
    if not square then return nil end

    local hasGutterPipe = utils:isGutterPipeSquare(square, squareProps)
    if not hasGutterPipe then
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps > enums.maxGutterCrawlSteps then
        -- Shouldn't hit unless player builds a large system with more gutter objects
        -- adding as failsafe against runaway recursion which also shouldn't occur but just in case
        utils:modPrint("Crawl steps exceeded maximum: "..tostring(enums.maxGutterCrawlSteps))
        return square
    end

    -- Try following gutter pipes north, south, east, west
    local _, squareGutter, spriteName, _ = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.gutter)
    if squareGutter then
        local squareID = square:getID()
        gutterPipeMap[enums.pipeType.gutter][squareID] = square
        gutterPipeMap._all[squareID] = square
        gutterPipeMap._gutter_count = gutterPipeMap._gutter_count + 1 -- NOTE: bit hacky but useful to not have to dynamically check the size of the dictionary in ui

        local spriteDef = enums.pipes[spriteName]
        if spriteDef.position == localIsoDirections.N or spriteDef.position == localIsoDirections.NW then
            -- Check west
            if prevDir ~= localIsoDirections.E then
                local westSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
                self:crawlGutterSquare(westSquare, gutterPipeMap, localIsoDirections.W, crawlSteps)
            end

            -- Check east
            if prevDir ~= localIsoDirections.W then
                local eastSquare = getCell():getGridSquare(square:getX() + 1, square:getY(), square:getZ())
                self:crawlGutterSquare(eastSquare, gutterPipeMap, localIsoDirections.E, crawlSteps)
            end
        end

        if spriteDef.position == localIsoDirections.W or spriteDef.position == localIsoDirections.NW then
            -- Check north
            if prevDir ~= localIsoDirections.S then
                local northSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
                self:crawlGutterSquare(northSquare, gutterPipeMap, localIsoDirections.N, crawlSteps)
            end

            -- Check south
            if prevDir ~= localIsoDirections.N then
                local southSquare = getCell():getGridSquare(square:getX(), square:getY() + 1, square:getZ())
                self:crawlGutterSquare(southSquare, gutterPipeMap, localIsoDirections.S, crawlSteps)
            end
        end
    end

    -- TODO rethink response now that we check forked paths and won't have a singular final square
    return square
end

---@param square IsoGridSquare
---@param squareProps PropertyContainer
---@param gutterPipeMap GutterPipeMap
---@param prevDir IsoDirections|nil
---@param crawlSteps integer|nil
---@return IsoGridSquare|nil
function isoUtils:crawlVerticalPipes(square, squareProps, gutterPipeMap, prevDir, crawlSteps)
    if not square then return nil end

    local hasDrainPipe = utils:isDrainPipeSquare(square, squareProps)
    local hasVerticalPipe = utils:isVerticalPipeSquare(square, squareProps)
    if not hasVerticalPipe and not hasDrainPipe then
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps > enums.maxGutterCrawlSteps then
        -- Shouldn't hit unless player builds a large system with more gutter objects
        -- adding as failsafe against runaway recursion which also shouldn't occur but just in case
        utils:modPrint("Crawl steps exceeded "..tostring(enums.maxGutterCrawlSteps))
        return square
    end

    local squareID = square:getID()
    if hasDrainPipe then
        gutterPipeMap[enums.pipeType.drain][squareID] = square
        gutterPipeMap._drain_count = gutterPipeMap._drain_count + 1 -- NOTE: bit hacky but useful to not have to dynamically check the size of the dictionary in ui
    end
    if hasVerticalPipe then
        gutterPipeMap[enums.pipeType.vertical][squareID] = square
        gutterPipeMap._vertical_count = gutterPipeMap._vertical_count + 1 -- NOTE: bit hacky but useful to not have to dynamically check the size of the dictionary in ui
    end

    gutterPipeMap._all[squareID] = square

    -- Following vertical pipes up z levels
    local nextSquare = getCell():getGridSquare(square:getX(), square:getY(), square:getZ() + 1)
    local crawlUp = self:crawlGutterSquare(nextSquare, gutterPipeMap, nil, crawlSteps) -- TODO up dir?
    if crawlUp then
        return crawlUp
    end

    -- TODO rethink response now that we check forked paths and won't have a singular final square
    return square
end

---@param square IsoGridSquare
---@param gutterPipeMap GutterPipeMap
---@param prevDir IsoDirections|nil
---@param crawlSteps integer|nil
---@return IsoGridSquare|nil
function isoUtils:crawlGutterSquare(square, gutterPipeMap, prevDir, crawlSteps)
    if not square then return nil end

    local squareProps = square:getProperties()
    if not utils:isAnyPipeSquare(square, squareProps) then
        return nil
    elseif not prevDir and not utils:isVerticalPipeSquare(square, squareProps) and not utils:isDrainPipeSquare(square, squareProps) then
        -- When no prevDir (coming up from below), ensure a vertical pipe exists before crawling
        -- This is to prevent horizontal/gutter pipes from being included when there is no vertical pipe to connect them
        -- TODO provide "up"/"down" prevDir if we want to reverse crawl and navigate top-down
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps > enums.maxGutterCrawlSteps then
        -- Shouldn't hit unless player builds a large system with more gutter objects
        -- adding as failsafe against runaway recursion which also shouldn't occur but just in case
        utils:modPrint("Crawl steps exceeded "..tostring(enums.maxGutterCrawlSteps))
        return square
    end

    self:crawlHorizontalPipes(square, squareProps, gutterPipeMap, prevDir, crawlSteps)
    self:crawlVerticalPipes(square, squareProps, gutterPipeMap, prevDir, crawlSteps)

    -- TODO rethink response now that we check forked paths and won't have a singular final square
    return square
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

-- TODO rename to crawlGutterPipes so that "system" can be used for the entire gutter system including roofs and meta data
---@param square IsoGridSquare
---@return GutterPipeMap gutterPipeMap
function isoUtils:crawlGutterSystem(square)
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
    self:crawlGutterSquare(square, gutterPipeMap, nil, crawlSteps)

    gutterPipeMap._count = utils:getDictSize(gutterPipeMap._all)

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

---@param buildingDef BuildingDef
---@param zLevel integer
---@return GutterRoofMap floorSquares
function isoUtils:getVanillaBuildingFloorSquares(buildingDef, zLevel)
    local floorSquares = {}
    local buildingDefRooms = buildingDef:getRooms()
    for i=0, buildingDefRooms:size() - 1 do
        local roomDef  = buildingDefRooms:get(i)
        local roomZ = roomDef:getZ()
        if roomZ == zLevel then
            if roomDef:isEmptyOutside() then
                -- Ignore empty outside rooms
                utils:modPrint("Room is empty outside: "..tostring(roomDef:getID()))
            else
                local isoRoom = roomDef:getIsoRoom()
                if isoRoom then
                    local roomSquares = isoRoom:getSquares()
                    for j=0, roomSquares:size() - 1 do
                        local square = roomSquares:get(j)
                        floorSquares[square:getID()] = square
                    end
                end
            end
        end
    end

    return floorSquares
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap|nil
---@param building IsoBuilding
---@return integer roofArea, GutterRoofMap roofSquares
function isoUtils:getVanillaBuildingRoofAreaFromFloors(square, pipeMap, building)
    -- NOTE: not used atm because building bounds strategy is more accurate for a broader set of configurations
    if not pipeMap then
        pipeMap = self:crawlGutterSystem(square)
    end

    local topGutterFloor = self:getGutterTopLevel(pipeMap)
    local buildingDef = building:getDef()
    local floorSquares = self:getVanillaBuildingFloorSquares(buildingDef, topGutterFloor)
    local maxZ = buildingDef:getMaxLevel()
    local roofArea = 0
    local roofSquares = {}

    for _, floorSquare in pairs(floorSquares) do
        local squareX = floorSquare:getX()
        local squareY = floorSquare:getY()
        local squareZ = floorSquare:getZ()
        local roofSquare = getCell():getGridSquare(squareX, squareY, squareZ + 1)
        if squareZ == maxZ then
            -- If the square is at the max level, then we can assume the square above is a valid roof
            roofArea = roofArea + 1
            roofSquares[roofSquare:getID()] = roofSquare
        else
            -- Otherwise check if the square above is valid
            if self:isValidRoofSquare(roofSquare) then
                roofArea = roofArea + 1
                roofSquares[roofSquare:getID()] = roofSquare
            end
        end
    end

    return roofArea, roofSquares
end

---@param square IsoGridSquare
---@param pipeMap GutterPipeMap|nil
---@param building IsoBuilding
---@return integer roofArea, GutterRoofMap roofSquares
function isoUtils:getVanillaBuildingRoofAreaFromBounds(square, pipeMap, building)
    -- NOTE: "bounds" strategy is generally more accurate for a broader set of configurations compared to "rooms" strategy 
    -- but might be less performant for buildings that generate a large bounding rect compared to what space is actually occupied by the structure
    if not pipeMap then
        pipeMap = self:crawlGutterSystem(square)
    end

    local topGutterFloor = self:getGutterTopLevel(pipeMap)
    local buildingDef = building:getDef()
    local buildingBounds = {
        x = buildingDef:getX(),
        y = buildingDef:getY(),
        x2 = buildingDef:getX2(),
        y2 = buildingDef:getY2(),
        w = buildingDef:getW(),
        h = buildingDef:getH(),
    }
    local buildingDefId = buildingDef:getID() -- NOTE: different from IsoBuilding ID
    local maxZ = buildingDef:getMaxLevel()
    local minZ = buildingDef:getMinLevel()
    local roofZ = topGutterFloor > maxZ and maxZ + 1 or topGutterFloor + 1
    local roofArea = 0
    local roofSquares = {}

    local startX = buildingBounds.x
    local startY = buildingBounds.y
    local metaGrid = getWorld():getMetaGrid()
    for x = 0, buildingBounds.w do
        for y = 0, buildingBounds.h do
            local squareX = startX + x
            local squareY = startY + y

            -- Verify square is 'associated' with the building
            -- Roof squares are not in the bounds of the IsoBuilding but will still be associated with it from a meta grid perspective
            -- Additionally, building bounds might intersect or overlap so we need to ensure roofs from other buildings are not included
            local associatedBuilding = metaGrid:getAssociatedBuildingAt(squareX, squareY)
            if associatedBuilding and associatedBuilding:getID() == buildingDefId then
                local roofSquare = getCell():getGridSquare(squareX, squareY, roofZ)
                -- Check if the square is valid to be considered a roof square
                if roofSquare and self:isValidRoofSquare(roofSquare) then
                    -- If the square doesn't have a floor, it might still be a valid roof but requires additional checks
                    if not roofSquare:getFloor() then
                        -- Verify the square is associated with a room on the min z level of the building (generally the 'ground' floor has the largest area of rooms)
                        -- TODO check if this is the best way to determine if a square is part of a room as there are some holes
                        -- maybe just check the square directly below for being inside or outside? if outside then ignore it
                        local downSquare = getCell():getGridSquare(squareX, squareY, roofZ - 1)
                        if downSquare and not downSquare:isOutside() then
                            roofArea = roofArea + 1
                            roofSquares[roofSquare:getID()] = roofSquare
                        end
                    else
                        roofArea = roofArea + 1
                        roofSquares[roofSquare:getID()] = roofSquare
                    end
                end
            end

            -- Don't crawl the entirety of extremely large buildings (25x25 = 625 squares)
            if y >= enums.maxBuildingBoundCrawlSteps then break end
        end

        -- Don't crawl the entirety of extremely large buildings (25x25 = 625 squares)
        if x >= enums.maxBuildingBoundCrawlSteps then break end
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
        roofArea, roofSquares = self:getVanillaBuildingRoofAreaFromBounds(square, pipeMap, building)
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