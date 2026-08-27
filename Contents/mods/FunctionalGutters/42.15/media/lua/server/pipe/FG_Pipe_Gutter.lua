local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local BasePipeServiceInterface = require("pipe/FG_Pipe_Base")

local GutterPipeService = BasePipeServiceInterface:derive("GutterPipeService")

function GutterPipeService:isObjectType(object)
    return utils:isGutterPipe(object)
end

function GutterPipeService:onCreate(createParams)
    local object = createParams.thumpable
    utils:modPrint("Gutter pipe on create func: " .. tostring(object))
    -- Bug in vanilla atm where tools that are 'drained' when building an iso thumpable object are added to the object's mod data
    -- The issue is that the consumed build inputs added to the object's mod data are also used to determine what items can be returned on scrap
    -- This leads to a weird bug in vanilla where scrapping a metal iso object can return a full blowtorch and/or welding rods
    local modData = object:getModData()
    modData["need:Base.BlowTorch"] = nil
    modData["need:Base.WeldingRods"] = nil

    -- Swap IsoThumpable object for IsoObject
    -- NOTE: dismantle will not use "need:" mod data since object is no longer an IsoThumpable
    local sprite = object:getSprite()
    local sq = object:getSquare();
    local index = object:getObjectIndex()
    local javaObject = IsoObject.new(sq:getCell(), sq, sprite)
    local entityScript = utils:getObjectEntityScript(object)
    if entityScript then
        local gameEntityScript = entityScript
        local isFirstTimeCreated = true
        GameEntityFactory.CreateIsoObjectEntity(javaObject, gameEntityScript, isFirstTimeCreated)
    end

    if object:getSquare() ~= nil then
        object:removeFromWorld();
        object:removeFromSquare();
        object:setSquare(nil);
    end

    sq:AddSpecialObject(javaObject, index)

    return { replaceObject = true, object = javaObject };
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
    if not isoUtils:hasValidPipeAttachment(square) and not isoUtils:hasValidFloorAttachment(square) then
        -- Handle special placement rules for small corner gutters
        if tileInfoSprite == 'gutter_01_4' or tileInfoSprite == 'gutter_01_11' then
            if not isoUtils:hasValidFloorAttachmentNW(square) then
                return false
            end
        else
            return false
        end
    end

    return true
end

return GutterPipeService
