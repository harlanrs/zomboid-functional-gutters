if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local DrainPipeService = BasePipeServiceInterface:derive("DrainPipeService")

local localIsoDirections = IsoDirections
local localIsoFlagType = IsoFlagType

function DrainPipeService:isObjectType(object)
    return utils:isDrainPipe(object)
end

function DrainPipeService:onCreate(object)
    utils:modPrint("Drain pipe on create func: "..tostring(object))
end

function DrainPipeService:onIsValid(buildParams)
    local square = buildParams.square
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

    -- Requires no existing drain pipe within x tiles (with caveat)
    local closeDrainPipe = isoUtils:findPipeInRadius(square, 6, enums.pipeType.drain)
    if closeDrainPipe then
        -- Check if drain pipe in on the same pre-made building as the selected drain square
        -- Allows for placing drains closer together when they are part of different nearby buildings
        local buildingDef = isoUtils:getAttachedBuilding(square)
        local closeDrainPipeBuildingDef = isoUtils:getAttachedBuilding(closeDrainPipe:getSquare())
        if not buildingDef and not closeDrainPipeBuildingDef then
            -- Neither are a building
            return false
        end

        if buildingDef and closeDrainPipeBuildingDef then
            -- Both are buildings - check if they are the same building
            if buildingDef:getID() == closeDrainPipeBuildingDef:getID() then
                return false
            end
            -- Different buildings - allow for closer placement
        end

        -- ELSE
        -- One is pre-built and the other is player-built
        -- Allow for closer placement
    end

	return true
end


return DrainPipeService
