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
    end
end

function GutterServerManager.OnIsoObjectBuilt(square, sprite)
    -- React to the creation of a new iso object on a tile
    local checkDrainPipes = false
    local squareModData = serviceUtils:syncSquarePipeModData(square)
    if utils:isAnyPipeSprite(sprite) then
        -- A pipe was built 
        checkDrainPipes = true
    end

    if utils:getModDataIsRoofSquare(square, squareModData) then
        -- Object was built on a square previously marked as a valid roof tile
        serviceUtils:syncSquareRoofModData(square, squareModData)
        if not utils:getModDataIsRoofSquare(square, squareModData) then
            -- The square is no longer a roof tile so re-crawl the gutter system
            checkDrainPipes = true
        end
    end

    if checkDrainPipes then
        utils:modPrint("Checking local drain pipes after object built: "..tostring(square:getX())..", "..tostring(square:getY())..", "..tostring(square:getZ()))
        -- Seek all nearby drain pipes to update the rain factor
        local triggerGutterTileUpdateEvent = false
        local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
        if drainPipes then
            for i=1, #drainPipes do
                local drainPipe = drainPipes[i]
                local connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                if connectedCollector then
                    gutterService:connectCollector(connectedCollector)
                    triggerGutterTileUpdateEvent = true
                end
            end
        end

        if triggerGutterTileUpdateEvent then
            triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
        end
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local checkDrainPipes = false
    local square = placedObject:getSquare()
    local squareModData = serviceUtils:syncSquarePipeModData(square)
    if squareModData then
        if utils:getModDataIsRoofSquare(square, squareModData) then
            -- Check if the square roof tile is still 'valid'
            serviceUtils:syncSquareRoofModData(square, squareModData)
            if not utils:getModDataIsRoofSquare(square, squareModData) then
                -- The square is no longer a roof tile so re-crawl the gutter system
                utils:modPrint("Tile no long valid roof square after placing object: "..tostring(square))
                checkDrainPipes = true
            end
        end
    end

    if utils:isAnyPipeSquare(square) then
        -- Object placed on a tile with a pipe
        checkDrainPipes = true
    end

    -- TODO cleanup trough logic
    -- Check if the placed object is a trough and convert it to a global object if necessary
    if globalObjectUtils:loadFullTrough(placedObject) then
        -- Trough was placed and converted to a global object
    elseif utils:getModDataIsGutterConnected(placedObject, nil) then
        -- Can't properly clean up all object types on pickup so have to check here for placement
        utils:modPrint("Cleaning up existing object mod data after placing: "..tostring(placedObject))
        gutterService:disconnectCollector(placedObject)
    end

    if checkDrainPipes then
        utils:modPrint("Checking local drain pipes after object placed: "..tostring(square:getX())..", "..tostring(square:getY())..", "..tostring(square:getZ()))
        -- Seek all nearby drain pipes to update the rain factor
        local triggerGutterTileUpdateEvent = false
        local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
        if drainPipes then
            for i=1, #drainPipes do
                local drainPipe = drainPipes[i]
                local connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                if connectedCollector then
                    gutterService:connectCollector(connectedCollector)
                    triggerGutterTileUpdateEvent = true
                end
            end
        end

        if triggerGutterTileUpdateEvent then
            triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
        end
    end
end

function GutterServerManager.OnIsoObjectRemoved(removedObject)
    -- React to the removal of an existing iso object on a tile
    local square = removedObject:getSquare()
    if square then
        local checkDrainPipes = false
        if utils:isAnyPipe(removedObject) then
            -- Cleanup square's mod data when any pipes are removed
            utils:modPrint("Pipe object removed from square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))

            -- Check if the drainpipe was the removed object
            if utils:isDrainPipe(removedObject) then
                local connectedCollector = utils:getConnectedCollectorFromSquare(square)
                if connectedCollector then
                    -- A drain pipe was removed so disconnect the collector
                    utils:modPrint("Disconnecting collector after drain pipe was removed: "..tostring(connectedCollector:getName()))
                    gutterService:disconnectCollector(connectedCollector)
                    serviceUtils:syncSquarePipeModData(square, true)
                end
            end

            checkDrainPipes = true
        elseif utils:isDrainPipeSquare(square) then
            utils:modPrint("Tile marked as having a gutter drain after removing object: "..tostring(square))
            checkDrainPipes = true
        end

        local squareModData = square:hasModData() and square:getModData() or nil
        if utils:getModDataIsRoofSquare(square, squareModData) then
            -- Check if the square roof tile is still 'valid'
            serviceUtils:syncSquareRoofModData(square, squareModData)
            if not utils:getModDataIsRoofSquare(square, squareModData) then
                -- The square is no longer a roof tile so re-crawl the gutter system
                utils:modPrint("Tile no long valid roof square after removing object: "..tostring(square))
                checkDrainPipes = true
            end
        end

        if checkDrainPipes then
            utils:modPrint("Checking local drain pipes after object removed: "..tostring(square:getX())..", "..tostring(square:getY())..", "..tostring(square:getZ()))
            -- Seek all nearby drain pipes to update the rain factor
            local triggerGutterTileUpdateEvent = false
            local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
            if drainPipes then
                for i=1, #drainPipes do
                    local drainPipe = drainPipes[i]
                    local connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                    if connectedCollector then
                        gutterService:connectCollector(connectedCollector)
                        triggerGutterTileUpdateEvent = true
                    end
                end
            end

            if triggerGutterTileUpdateEvent then
                triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
            end
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
