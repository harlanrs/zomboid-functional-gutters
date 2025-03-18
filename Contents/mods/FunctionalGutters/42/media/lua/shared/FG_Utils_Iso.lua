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
            return adjacentBuilding, adjacentSquare
        end
    end

    return nil, nil
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

function isoUtils:getBuildingFloorArea(building, z)
    local buildingDef = building:getDef()
    local maxZ = buildingDef:getMaxLevel()
    if z == nil then
        z = maxZ
    elseif z > maxZ then
        return nil
    end

    -- TODO if z is not the top floor, take the difference between the floor and the one above

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
    utils:modPrint("Building floor "..tostring(z).." area: "..tostring(area))
    return area
end

function isoUtils:crawlGutterSquare(square, gutterSystemMap, prevDir, crawlSteps)
    if not square then return nil end

    local squareModData = square:getModData()
    local hasDrainPipe = utils:getModDataHasGutter(square, squareModData)
    local hasVerticalPipe = utils:getModDataHasVerticalPipe(square, squareModData)
    local hasGutterPipe = utils:getModDataHasGutterPipe(square, squareModData)
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
                -- local westSquare = getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ())
                if prevDir ~= localIsoDirections.E then
                    local westSquare = square:getW()
                    local crawlWest = self:crawlGutterSquare(westSquare, gutterSystemMap, localIsoDirections.W, crawlSteps)
                    if crawlWest then
                        utils:modPrint("Crawled west to square: "..tostring(crawlWest:getX())..","..tostring(crawlWest:getY())..","..tostring(crawlWest:getZ()))
                        return crawlWest
                    end

                    utils:modPrint("No gutter pipe found west")
                end

                -- Check east
                -- local southSquare = getCell():getGridSquare(square:getX() + 1, square:getY(), square:getZ())
                if prevDir ~= localIsoDirections.W then
                    local eastSquare = square:getE()
                    local crawlSouth = self:crawlGutterSquare(eastSquare, gutterSystemMap, localIsoDirections.E, crawlSteps)
                    if crawlSouth then
                        utils:modPrint("Crawled east to square: "..tostring(crawlSouth:getX())..","..tostring(crawlSouth:getY())..","..tostring(crawlSouth:getZ()))
                        return crawlSouth
                    end

                    utils:modPrint("No gutter pipe found east")
                end
            else
                -- Check north
                -- local northSquare = getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ())
                if prevDir ~= localIsoDirections.S then
                    local northSquare = square:getN()
                    local crawlNorth = self:crawlGutterSquare(northSquare, gutterSystemMap, localIsoDirections.N, crawlSteps)
                    if crawlNorth then
                        utils:modPrint("Crawled north to square: "..tostring(crawlNorth:getX())..","..tostring(crawlNorth:getY())..","..tostring(crawlNorth:getZ()))
                        return crawlNorth
                    end

                    utils:modPrint("No gutter pipe found north")
                end

                -- Check south
                -- local southSquare = getCell():getGridSquare(square:getX(), square:getY() + 1, square:getZ())
                if prevDir ~= localIsoDirections.N then
                    local southSquare = square:getS()
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
    if not square then return nil end

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
    -- Check if square is 'occupied' (solidTrans or solid is true)
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
    local nextSquare = dir == IsoDirections.N and square:getN() or square:getW()
    local crawlNext = self:crawlPlayerBuildingRoofSquare(nextSquare, roofMap, dir, crawlSteps) -- TODO up dir?
    if crawlNext then
        utils:modPrint("Crawled to square: "..tostring(crawlNext:getX())..","..tostring(crawlNext:getY())..","..tostring(crawlNext:getZ()))
        return crawlNext
    end

    return square
end

function isoUtils:getPlayerBuildingFloorArea(square)
    -- TODO instead of trying to walk every all directions
    -- lets use the gutter pipes to determine a length
    -- and walk 'in' from each segment of gutter pipes
    -- ex: 6 gutter pipes long, walk 4 in from each for a total area of 24
    
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

    -- TODO check each gutter square for 

    local validRoofTiles = {}

    for i=1, #gutterSystemMap[enums.pipeType.gutter] do
        local gutterSquare = gutterSystemMap[enums.pipeType.gutter][i]
        local objectIndex, squareGutter, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(gutterSquare, enums.pipeType.gutter)
        -- TODO use attachedN and attachedW or facing props?
        local spriteDef = enums.pipes[spriteName]
        local squareCrawlSteps = 0

        local attachedRoofX = spriteDef.position == IsoDirections.N and gutterSquare:getX() or gutterSquare:getX() - 1
        local attachedRoofY = spriteDef.position == IsoDirections.N and gutterSquare:getY() - 1 or gutterSquare:getY()
        local attachedRoofSquare = getCell():getGridSquare(attachedRoofX, attachedRoofY, gutterSquare:getZ() + 1)
        -- local crawlDirection = spriteDef.position == IsoDirections.N and IsoDirections.N or IsoDirections.W
        self:crawlPlayerBuildingRoofSquare(attachedRoofSquare, validRoofTiles, spriteDef.position, squareCrawlSteps)
    end

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

function isoUtils:getGutterRoofArea(square)
    local building = square:getBuilding()
    utils:modPrint("Tile in building: "..tostring(building))

    local roofBuilding = square:getRoofHideBuilding()
    if roofBuilding then
        utils:modPrint("Roof Building: "..tostring(roofBuilding))
    end

    local buildingSquare = square
    if not building then
        building, buildingSquare = isoUtils:getAdjacentBuilding(square)
        utils:modPrint("Adjacent Building: "..tostring(building))
        if buildingSquare then
            roofBuilding = buildingSquare:getRoofHideBuilding()
            utils:modPrint("Adjacent Roof Building: "..tostring(roofBuilding))
        end
    end

    -- Calculate area of top-floor assuming it's 1-1 square -> roof
    local topGutterFloor = isoUtils:findGutterTopLevel(square)
    utils:modPrint("Top Gutter Floor: "..tostring(topGutterFloor))

    if not building then
        -- Check for player built floors
        return self:getPlayerBuildingFloorArea(square)
    end

    return isoUtils:getBuildingFloorArea(building, topGutterFloor)
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

-- function isoUtils:applyToSquareStackUp(square, func)
    
-- end

-- function isoUtils:applyToSquareStackDown(square, func)

-- end

-- square:HasSlopedRoofNorth
-- this.Has(IsoObjectType.WestRoofB) || this.Has(IsoObjectType.WestRoofM) || this.Has(IsoObjectType.WestRoofT);

-- square:HasSlopedRoofWest
-- this.Has(IsoObjectType.WestRoofB) || this.Has(IsoObjectType.WestRoofM) || this.Has(IsoObjectType.WestRoofT);

-- square:HasEave
-- this.getProperties().Is(IsoFlagType.isEave);

-- for player built:
-- check if square has a roof (exterior is false) or if the floor is 'occupied' (solidTrans or solid is true)

return isoUtils