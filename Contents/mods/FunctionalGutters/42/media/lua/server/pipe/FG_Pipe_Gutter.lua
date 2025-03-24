if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local GutterPipeService = BasePipeServiceInterface:derive("GutterPipeService")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

function GutterPipeService:isObjectType(object)
    return utils:isGutterPipe(object)
end

function GutterPipeService:onCreate(object)
    utils:modPrint("Gutter pipe on create func: "..tostring(object))
    -- Bug in vanilla atm where tools that are 'drained' when building an iso thumpable object are added to the object's mod data
    -- The issue is that the consumed build inputs added to the object's mod data are also used to determine what items can be returned on scrap
    -- This leads to a weird bug in vanilla where scrapping a metal iso object can return a full blowtorch and/or welding rods
    local modData = object:getModData()
    modData["need:Base.BlowTorch"] = nil
    modData["need:Base.WeldingRods"] = nil
end

function GutterPipeService:onIsValid(buildParams)
    local square = buildParams.square

    -- Requires being outside
    if not square:isOutside() then
        return false
    end

    -- Requires a wall (to attach on)
    if not isoUtils:hasWallNW(square) then
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

    -- Requires no existing gutter pipe on tile
    if utils:hasGutterPipeOnTile(square) then
        return false
    end

	return true
end

return GutterPipeService
