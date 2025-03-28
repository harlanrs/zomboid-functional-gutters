local enums = require("FG_Enums")
local utils = require("FG_Utils")

local isoUtils = {}

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType
local table_insert = table.insert

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

function isoUtils:getSquare2(square, north, reverse)
    local x, y, z
    if reverse then
        x, y, z = self:getSquare2PosReverse(square, north)
    else
        x, y, z = self:getSquare2Pos(square, north)
    end
    return getCell():getGridSquare(x, y, z)
end

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

function isoUtils:isValidPlayerBuiltFloor(square)
    -- Ensure has player-built floor
    local hasPlayerBuiltFloor = square:getPlayerBuiltFloor()
    if not hasPlayerBuiltFloor then
        return nil
    end

    return isoUtils:isValidRoofSquare(square)
end

function isoUtils:hasDoorWindowN(square, props)
    if not props then
        props = square:getProperties()
    end
    return props:Is(localIsoFlagType.DoorWallN) or props:Is("WindowN") -- IsoFlagType has "windowN" not "WindowN" which is a bug
end

function isoUtils:hasDoorWindowW(square, props)
    if not props then
        props = square:getProperties()
    end
    return props:Is(localIsoFlagType.DoorWallW) or props:Is("WindowW")
end

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

function isoUtils:hasDoorWindowNW(square, props)
    if not props then
        props = square:getProperties()
    end
    return self:hasDoorWindowN(square, props) or self:hasDoorWindowW(square, props)
end

function isoUtils:hasWallNW(square)
    local props = square:getProperties()
    if self:hasWallN(square, props) or self:hasWallW(square, props) then
        return true
    end

    return false
end

