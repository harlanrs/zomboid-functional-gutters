if isClient() then return end

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local serviceUtils = require("FG_Utils_Service")
local troughUtils = require("FG_Utils_Trough")
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

local function loadTroughGlobalObject(object)
    -- Wrap load full trough function to trigger event if trough is on a drain pipe square
    local primaryTrough, secondaryTrough = globalObjectUtils:loadFullTrough(object)
    if not primaryTrough then
        return nil
    end

    local primaryTroughSquare = primaryTrough:getSquare()
    if utils:isDrainPipeSquare(primaryTroughSquare) then
        -- Primary trough is on drain pipe square
        triggerEvent(enums.modEvents.OnGutterTileUpdate, primaryTroughSquare)
    elseif secondaryTrough then
        local secondaryTroughSquare = secondaryTrough:getSquare()
        if utils:isDrainPipeSquare(secondaryTroughSquare) then
            -- Secondary trough is on drain pipe square
            triggerEvent(enums.modEvents.OnGutterTileUpdate, secondaryTroughSquare)
        end
    end
end

function GutterServerManager.OnIsoObjectBuilt(square, sprite)
    -- React to the creation of a new iso object on a tile
    local checkDrainPipes = false
    local triggerGutterTileUpdateEvent = false
    local squareModData = serviceUtils:syncSquarePipeModData(square)
    if utils:isAnyPipeSprite(sprite) then
        -- A pipe was built 
        checkDrainPipes = true
    end

    if utils:isDrainPipeSquare(square) then
        -- Object was built on a tile marked as having a gutter drain
        utils:modPrint("Object built on drain pipe tile")
        checkDrainPipes = true
        triggerGutterTileUpdateEvent = true
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
        -- Seek all nearby drain pipes to update the rain factor
        local drainPipes = serviceUtils:getLocalDrainPipes3D(square, 10, 1)
        if drainPipes then
            for i=1, #drainPipes do
                local drainPipe = drainPipes[i]
                local connectedCollector = utils:getConnectedCollectorFromSquare(drainPipe:getSquare())
                if connectedCollector then
                    -- Re-run connect logic to update the rain factor for already connected collectors
                    gutterService:connectCollector(connectedCollector)
                    triggerGutterTileUpdateEvent = true
                end
            end
        end
    end

    if triggerGutterTileUpdateEvent then
        triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
    end
end

function GutterServerManager.OnIsoObjectPlaced(placedObject)
    -- React to the placement of an existing iso object on a tile
    local checkDrainPipes = false
    local triggerGutterTileUpdateEvent = false
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

    local squareProps = square:getProperties()
    if utils:isAnyPipeSquare(square, squareProps) then
        -- Object placed on a tile with at least one pipe
        checkDrainPipes = true

        if utils:isDrainPipeSquare(square, squareProps) then
            -- Object placed on a tile with a drain pipe
            utils:modPrint("Object placed on drain pipe tile")
            triggerGutterTileUpdateEvent = true
        end
    end

    if loadTroughGlobalObject(placedObject) then
        -- Trough was placed and converted to a global object
    elseif utils:getModDataIsGutterConnected(placedObject, nil) then
        -- Can't properly clean up all object types on pickup so have to check here for placement
        utils:modPrint("Cleaning up existing collector object mod data after placing: "..tostring(placedObject))
        gutterService:disconnectCollector(placedObject)
    end

    if checkDrainPipes then
        -- Seek all nearby drain pipes to update the rain factor
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
    end

    if triggerGutterTileUpdateEvent then
        triggerEvent(enums.modEvents.OnGutterTileUpdate, square)
    end
end

function GutterServerManager.OnIsoObjectRemoved(removedObject)
    -- React to the removal of an existing iso object on a tile
    local square = removedObject:getSquare()
    if not square then return end

    if serviceUtils:isWorldInventoryObject(removedObject) then
        -- Ignore IsoWorldInventoryObjects for now
        return
    end

    local checkDrainPipes = false
    local triggerGutterTileUpdateEvent = false
    local triggerSquare = square
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
                serviceUtils:syncSquarePipeModData(square)
            end
        end

        checkDrainPipes = true
    elseif utils:isDrainPipeSquare(square) then
        -- Object removed from a tile with a drain pipe
        utils:modPrint("Tile marked as having a gutter drain after removing object: "..tostring(square))
        checkDrainPipes = true
        triggerGutterTileUpdateEvent = true
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

    if troughUtils:isTroughObject(removedObject) then
        -- Explicitly checking for trough object type as removal event will be triggered when upgrading a trough to global object
        utils:modPrint("Trough object removed from square: "..tostring(square:getX())..","..tostring(square:getY())..","..tostring(square:getZ()))

        local drainSquare = serviceUtils:getDrainPipeSquareFromCollector(removedObject)
        if drainSquare then
            triggerSquare = drainSquare
            triggerGutterTileUpdateEvent = true
        end
    end

    if checkDrainPipes then
        utils:modPrint("Checking local drain pipes after object removed: "..tostring(square:getX())..", "..tostring(square:getY())..", "..tostring(square:getZ()))
        -- Seek all nearby drain pipes to update the rain factor
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
    end

    if triggerGutterTileUpdateEvent then
        triggerEvent(enums.modEvents.OnGutterTileUpdate, triggerSquare)
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

-- Testing to see if these are used yet
local function processTransaction(action, character, item, source, destination, args)
    utils:modPrint("Processing transaction: "..action)
end

Events.OnProcessTransaction.Add(processTransaction)

local function processAction(action, character, args)
    utils:modPrint("Processing action: "..action)
end

Events.OnProcessTransaction.Add(processAction)