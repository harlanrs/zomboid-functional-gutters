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

    triggerEvent(enums.modEvents.OnGutterTileUpdate, collectorObject:getSquare())
end

function GutterCommands.disconnectCollector(args)
    local collectorObject = utils:parseObjectCommandArgs(args)
    if not collectorObject then
        return
    end

    gutterService:disconnectCollector(collectorObject)

    triggerEvent(enums.modEvents.OnGutterTileUpdate, collectorObject:getSquare())
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
    -- elseif module == "object" and command == "OnDestroyIsoThumpable" then
    --     -- Handle scrap event for IsoThumpable if it is used to remove gutter objects
    --     -- So we can directly place materials on the ground instead of relying on base scrap logic
    --     -- This is a workaround for default moveable behavior not satisfying our needs
    --     -- So we force players to scrap the object and rebuild instead
    --     -- sendClientCommand(_character, 'object', 'OnDestroyIsoThumpable', args)
    end
end

function GutterServerManager.OnIsoObjectBuilt(square, sprite)
    -- React to the creation of a new iso object on a tile
    -- NOTE: param is square not the object itself
    serviceUtils:syncSquareModData(square, nil)
    local squareProps = square:getProperties()
    if utils:checkPropIsAnyPipe(square, squareProps) then
        if utils:isAnyPipeSprite(sprite) then
            -- A pipe was built 
            if utils:checkPropIsDrainPipe(square, squareProps) then
                -- Get the connected collector (if any) from the drain pipe square
                local connectedCollector = utils:getConnectedCollectorFromSquare(square)
                if connectedCollector then
                    -- Re-evaluate the rain factor for the connected collector
                    gutterService:connectCollector(connectedCollector)
                end
            else
                -- Non-drain pipe square but still a part of a gutter segment. 
                -- Seek all nearby drain pipes to update the rain factor
                local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
                if drainPipes then
                    for i=1, #drainPipes do
                        local drainPipe = drainPipes[i]
                        local connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                        if connectedCollector then
                            gutterService:connectCollector(connectedCollector)
                        end
                    end
                end
            end
        end

        utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
        triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquareModData(square, nil)
    if squareModData and utils:getModDataHasGutter(square, squareModData) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))
        triggerEvent(enums.modEvents.OnGutterTileUpdate, square) -- TODO is this too early to trigger?
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
        if utils:isAnyPipe(removedObject) then
            -- Cleanup square's mod data when any pipes are removed
            utils:modPrint("Pipe object removed from square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))

            -- Check if there is a connected collector on the tile
            local connectedCollector = utils:getConnectedCollectorFromSquare(square)
            if connectedCollector then
                if utils:isDrainPipe(removedObject) then
                    -- A drain pipe was removed so disconnect the collector
                    utils:modPrint("Disconnecting collector after drain pipe was removed: "..tostring(connectedCollector:getName()))
                    gutterService:disconnectCollector(connectedCollector)
                    serviceUtils:syncSquareModData(square, true)
                else
                    -- A non-drain pipe was removed update the connected collector's rain factor
                    -- NOTE: connect collector will re-crawl the gutter system and update the rain factor
                    utils:modPrint("Re-evaluating collector rain factor after pipe was removed: "..tostring(connectedCollector:getName()))
                    gutterService:connectCollector(connectedCollector)
                end
            else
                -- A pipe was removed but not directly on the tile with a collector
                -- Trigger a recalc of the rain factor for any connected collectors to nearby drain pipes
                local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
                if drainPipes then
                    for i=1, #drainPipes do
                        local drainPipe = drainPipes[i]
                        connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                        if connectedCollector then
                            utils:modPrint("Re-evaluating collector rain factor after pipe was removed: "..tostring(connectedCollector:getName()))
                            gutterService:connectCollector(connectedCollector)
                        end
                    end
                end
            end

            triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
        elseif utils:checkPropIsDrainPipe(square) then
            utils:modPrint("Tile marked as having a gutter drain after removing object: "..tostring(square))
            triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
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
