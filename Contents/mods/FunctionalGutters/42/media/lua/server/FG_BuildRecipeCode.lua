local enums = require("FG_Enums")
local utils = require("FG_Utils")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

FG_BuildRecipeCode = {}
FG_BuildRecipeCode.pipe = {
    drain = {},
    vertical = {},
    horizontal = {}
}

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

    -- TODO requires no existing drain pipe within x tiles - Nope would be too much of a performance hit here
    -- Will need to be handled elsewhere

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

    local i, belowPipe, spriteName, foundSpriteCategory = utils:getSpriteCategoryMemberOnTile(below)
    if not belowPipe or (foundSpriteCategory ~= enums.pipeType.vertical and foundSpriteCategory ~= enums.pipeType.drain) then
        return false
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