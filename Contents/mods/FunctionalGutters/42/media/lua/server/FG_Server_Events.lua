local enums = require("FG_enums")
local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local serviceUtils = require("FG_Utils_Service")
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

function GutterServerManager.OnIsoObjectBuilt(square)
    -- React to the creation of a new iso object on a tile
    -- NOTE: param is square not the object itself
    local squareModData = serviceUtils:syncSquareModData(square)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))
    end

    -- Fix vanilla bug/gap where troughs are not being converted to global objects on placement like they are on build & reload
    -- Causes some odd behavior that requires a reload for the trough to function properly even in vanilla
    local objectSpriteName = placedObject:getSpriteName()
    if troughUtils:isTroughSprite(objectSpriteName) then
        -- Ignore if this is already a global trough object
        if troughUtils:isTroughObject(placedObject) then return end

        -- Ignore if this is a secondary trough
        -- Due to order of operations, the secondary trough's sprite is placed before the primary trough's sprite 
        -- so we need to wait for the primary trough to be placed before upgrading them both together
        if not troughUtils:isPrimaryTroughSprite(objectSpriteName) then
            return
        end

        local success = troughUtils:upgradeTroughToGlobalObject(placedObject)
        if not success then
            utils:modPrint("Failed to convert placed object to global trough: "..tostring(placedObject))
            return
        end

        return
    end

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

    GutterServerManager.OnIsoObjectBuilt(square)
end

Events.OnObjectAdded.Add(GutterServerManager.OnIsoObjectPlaced)

Events.OnClientCommand.Add(GutterServerManager.OnClientCommand)