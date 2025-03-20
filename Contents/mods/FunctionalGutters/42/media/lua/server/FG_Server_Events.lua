if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local globalObjectUtils = require("FG_Utils_GlobalObject")
local gutterService = require("FG_Service")

local GutterServerManager = {}
local GutterCommands = {}

function GutterCommands.connectCollector(args)
    local collectorObject = utils:parseObjectCommandArgs(args)
    if not collectorObject then
        return
    end

    gutterService:connectCollector(collectorObject)
end

function GutterCommands.disconnectCollector(args)
    local collectorObject = utils:parseObjectCommandArgs(args)
    if not collectorObject then
        return
    end

    gutterService:disconnectCollector(collectorObject)
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
    local squareModData = serviceUtils:syncSquareModData(square, true) -- TODO maybe set full to nil 
    if squareModData then
        if utils:getModDataHasGutter(square, squareModData) then
            utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
            triggerEvent("OnGutterTileUpdate", square)
        end
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square, true) -- TODO maybe set full to nil 
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))
        triggerEvent("OnGutterTileUpdate", square) -- TODO is this too early to trigger?
    end

    -- Check if the placed object is a trough and convert it to a global object if necessary
    if globalObjectUtils:loadFullTrough(placedObject) then return end

    -- Can't properly clean up all object types on pickup so have to check here for placement
    if utils:getModDataIsGutterConnected(placedObject, nil) then
        utils:modPrint("Object marked as having a gutter after placing: "..tostring(placedObject))
        gutterService:disconnectCollector(placedObject)
    end
end

function GutterServerManager.OnIsoObjectRemoved(removedObject)
    -- React to the removal of an existing iso object on a tile
    local square = removedObject:getSquare()
    if square then
        -- TODO verify if the upgrade of IsoObject -> IsoThumpable when a pipe placed will trigger this event
        if utils:isAnyPipe(removedObject) then
            -- Cleanup square's mod data when any pipes are removed
            utils:modPrint("Pipe object removed from square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))
            local squareModData = serviceUtils:syncSquareModData(square, true) -- TODO maybe set full to nil
            -- TODO need to trigger a re-crawl of the pipe system to downscale a connected collector's rain factor 
            -- in case the removed pipe affects how much roof is connected to the gutter system
        end

        if utils:checkPropIsDrainPipe(square) then
            utils:modPrint("Tile marked as having a gutter drain after removing object: "..tostring(square))
            triggerEvent("OnGutterTileUpdate", square)
        end
    end
end

-- TODO re-evaluate if we can get this event from any other source beside having to wrap the function
local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso object from the build menu
    -- NOTE: using ISBuildIsoEntity:setInfo instead of ISBuildIsoEntity:create as it is possible for the create function to exit early unsuccessfully
    ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    GutterServerManager.OnIsoObjectBuilt(square, sprite)
end

Events.OnObjectAdded.Add(GutterServerManager.OnIsoObjectPlaced)

Events.OnTileRemoved.Add(GutterServerManager.OnIsoObjectRemoved)

Events.OnClientCommand.Add(GutterServerManager.OnClientCommand)
