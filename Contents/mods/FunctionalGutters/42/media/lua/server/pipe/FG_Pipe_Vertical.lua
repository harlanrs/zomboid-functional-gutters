if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local VerticalPipeService = BasePipeServiceInterface:derive("VerticalPipeService")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

function VerticalPipeService:isObjectType(object)
    return utils:isVerticalPipe(object)
end

function VerticalPipeService:onCreate(object)
    utils:modPrint("Vertical pipe on create func: "..tostring(object))
    -- Bug in vanilla atm where tools that are 'drained' when building an iso thumpable object are added to the object's mod data
    -- The issue is that the consumed build inputs added to the object's mod data are also used to determine what items can be returned on scrap
    -- This leads to a weird bug in vanilla where scrapping a metal iso object can return a full blowtorch and/or welding rods
    local modData = object:getModData()
    modData["need:Base.BlowTorch"] = nil
    modData["need:Base.WeldingRods"] = nil
end

function VerticalPipeService:onIsValid(buildParams)
    local square = buildParams.square
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

    -- Requires a wall/pole (to attach on)
    if not isoUtils:hasWallNW(square) and not utils:getSpecificIsoObjectFromSquare(square, enums.woodenPoleSprite) then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        if not isoUtils:hasWallW(adjacentSquareN) then
            -- Check if the square to the west has a wall on the north
            local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
            if not adjacentSquareW then
                return false
            end

            if not isoUtils:hasWallN(adjacentSquareW) then
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
    local tileInfoSprite = buildParams.tileInfo:getSpriteName();
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

return VerticalPipeService

