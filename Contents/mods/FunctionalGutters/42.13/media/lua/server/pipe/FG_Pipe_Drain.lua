local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local DrainPipeService = BasePipeServiceInterface:derive("DrainPipeService")

local localIsoDirections = IsoDirections

function DrainPipeService:isObjectType(object)
    return utils:isDrainPipe(object)
end

function DrainPipeService:onCreate(createParams)
    local object = createParams.thumpable
    -- Bug in vanilla atm where tools that are 'drained' when building an iso thumpable object are added to the object's mod data
    -- The issue is that the consumed build inputs added to the object's mod data are also used to determine what items can be returned on scrap
    -- This leads to a weird bug in vanilla where scrapping a metal iso object can return a full blowtorch and/or welding rods
    local modData = object:getModData()
    modData["need:Base.BlowTorch"] = nil
    modData["need:Base.WeldingRods"] = nil
    modData[enums.modDataKey.drainCleared] = true
end

function DrainPipeService:onIsValid(buildParams)
    local square = buildParams.square
    local z = square:getZ()

    -- Requires being outside (so any connected collector can still receive rain)
    if not square:isOutside() then
        return false
    end

    -- Requires a floor (so any collectors can be placed on top)
    if z > 0 and not square:hasFloor() then
        return false
    end

    -- Requires a wall/pole (to attach on)
    if not isoUtils:hasWallNW(square) and not isoUtils:hasPole(square) then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        if not isoUtils:hasWallW(adjacentSquareN) and not isoUtils:hasPole(adjacentSquareN) then
            -- Check if the square to the west has a wall on the north
            local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
            if not adjacentSquareW then
                return false
            end

            if not isoUtils:hasWallN(adjacentSquareW) and not isoUtils:hasPole(adjacentSquareW) then
                -- Need to check adjacent north-west square for pole directly
                local adjacentSquareNW = square:getAdjacentSquare(localIsoDirections.NW)
                if not adjacentSquareNW then
                    return false
                end
                if not isoUtils:hasPole(adjacentSquareNW) then
                    return false
                end
            end
        end
    end

    -- Requires no existing drain pipe
    if utils:isDrainPipeSquare(square) then
        return false
    end

    return true
end

return DrainPipeService