function isoUtils:getAdjacentBuilding(square, dir)
    if not dir then
        -- South & East tiles are least likely
        dir = table.newarray(
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

    for i=1, #dir do
        local adjacentSquare = square:getAdjacentSquare(dir[i])
        local adjacentBuilding = adjacentSquare:getBuilding()
        if adjacentBuilding then
            return adjacentBuilding:getDef()
        end
    end

    return nil
end

function isoUtils:getBuildingRoofRoom(building, z)
    local buildingDef = building:getDef()
    local roofRoomId = buildingDef:getRoofRoomID(z)
    if roofRoomId < 0 then
        return nil
    end
    return roofRoomId
end

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

function isoUtils:crawlHorizontalPipes(square, squareProps, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local hasGutterPipe = utils:isGutterPipeSquare(square, squareProps)
    if not hasGutterPipe then
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps > enums.maxGutterCrawlSteps then
        -- Shouldn't hit unless player builds a system with 25+ gutter objects
        -- adding as safeguard against runaway recursion
        utils:modPrint("Crawl steps exceeded 25")
        return square
    end

    -- Try following gutter pipes north, south, east, west
    local _, squareGutter, spriteName, _ = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.gutter)
    if squareGutter then
        table_insert(gutterSystemMap[enums.pipeType.gutter], square)

        local spriteDef = enums.pipes[spriteName]
        if spriteDef.position == localIsoDirections.N or spriteDef.position == localIsoDirections.NW then
            local crawlWest = nil
            local crawlEast = nil

            -- Check west
            if prevDir ~= localIsoDirections.E then
                local westSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
                crawlWest = self:crawlGutterSquare(westSquare, gutterSystemMap, localIsoDirections.W, crawlSteps)
            end

            -- Check east
            if prevDir ~= localIsoDirections.W then
                local eastSquare = getCell():getGridSquare(square:getX() + 1, square:getY(), square:getZ())
                crawlEast = self:crawlGutterSquare(eastSquare, gutterSystemMap, localIsoDirections.E, crawlSteps)
            end
        end

        if spriteDef.position == localIsoDirections.W or spriteDef.position == localIsoDirections.NW then
            local crawlNorth = nil
            local crawlSouth = nil

            -- Check north
            if prevDir ~= localIsoDirections.S then
                local northSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
                crawlNorth = self:crawlGutterSquare(northSquare, gutterSystemMap, localIsoDirections.N, crawlSteps)
            end

            -- Check south
            if prevDir ~= localIsoDirections.N then
                local southSquare = getCell():getGridSquare(square:getX(), square:getY() + 1, square:getZ())
                crawlSouth = self:crawlGutterSquare(southSquare, gutterSystemMap, localIsoDirections.S, crawlSteps)
            end
        end
    end

    return square
end

function isoUtils:crawlVerticalPipes(square, squareProps, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local hasDrainPipe = utils:isDrainPipeSquare(square, squareProps)
    local hasVerticalPipe = utils:isVerticalPipeSquare(square, squareProps)
    if not hasVerticalPipe and not hasDrainPipe then
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps > enums.maxGutterCrawlSteps then
        -- Shouldn't hit unless player builds a system with more gutter objects
        -- adding as failsafe against runaway recursion which also shouldn't occur but just in case
        utils:modPrint("Crawl steps exceeded "..tostring(enums.maxGutterCrawlSteps))
        return square
    end

    if hasDrainPipe then
        table_insert(gutterSystemMap[enums.pipeType.drain], square)
    end
    if hasVerticalPipe then
        table_insert(gutterSystemMap[enums.pipeType.vertical], square)
    end

    -- Following vertical pipes up z levels
    local nextSquare = getCell():getGridSquare(square:getX(), square:getY(), square:getZ() + 1)
    local crawlUp = self:crawlGutterSquare(nextSquare, gutterSystemMap, nil, crawlSteps) -- TODO up dir?
    if crawlUp then
        return crawlUp
    end

    return square
end

function isoUtils:crawlGutterSquare(square, gutterSystemMap, prevDir, crawlSteps)
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
        -- Shouldn't hit unless player builds a system with 25+ gutter objects
        -- adding as safeguard against runaway recursion
        utils:modPrint("Crawl steps exceeded 25")
        return square
    end

    self:crawlHorizontalPipes(square, squareProps, gutterSystemMap, prevDir, crawlSteps)
    self:crawlVerticalPipes(square, squareProps, gutterSystemMap, prevDir, crawlSteps)

    return square
end

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

    return square
end

function isoUtils:crawlGutterSystem(square)
    local gutterSystemMap = {
        [enums.pipeType.drain] = table.newarray(),
        [enums.pipeType.vertical] = table.newarray(),
        [enums.pipeType.gutter] = table.newarray()
    }
    local crawlSteps = 0
    self:crawlGutterSquare(square, gutterSystemMap, nil, crawlSteps)
    return gutterSystemMap
end

function isoUtils:isSquareInGutterPipeMap(square, gutterPipeMap)
    for _, pipeSquares in pairs(gutterPipeMap) do
        for i=1, #pipeSquares do
            local gutterSquare = pipeSquares[i]
            if square:getID() == gutterSquare:getID() then
                return true
            end
        end
    end

    return false
end

function isoUtils:getPlayerBuildingRoofSquares(gutterPipeMap)
    local validRoofSquares = {}

    for i=1, #gutterPipeMap[enums.pipeType.gutter] do
        local gutterSquare = gutterPipeMap[enums.pipeType.gutter][i]
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

function isoUtils:getPlayerBuildingRoofArea(square, gutterPipeMap)
    if not gutterPipeMap then
        gutterPipeMap = self:crawlGutterSystem(square)
    end

    local validRoofSquares = self:getPlayerBuildingRoofSquares(gutterPipeMap)

    local totalArea = 0
    for k, v in pairs(validRoofSquares) do
        totalArea = totalArea + 1
    end

    return totalArea, validRoofSquares
end

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

function isoUtils:getAttachedBuilding(square)
    -- Check square directly
    local squareBuilding = square:getBuilding()
    if squareBuilding then
        return squareBuilding:getDef()
    end

    -- Check square's meta grid (includes the outside perimeter squares unlike base square:getBuilding() method)
    local buildingDef = getWorld():getMetaGrid():getAssociatedBuildingAt(square:getX(), square:getY())
    if buildingDef then
        return buildingDef
    end

    -- Check adjacent squares
    return self:getAdjacentBuilding(square)
end

function isoUtils:getGutterTopLevel(gutterPipeMap)
    local topLevel = 0
    for pipeType, pipeSquares in pairs(gutterPipeMap) do
        if pipeType == enums.pipeType.drain or pipeType == enums.pipeType.vertical then
            -- Only check vertical or drain pipes
            for i=1, #pipeSquares do
                local gutterSquare = pipeSquares[i]
                local squareZ = gutterSquare:getZ()
                if squareZ > topLevel then
                    topLevel = squareZ
                end
            end
        end
    end

    return topLevel
end

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

function isoUtils:getVanillaBuildingRoofArea(square, gutterPipeMap, buildingDef)
    if not buildingDef then
        buildingDef = self:getAttachedBuilding(square)
    end

    if not buildingDef then
        -- No building def exists for this square
        return nil, nil
    end

    local topGutterFloor = self:getGutterTopLevel(gutterPipeMap)
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

function isoUtils:getGutterRoofArea(square, gutterPipeMap)
    local buildingDef = self:getAttachedBuilding(square)
    local roofArea, roofSquares, buildingType
    if buildingDef then
        -- Vanilla building mode
        buildingType = enums.buildingType.vanilla
        roofArea, roofSquares = self:getVanillaBuildingRoofArea(square, gutterPipeMap, buildingDef)
    else
        -- Custom building mode
        buildingType = enums.buildingType.custom
        roofArea, roofSquares = self:getPlayerBuildingRoofArea(square, gutterPipeMap)
    end

    return roofArea, roofSquares, buildingType
end

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

function isoUtils:findAllDrainsInRadius(square, radius)
    local pipeObjects = table.newarray()
    local sx,sy,sz = square:getX(), square:getY(), square:getZ();
    for x = sx-radius,sx+radius do
        for y = sy-radius,sy+radius do
            local sq = getCell():getGridSquare(x,y,sz);
            if sq and utils:isDrainPipeSquare(sq) then
                local _, pipeObject, _, _ = utils:getSpriteCategoryMemberOnTile(sq, enums.pipeType.drain)
                if pipeObject then
                    utils:modPrint("Found drain pipe: "..tostring(pipeObject:getX())..","..tostring(pipeObject:getY())..","..tostring(pipeObject:getZ()))
                    table_insert(pipeObjects, pipeObject)
                end
            end
        end
    end

    return pipeObjects
end

return isoUtils