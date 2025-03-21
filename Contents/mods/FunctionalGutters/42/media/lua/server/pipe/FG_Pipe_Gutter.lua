if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local GutterPipeService = BasePipeServiceInterface:derive("GutterPipeService")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

function GutterPipeService:isObjectType(object)
    return utils:isGutterPipe(object)
end

function GutterPipeService:onCreate(object)
    utils:modPrint("Gutter pipe on create func: "..tostring(object))
end

function GutterPipeService:onIsValid(buildParams)
    local square = buildParams.square

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

return GutterPipeService
