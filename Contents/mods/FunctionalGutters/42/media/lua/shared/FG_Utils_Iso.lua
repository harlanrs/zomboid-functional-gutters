local enums = require("FG_Enums")
local utils = require("FG_Utils")

local isoUtils = {}

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

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

-- function isoUtils:getAdjacentWall(square, dir)
--     if not dir then
--         -- South & East tiles are least likely
--         dir = table.newarray(
--             localIsoDirections.N,
--             localIsoDirections.W,
--             localIsoDirections.NW,
--             localIsoDirections.SW,
--             localIsoDirections.NE,
--             localIsoDirections.S,
--             localIsoDirections.E,
--             localIsoDirections.SE
--         )
--     end

--     for i=1, #dir do
--         local adjacentSquare = square:getAdjacentSquare(dir[i])
--         local adjacentWall = adjacentSquare:getWall()
--         if adjacentBuilding then
--             return adjacentBuilding, adjacentSquare
--         end
--     end

--     return nil, nil
-- end

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

function isoUtils:crawlGutterSquare(square, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local squareProps = square:getProperties()
    local hasDrainPipe = utils:checkPropIsDrainPipe(square, squareProps)
    local hasVerticalPipe = utils:checkPropIsVerticalPipe(square, squareProps)
    local hasGutterPipe = utils:checkPropIsGutterPipe(square, squareProps)
    if not hasGutterPipe and not hasVerticalPipe and not hasDrainPipe then
        utils:modPrint("No gutter item found on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1
    utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    if crawlSteps > 25 then
        -- Shouldn't hit unless player builds a system with 25+ gutter objects
        -- adding as safeguard against runaway recursion
        utils:modPrint("Crawl steps exceeded 25")
        return square
    end

    if hasDrainPipe or hasVerticalPipe then
        if hasDrainPipe then
            table.insert(gutterSystemMap[enums.pipeType.drain], square)
        end
        if hasVerticalPipe then
            table.insert(gutterSystemMap[enums.pipeType.vertical], square)
        end
        -- Prioritize following vertical pipes up z levels
        local nextSquare = getCell():getGridSquare(square:getX(), square:getY(), square:getZ() + 1)
        local crawlUp = self:crawlGutterSquare(nextSquare, gutterSystemMap, nil, crawlSteps) -- TODO up dir?
        if crawlUp then
            utils:modPrint("Crawled up to square: "..tostring(crawlUp:getX())..","..tostring(crawlUp:getY())..","..tostring(crawlUp:getZ()))
            return crawlUp
        end
    end

    if hasGutterPipe then
        -- Try following gutter pipes north, south, east, west
        local i, squareGutter, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(square, enums.pipeType.gutter)
        if squareGutter then
            table.insert(gutterSystemMap[enums.pipeType.gutter], square)

            local spriteDef = enums.pipes[spriteName]
            if spriteDef.position == localIsoDirections.N then
                -- Check west
                if prevDir ~= localIsoDirections.E then
                    local westSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
                    local crawlWest = self:crawlGutterSquare(westSquare, gutterSystemMap, localIsoDirections.W, crawlSteps)
                    if crawlWest then
                        utils:modPrint("Crawled west to square: "..tostring(crawlWest:getX())..","..tostring(crawlWest:getY())..","..tostring(crawlWest:getZ()))
                        return crawlWest
                    end

                    utils:modPrint("No gutter pipe found west")
                end

                -- Check east
                if prevDir ~= localIsoDirections.W then
                    local eastSquare = getCell():getGridSquare(square:getX() + 1, square:getY(), square:getZ())
                    local crawlSouth = self:crawlGutterSquare(eastSquare, gutterSystemMap, localIsoDirections.E, crawlSteps)
                    if crawlSouth then
                        utils:modPrint("Crawled east to square: "..tostring(crawlSouth:getX())..","..tostring(crawlSouth:getY())..","..tostring(crawlSouth:getZ()))
                        return crawlSouth
                    end

                    utils:modPrint("No gutter pipe found east")
                end
            else
                -- Check north
                if prevDir ~= localIsoDirections.S then
                    local northSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
                    local crawlNorth = self:crawlGutterSquare(northSquare, gutterSystemMap, localIsoDirections.N, crawlSteps)
                    if crawlNorth then
                        utils:modPrint("Crawled north to square: "..tostring(crawlNorth:getX())..","..tostring(crawlNorth:getY())..","..tostring(crawlNorth:getZ()))
                        return crawlNorth
                    end

                    utils:modPrint("No gutter pipe found north")
                end

                -- Check south
                if prevDir ~= localIsoDirections.N then
                    local southSquare = getCell():getGridSquare(square:getX(), square:getY() + 1, square:getZ())
                    local crawlSouth = self:crawlGutterSquare(southSquare, gutterSystemMap, localIsoDirections.S, crawlSteps)
                    if crawlSouth then
                        utils:modPrint("Crawled south to square: "..tostring(crawlSouth:getX())..","..tostring(crawlSouth:getY())..","..tostring(crawlSouth:getZ()))
                        return crawlSouth
                    end

                    utils:modPrint("No gutter pipe found south")
                end
            end

            return square
        end
    end
end

function isoUtils:crawlPlayerBuildingRoofSquare(square, roofMap, dir, crawlSteps)
    if not square then
        utils:modPrint("No square found")
        return nil
    end

    local hasPlayerBuiltFloor = square:getPlayerBuiltFloor()
    if not hasPlayerBuiltFloor then
        utils:modPrint("No player built floor found on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
        return nil
    end

    if not crawlSteps then crawlSteps = 0 end
    crawlSteps = crawlSteps + 1

    -- Check if square is 'valid'
    -- * no roof / is external
    -- * has a floor
    -- * no occupied by a solidTrans or solid object
    -- Ex: don't want to count a square that has a rain catcher already on it
    local isOccupied = square:isSolid() or square:isSolidTrans()
    if square:isOutside() and not isOccupied then
        -- Add square to roof map
        roofMap[square:getID()] = square
    end

    utils:modPrint("Crawl step "..tostring(crawlSteps).." on square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
    -- TODO setup a max roof crawl enum
    if crawlSteps > 5 then
        utils:modPrint("Crawl steps hit max")
        return square
    end

    -- Prioritize following vertical pipes up z levels
    local nextSquare
    if dir == IsoDirections.N then
        -- nextSquare = square:getN()
        nextSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
    else
        -- nextSquare = square:getW()
        nextSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
    end
    -- local nextSquare = dir == IsoDirections.N and square:getN() or square:getW()
    local crawlNext = self:crawlPlayerBuildingRoofSquare(nextSquare, roofMap, dir, crawlSteps) -- TODO up dir?
    if crawlNext then
        utils:modPrint("Crawled to square: "..tostring(crawlNext:getX())..","..tostring(crawlNext:getY())..","..tostring(crawlNext:getZ()))
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
    local lastSquare = self:crawlGutterSquare(square, gutterSystemMap, nil, crawlSteps)
    utils:modPrint("Gutter system map - drains count: "..tostring(#gutterSystemMap[enums.pipeType.drain]))
    utils:modPrint("Gutter system map - verticals count: "..tostring(#gutterSystemMap[enums.pipeType.vertical]))
    utils:modPrint("Gutter system map - gutters count: "..tostring(#gutterSystemMap[enums.pipeType.gutter]))
    utils:modPrint("Total crawl steps: "..tostring(crawlSteps))
    if lastSquare then
        utils:modPrint("Last square: "..tostring(lastSquare:getX())..","..tostring(lastSquare:getY())..","..tostring(lastSquare:getZ()))
    end

    return gutterSystemMap
end

function isoUtils:isSquareInGutterMap(square, gutterSystemMap)
    for _, pipeSquares in pairs(gutterSystemMap) do
        for i=1, #pipeSquares do
            local gutterSquare = pipeSquares[i]
            if square:getId() == gutterSquare:getSquare() then
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
        local objectIndex, squareGutter, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(gutterSquare, enums.pipeType.gutter)
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
    -- TODO instead of trying to walk every all directions
    -- lets use the gutter pipes to determine a length
    -- and walk 'in' from each segment of gutter pipes
    -- ex: 6 gutter pipes long, walk 4 in from each for a total area of 24
    if not gutterSystemMap then
        gutterSystemMap = self:crawlGutterSystem(square)
    end

    local validRoofTiles = self:getGutterCoveredFloors(gutterSystemMap)

    local totalArea = 0
    for k, v in pairs(validRoofTiles) do
        totalArea = totalArea + 1
    end

    utils:modPrint("Total roof area: "..tostring(totalArea))

    return totalArea

    -- if not square:getPlayerBuiltFloor() then
    --     return 0
    -- end
    -- local maxWalk = 10
    -- local area = 1
    -- local z = square:getZ()
    -- local x = square:getX()
    -- local y = square:getY()
    -- local finalXSquare = square
    -- local finalYSquare = square
    -- local walkYLength = 0 -- TODO base on gutter length?
    -- local walkXLength = 0 -- TODO base on gutter length?

    -- for i=1, maxWalk do
    --     local nextX = x - i
    --     local nextSquare = square:getCell():getGridSquare(nextX, y, z)
    --     if not nextSquare or not nextSquare:getPlayerBuiltFloor() then
    --         break
    --     end

    --     finalXSquare = nextSquare
    --     walkXLength = walkXLength + 1
    -- end

    -- for i=1, maxWalk do
    --     local nextY = y - i
    --     local nextSquare = square:getCell():getGridSquare(x, nextY, z)
    --     if not nextSquare or not nextSquare:getPlayerBuiltFloor() then
    --         break
    --     end

    --     finalYSquare = nextSquare
    --     walkYLength = walkYLength + 1
    -- end

    -- utils:modPrint("Walk X: "..tostring(walkXLength))
    -- utils:modPrint("Walk Y: "..tostring(walkYLength))
    -- utils:modPrint("final X square: "..tostring(finalXSquare:getX())..","..tostring(finalXSquare:getY())..","..tostring(finalXSquare:getZ()))
    -- utils:modPrint("final Y square: "..tostring(finalYSquare:getX())..","..tostring(finalYSquare:getY())..","..tostring(finalYSquare:getZ()))

    -- square:hasRainBlockingTile
    -- square:haveRoofFull
    -- square:hasFloor
    -- square:getPlayerBuiltFloor
    -- square:AddTileObject or AddSpecialTileObject
    -- transmitAddObjectToSquare

    -- local squareHasRoof = square:haveRoof()
    -- (var10.isFloor() || var4.haveRoof || var4.HasSlopedRoof()
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
            utils:modPrint("next square level not found: "..tostring(nextFloor))
            break
        elseif not utils:hasVerticalPipeOnTile(nextSquare) then
            break
        end

        z = nextFloor
    end

    return z
end

function isoUtils:getAttachedBuilding(square)
    -- TODO check the 'cost' of this as it is only used in debug mode chunk panel
    -- NOTE: this method includes outside wall squares
    -- isoMetaCell:getMetaGridFromTile(x, y)
    local buildingDef = getWorld():getMetaGrid():getAssociatedBuildingAt(square:getX(), square:getY())
    if buildingDef then
        return buildingDef
    end

    return self:getAdjacentBuilding(square)
end

function isoUtils:getGutterRoofArea(square)
    local buildingDef = self:getAttachedBuilding(square)
    if buildingDef then
        -- Calculate area of top-floor assuming it's 1-1 square -> roof
        local topGutterFloor = isoUtils:findGutterTopLevel(square)
        utils:modPrint("Top gutter floor: "..tostring(topGutterFloor))

        local floorArea = self:getBuildingFloorArea(buildingDef, topGutterFloor)
        local maxZ = buildingDef:getMaxLevel()
        if floorArea and topGutterFloor < maxZ then
            -- Remove the area of the floor above the top gutter floor
            local nextFloorZ = topGutterFloor + 1
            local nextFloorArea = self:getBuildingFloorArea(buildingDef, nextFloorZ)
            if nextFloorArea then
                utils:modPrint("Removing upstairs floor "..tostring(nextFloorZ).." area: "..tostring(nextFloorArea))
                floorArea = floorArea - nextFloorArea
            end
        end

        utils:modPrint("Total gutter roof area: "..tostring(floorArea))
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

function isoUtils:findAllPipesInRadius(square, radius, pipeType)
    local pipeObjects = table.newarray()
    local sx,sy,sz = square:getX(), square:getY(), square:getZ();
    for x = sx-radius,sx+radius do
        for y = sy-radius,sy+radius do
            local sq = getCell():getGridSquare(x,y,sz);
            if sq then
                local _, pipeObject, _, _ = utils:getSpriteCategoryMemberOnTile(sq, pipeType)
                if pipeObject then
                    table.insert(pipeObjects, pipeObject)
                end
            end
        end
    end

    return pipeObjects
end

return isoUtils