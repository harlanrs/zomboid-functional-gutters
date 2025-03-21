local enums = require("FG_Enums")
local utils = require("FG_Utils")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

FG_BuildRecipeCode = {}
FG_BuildRecipeCode.pipe = {
    drain = {},
    vertical = {},
    horizontal = {},
    gutter = {},
}

function FG_BuildRecipeCode.pipe.drain.OnCreate(object)
    -- TODO if anything needs to be done on creation
    utils:modPrint("Drain pipe on create func: "..tostring(object))
    return object
end

function FG_BuildRecipeCode.pipe.drain.OnIsValid(params)
    local square = params.square
    local z = square:getZ()

    -- Requires being outside (so any connected collector can still receive rain)
    if not square:isOutside() then
        return false
    end

    -- Requires a floor (so any collectors can be placed on top)
	if z > 0 then
		if not square:hasFloor() then
            return false
        end
	end

    -- Requires a wall (to attach on)
    if not square:isWallSquareNW() then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        local northProps = adjacentSquareN:getProperties()
        if not northProps:Is(localIsoFlagType.WallW) then
            -- Check if the square to the west has a wall on the north
            local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
            if not adjacentSquareW then
                return false
            end

            local westProps = adjacentSquareW:getProperties()
            if not westProps:Is(localIsoFlagType.WallN) then
                return false
            end
        end
    end

    -- Requires no existing drain pipe
    if utils:hasDrainPipeOnTile(square) then
        return false
    end

    -- Requires no existing drain pipe within x tiles 
    -- NOTE: might be too much of a performance hit - will need to verify
    -- TODO check if drain pipe in on a pre-made building
    -- if so, also check if the found drainpipe is connected to the same building
    -- Allows for placing drains closer together when they are part of different buildings
    local radius = 6
    local sx,sy,sz = square:getX(), square:getY(), square:getZ();
    for x = sx-radius,sx+radius do
        for y = sy-radius,sy+radius do
            local sq = getCell():getGridSquare(x,y,sz);
            if sq then
                local squareObjects = sq:getObjects() 
                for i=0,squareObjects:size()-1, 1 do
                    local object = squareObjects:get(i)
                    if object and utils:checkPropIsDrainPipe(squareObjects:get(i)) then
                        -- Drain pipe found within radius
                        return false
                    end
                end
            end
        end
    end

	return true
end

function FG_BuildRecipeCode.pipe.vertical.OnIsValid(params)
    local square = params.square
    local z = square:getZ()

    -- Requires being outside
    if not square:isOutside() then
        return false
    end

    -- Requires not being on or below the ground floor
    -- TODO maybe revisit to support basements
    if z <= 0 then
        return false
    end

    -- Requires an open floor
	if z > 0 then
		if square:hasFloor() then
            return false
        end
	end

    -- Requires a wall (to attach on)
    if not square:isWallSquareNW() then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        local northProps = adjacentSquareN:getProperties()
        if not northProps:Is(localIsoFlagType.WallW) then
            -- Check if the square to the west has a wall on the north
            local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
            if not adjacentSquareW then
                return false
            end

            local westProps = adjacentSquareN:getProperties()
            if not westProps:Is(localIsoFlagType.WallN) then
                return false
            end
        end
    end

    -- Requires no existing drain pipe
    if utils:hasVerticalPipeOnTile(square) then
        return false
    end

    -- Requires another vertical pipe or drain pipe below
    local below = square:getCell():getGridSquare(square:getX(), square:getY(), z - 1)
    if not below then
        return false
    end

    local i, belowPipe, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(below, enums.pipeType.vertical)
    if not belowPipe or foundSpriteCategory ~= enums.pipeType.vertical then
        i, belowPipe, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(below, enums.pipeType.drain)
        if not belowPipe or foundSpriteCategory ~= enums.pipeType.drain then
            return false
        end
    end
    

    -- Check alignment of pipes through sprite name
    local tileInfoSprite = params.tileInfo:getSpriteName();
    local pipeDef = enums.pipes[tileInfoSprite]
    if not pipeDef then
        return false
    end

    local sharedPositionPipes = enums.pipeAtlas.position[pipeDef.position]
    if not sharedPositionPipes then
        return false
    end

    local belowPipeDef = enums.pipes[spriteName]
    if not belowPipeDef then
        return false
    end

    if belowPipeDef.position ~= pipeDef.position then
        return false
    end

	return true
end

function FG_BuildRecipeCode.pipe.gutter.OnCreate(object)
    -- TODO if anything needs to be done on creation
    utils:modPrint("Gutter pipe on create func: "..tostring(object))
    return object
end

function FG_BuildRecipeCode.pipe.gutter.OnIsValid(params)
    local square = params.square

    -- Requires being outside
    if not square:isOutside() then
        return false
    end

    -- Requires a wall (to attach on)
    if not square:isWallSquareNW() then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        local northProps = adjacentSquareN:getProperties()
        if not northProps:Is(localIsoFlagType.WallW) then
            -- Check if the square to the west has a wall on the north
            local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
            if not adjacentSquareW then
                return false
            end

            local westProps = adjacentSquareW:getProperties()
            if not westProps:Is(localIsoFlagType.WallN) then
                return false
            end
        end
    end

    -- Requires no existing gutter pipe on tile
    if utils:hasGutterPipeOnTile(square) then
        return false
    end

	return true
end