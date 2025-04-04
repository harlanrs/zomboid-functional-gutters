if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local GutterPipeService = BasePipeServiceInterface:derive("GutterPipeService")

local localIsoDirections = IsoDirections

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
    local tileInfoSprite = buildParams.tileInfo:getSpriteName();
    local pipeDef = enums.pipes[tileInfoSprite]

    if tileInfoSprite == "gutter_01_7" then
        -- Top-down build helper sprite so grab the 'real' square to check
        local z = square:getZ() - 1
        if z < 0 then
            return false
        end
        square = getCell():getGridSquare(square:getX(), square:getY() + 1, z)
        pipeDef = enums.pipes[enums.gutterAltBuildMap[tileInfoSprite]]
    elseif tileInfoSprite == "gutter_01_9" then
        -- Top-down build helper sprite so grab the 'real' square to check
        local z = square:getZ() - 1
        if z < 0 then
            return false
        end
        square = getCell():getGridSquare(square:getX() + 1, square:getY(), z)
        pipeDef = enums.pipes[enums.gutterAltBuildMap[tileInfoSprite]]
    elseif tileInfoSprite == "gutter_01_10" then
        -- Top-down build helper sprite so grab the 'real' square to check
        local z = square:getZ() - 1
        if z < 0 then
            return false
        end
        square = getCell():getGridSquare(square:getX() + 1, square:getY() + 1, z)
        pipeDef = enums.pipes[enums.gutterAltBuildMap[tileInfoSprite]]
    elseif tileInfoSprite == "gutter_01_11" then
        -- Top-down build helper sprite so grab the 'real' square to check
        local z = square:getZ() - 1
        if z < 0 then
            return false
        end
        square = getCell():getGridSquare(square:getX() + 1, square:getY() + 1, z)
        pipeDef = enums.pipes[enums.gutterAltBuildMap[tileInfoSprite]]
    end

    if not square then
        return false
    end

    if not pipeDef then
        return false
    end

    -- Requires being outside
    if not square:isOutside() then
        return false
    end

    -- Requires no existing gutter pipe on tile
    if utils:isGutterPipeSquare(square) then
        return false
    end

    -- Requires not having stairs on the tile
    if square:HasStairs() then
        return false
    end

    -- Requires a wall/pole on same level or floor on level above (to attach on)
    -- TODO check if there is a garage door section
    if not isoUtils:hasWallNW(square) and not utils:getSpecificIsoObjectFromSquare(square, enums.woodenPoleSprite) then
        -- Check if the square to the north has a wall on the west
        local adjacentSquareN = square:getAdjacentSquare(localIsoDirections.N)
        if not adjacentSquareN then
            return false
        end

        if not isoUtils:hasWallW(adjacentSquareN) then
            -- Check if there is a floor on the adjacent square north + 1 z level
            local adjacentSquareNUp = getCell():getGridSquare(adjacentSquareN:getX(), adjacentSquareN:getY(), adjacentSquareN:getZ() + 1)
            if not adjacentSquareNUp then
                return false
            end

            if not adjacentSquareNUp:hasFloor() then
                -- Check if the square to the west has a wall on the north
                local adjacentSquareW = square:getAdjacentSquare(localIsoDirections.W)
                if not adjacentSquareW then
                    return false
                end

                if not isoUtils:hasWallN(adjacentSquareW) then
                    -- Check if there is a floor on the adjacent square west + 1 z level
                    local adjacentSquareWUp = getCell():getGridSquare(adjacentSquareW:getX(), adjacentSquareW:getY(), adjacentSquareW:getZ() + 1)
                    if not adjacentSquareWUp or not adjacentSquareWUp:hasFloor() then
                        return false
                    end
                end
            end
        end
    end

	return true
end

return GutterPipeService
