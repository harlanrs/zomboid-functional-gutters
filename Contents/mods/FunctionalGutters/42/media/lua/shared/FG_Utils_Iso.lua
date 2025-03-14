local utils = require("FG_Utils")

local isoUtils = {}

local localIsoDirections = IsoDirections

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
        -- South & East tiles are least likely objects due to isometric view
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

function isoUtils:getPlayerBuildingFloorArea(square, z)
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

    if not building then
        return nil
    end

    -- Calculate area of top-floor assuming it's 1-1 square -> roof
    local topGutterFloor = isoUtils:findGutterTopLevel(square)
    utils:modPrint("Top Gutter Floor: "..tostring(topGutterFloor))
    return isoUtils:getBuildingFloorArea(building, topGutterFloor)
end


-- function isoUtils:getPlayerBuildingFloorArea(square, z)
--     --
-- end

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

return isoUtils