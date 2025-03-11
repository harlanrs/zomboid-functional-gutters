local enums = require("FG_enums")
local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local serviceUtils = require("FG_Utils_Service")
local mapObjectUtils = require("FG_Utils_MapObject")
local gutterService = require("FG_Service")

local GutterCommandManager = {}
local GutterCommands = {}

function GutterCommands.connectContainer(args)
    local containerObj = utils:parseObjectCommandArgs(args)
    if not containerObj then
        return
    end

    gutterService:connectContainer(containerObj)
end

function GutterCommands.disconnectContainer(args)
    local containerObj = utils:parseObjectCommandArgs(args)
    if not containerObj then
        return
    end

    gutterService:disconnectContainer(containerObj)
end

function GutterCommandManager.OnClientCommand(module, command, player, args)
	if module == enums.modName and GutterCommands[command] then
		local argStr = ''
		args = args or {}
		for k,v in pairs(args) do
			argStr = argStr..' '..k..'='..tostring(v)
		end
		utils:modPrint('Server received '..module..' '..command..' '..tostring(player)..argStr)
		GutterCommands[command](args)
	end
end

local function handleObjectBuiltOnTile(square)
    -- React to the creation of a new iso object on a tile
    local squareModData = serviceUtils:syncSquareModData(square)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
    end
end

local function handleObjectPlacedOnTile(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))

        if troughUtils:isTrough(placedObject) then
            if troughUtils:isTroughObject(placedObject) then return end
            -- Trigger the conversion to IsoFeedingTrough global object
            -- This is done automatically on build and on load but not on placement which can lead to odd behavior (both in vanilla and this mod)

            -- TODO Need to load the trough objects in the correct order from primary -> secondary
            -- TODO 
            -- TODO 

            if troughUtils:isSecondaryTrough(placedObject) then return end
            placedObject = mapObjectUtils:loadTrough(placedObject)
            utils:modPrint("Converted placed object to trough: "..tostring(placedObject))

            local otherTroughSquare = troughUtils:getOtherTroughSquare(placedObject)
            utils:modPrint("Other trough square: "..tostring(otherTroughSquare))
            if not otherTroughSquare then return end
            utils:modPrint(tostring(otherTroughSquare:getX()..","..otherTroughSquare:getY().. ","..otherTroughSquare:getZ()))
       
            -- Load the other trough
            local otherTrough = troughUtils:getIsoObjectFromSquare(otherTroughSquare)
            if not otherTrough then return end
            
            otherTrough = mapObjectUtils:loadTrough(otherTrough)
            utils:modPrint("Converted linked trough: "..tostring(otherTrough))
            return
        end
    end

    -- Can't properly clean up all object types on pickup so have to check here for placement
    if utils:getModDataIsGutterConnected(placedObject, nil) then
        utils:modPrint("Object marked as having a gutter after placing: "..tostring(placedObject))
        gutterService:disconnectContainer(placedObject)
    end
end

local function handleObjectRemovedFromTile(removedObject)
    -- React to the the removal of an object from a tile
    -- TODO look into how to require disconnecting from gutter before object can be picked up?
    local square = removedObject:getSquare()
    if square then
        local squareModData = serviceUtils:syncSquareModData(square)
        if squareModData and utils:getModDataHasGutter(square, squareModData) then
            if utils:getModDataIsGutterConnected(removedObject, nil) then
                if troughUtils:isTrough(removedObject) then
                    -- Troughs are a bit of a special case for the OnTileRemoved event:
                    -- They currently have a function "ReplaceExistingObject" invoked immediately on placement/build
                    -- which removes & replaces the existing object causing the OnTileRemoved event to be triggered (potentially multiple times for multi-tile troughs)
                    utils:modPrint("Animal trough removed from tile: "..tostring(removedObject))
                    return
                end

                -- Reset the removed object's rain factor if it was connected to a gutter
                -- NOTE: doesn't work if the object's FluidContainer is removed before the event is triggered
                utils:modPrint("Object removed from tile with gutter: "..tostring(removedObject))
                gutterService:disconnectContainer(removedObject)
            end
        end
    end
end

local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso entity object from the build menu
    -- NOTE: using ISBuildIsoEntity:setInfo instead of ISBuildIsoEntity:create as it is possible for the create function to exit early unsuccessfully
    ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    handleObjectBuiltOnTile(square)
end

Events.OnObjectAdded.Add(function(object)
    return handleObjectPlacedOnTile(object)
end)

Events.OnTileRemoved.Add(function(object)
    return handleObjectRemovedFromTile(object)
end)

Events.OnClientCommand.Add(GutterCommandManager.OnClientCommand)