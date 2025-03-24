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

function isoUtils:isValidPlayerBuiltFloor(square)
    -- Ensure has player-built floor
    local hasPlayerBuiltFloor = square:getPlayerBuiltFloor()
    if not hasPlayerBuiltFloor then
        return nil
    end

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

    if props:Is(localIsoFlagType.WallW) or props:Is(localIsoFlagType.WallNW) then
        return true
    end

    -- Check doors/windows
    if self:hasDoorWindowW(square, props) then
        return true
    end

    return false
end

function isoUtils:hasWallN(square, props)
    if not props then
        props = square:getProperties()
    end

    if props:Is(localIsoFlagType.WallN) or props:Is(localIsoFlagType.WallNW) then
        return true
    end

    -- Check doors/windows
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
    if square:isWallSquareNW() then
        return true
    end

    -- Check doors/windows nw
    if self:hasDoorWindowNW(square) then
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

    local hasGutterPipe = utils:checkPropIsGutterPipe(square, squareProps)
    if not hasGutterPipe then
        -- utils:modPrint("No horizontal pipes found on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    -- utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    if crawlSteps > 25 then
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

            if not crawlWest and not crawlEast then
                utils:modPrint("No gutter pipe found east or west")
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

            if not crawlNorth and not crawlSouth then
                utils:modPrint("No gutter pipe found north or south")
            end
        end
    end

    return square
end

function isoUtils:crawlVerticalPipes(square, squareProps, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local hasDrainPipe = utils:checkPropIsDrainPipe(square, squareProps)
    local hasVerticalPipe = utils:checkPropIsVerticalPipe(square, squareProps)
    if not hasVerticalPipe and not hasDrainPipe then
        -- utils:modPrint("No vertical pipes found on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    -- utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    if crawlSteps > 25 then
        -- Shouldn't hit unless player builds a system with 25+ gutter objects
        -- adding as safeguard against runaway recursion
        utils:modPrint("Crawl steps exceeded 25")
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
        -- utils:modPrint("Crawled up to square: "..tostring(crawlUp:getX())..","..tostring(crawlUp:getY())..","..tostring(crawlUp:getZ()))
        return crawlUp
    end

    return square
end

function isoUtils:crawlGutterSquare(square, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local squareProps = square:getProperties()
    if not utils:checkPropIsAnyPipe(square, squareProps) then
        -- utils:modPrint("No gutter item found on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    -- utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    if crawlSteps > 25 then
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

    -- utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    -- TODO setup a max roof crawl enum
    local crawlLimit = 4
    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    if crawlSteps >= crawlLimit then
        -- utils:modPrint("Hit crawl step limit of "..tostring(crawlLimit))
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
        -- utils:modPrint("Crawled to square: "..tostring(crawlNext:getX())..","..tostring(crawlNext:getY())..","..tostring(crawlNext:getZ()))
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
    -- local lastSquare = self:crawlGutterSquare(square, gutterSystemMap, nil, crawlSteps)
    -- utils:modPrint("Gutter system map - drains count: "..tostring(#gutterSystemMap[enums.pipeType.drain]))
    -- utils:modPrint("Gutter system map - verticals count: "..tostring(#gutterSystemMap[enums.pipeType.vertical]))
    -- utils:modPrint("Gutter system map - gutters count: "..tostring(#gutterSystemMap[enums.pipeType.gutter]))
    -- utils:modPrint("Total crawl steps: "..tostring(crawlSteps))

    return gutterSystemMap
end

function isoUtils:isSquareInGutterMap(square, gutterSystemMap)
    for _, pipeSquares in pairs(gutterSystemMap) do
        for i=1, #pipeSquares do
            local gutterSquare = pipeSquares[i]
            if square:getID() == gutterSquare:getID() then
                return true
            end
        end
    end

    return false
end

function isoUtils:getGutterCoveredFloors(gutterSystemMap)
    local validRoofTiles = {}

    for i=1, #gutterSystemMap[enums.pipeType.gutter] do
        local gutterSquare = gutterSystemMap[enums.pipeType.gutter][i]
        local _, _, spriteName, _ = utils:getSpriteCategoryMemberOnTile(gutterSquare, enums.pipeType.gutter)
        -- TODO use facing props?
        local spriteDef = enums.pipes[spriteName]
        local squareCrawlSteps = 0

        local attachedRoofX = spriteDef.position == IsoDirections.N and gutterSquare:getX() or gutterSquare:getX() - 1
        local attachedRoofY = spriteDef.position == IsoDirections.N and gutterSquare:getY() - 1 or gutterSquare:getY()
        local attachedRoofSquare = getCell():getGridSquare(attachedRoofX, attachedRoofY, gutterSquare:getZ() + 1)
        -- local crawlDirection = spriteDef.position == IsoDirections.N and IsoDirections.N or IsoDirections.W
        self:crawlPlayerBuildingRoofSquare(attachedRoofSquare, validRoofTiles, spriteDef.position, squareCrawlSteps)
    end

    return validRoofTiles
end

function isoUtils:getPlayerBuildingFloorArea(square, gutterSystemMap)
    if not gutterSystemMap then
        gutterSystemMap = self:crawlGutterSystem(square)
    end

    local validRoofTiles = self:getGutterCoveredFloors(gutterSystemMap)

    local totalArea = 0
    for k, v in pairs(validRoofTiles) do
        totalArea = totalArea + 1
    end

    return totalArea
end

function isoUtils:findGutterTopLevel(square)
    local cell = square:getCell()
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    -- Check 5 max
    for i=1, 4 do
        local nextFloor = z + 1
        local nextSquare = cell:getGridSquare(x, y, nextFloor)
        if not nextSquare then
            utils:modPrint("Next square level not found: "..tostring(nextFloor))
            break
        elseif not utils:hasVerticalPipeOnTile(nextSquare) then
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

function isoUtils:getGutterRoofArea(square)
    local buildingDef = self:getAttachedBuilding(square)
    if buildingDef then
        -- Calculate area of top-floor assuming it's 1-1 square -> roof
        local topGutterFloor = isoUtils:findGutterTopLevel(square)

        local floorArea = self:getBuildingFloorArea(buildingDef, topGutterFloor)
        local maxZ = buildingDef:getMaxLevel()
        if floorArea and topGutterFloor < maxZ then
            -- Remove the area of the floor above the top gutter floor
            local nextFloorZ = topGutterFloor + 1
            local nextFloorArea = self:getBuildingFloorArea(buildingDef, nextFloorZ)
            if nextFloorArea then
                floorArea = floorArea - nextFloorArea
            end
        end

        return floorArea
    end

    -- Check for player built floors
    return self:getPlayerBuildingFloorArea(square, nil)
end

function isoUtils:applyToSquareStack(square, func)
    local cell = square:getCell()
    local x = square:getX()
    local y = square:getY()
    local z = 0

    -- Check 5 max
    for i=1, 4 do
        local nextFloor = z + 1
        local nextSquare = cell:getGridSquare(x, y, nextFloor)
        local value = func(nextSquare)
        if value then
            return z
        elseif value == false then
            break
        end

        z = nextFloor
    end

    return z
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
            if sq and utils:checkPropIsDrainPipe(sq) then
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