if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local serviceUtils = require("FG_Utils_Service")
local globalObjectUtils = require("FG_Utils_GlobalObject")
local gutterService = require("FG_Service")

local GutterServerManager = {}
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

function GutterServerManager.OnClientCommand(module, command, player, args)
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

function GutterServerManager.OnIsoObjectBuilt(square, sprite)
    -- React to the creation of a new iso object on a tile
    -- NOTE: param is square not the object itself
    local squareModData = serviceUtils:syncSquareModData(square, nil)
    if squareModData then
        if utils:getModDataHasGutter(square, squareModData) then
            utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
        end
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square, nil)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))
    end

    -- Check if the placed object is a trough and convert it to a global object if necessary
    if globalObjectUtils:loadFullTrough(placedObject) then return end

    -- Can't properly clean up all object types on pickup so have to check here for placement
    if utils:getModDataIsGutterConnected(placedObject, nil) then
        utils:modPrint("Object marked as having a gutter after placing: "..tostring(placedObject))
        gutterService:disconnectContainer(placedObject)
    end
end

local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso object from the build menu
    -- NOTE: using ISBuildIsoEntity:setInfo instead of ISBuildIsoEntity:create as it is possible for the create function to exit early unsuccessfully
    ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    GutterServerManager.OnIsoObjectBuilt(square, sprite)
end

Events.OnObjectAdded.Add(GutterServerManager.OnIsoObjectPlaced)

Events.OnClientCommand.Add(GutterServerManager.OnClientCommand)