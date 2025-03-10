local enums = require("FG_Enums")
local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")
local FluidContainerService = require("FG_Service_FluidContainer")
local TroughService = require("FG_Service_Trough")

local gutterService = {}

gutterService.containerServiceMap = {
    [enums.containerType.fluidContainer] = FluidContainerService,
    [enums.containerType.trough] = TroughService,
}

function gutterService:getContainerService(containerObject)
    -- Filter out IsoWorldInventoryObjects for now
    if instanceof(containerObject, "IsoWorldInventoryObject") then
        utils:modPrint("IsoWorldInventoryObjects not supported yet")
        return nil
    end

    if TroughService:isObjectType(containerObject) then
        return TroughService
    elseif FluidContainerService:isObjectType(containerObject) then
        return FluidContainerService
    end

    utils:modPrint("No service interface found for container object: "..tostring(containerObject))
    return nil
end

function gutterService:isValidContainerObject(containerObject)
    return self:getContainerService(containerObject) ~= nil
end

function gutterService:syncSquareModData(square)
    -- Avoid initializing mod data if we don't need to
    local squareHasModData = square:hasModData()
    local hasDrainPipe = utils:hasDrainPipeOnTile(square)

    if not squareHasModData and not hasDrainPipe then
        -- No mod data, no drain pipe, no worries
        return nil
    end

    -- Temp patch
    utils:patchModData(square, true)

    local squareModData = square:getModData()
    if hasDrainPipe then
        -- The square has a drain pipe - ensure the square's mod data reflects this
        utils:setModDataHasGutter(square, true)
    else
        if utils:getModDataHasGutter(square) then
            -- The square no longer has a drain pipe - ensure the square's mod data reflects this
            utils:setModDataHasGutter(square, nil)
        end
    end

    return squareModData
end

function gutterService:connectContainer(containerObject)
    local containerService = self:getContainerService(containerObject)
    if not containerService then
        return
    end

    containerService:connectContainer(containerObject)
 
    -- Temp patch
    utils:patchModData(containerObject, false)
end

function gutterService:disconnectContainer(containerObject)
    local containerService = self:getContainerService(containerObject)
    if not containerService then
        return
    end

    containerService:disconnectContainer(containerObject)
    
    -- Temp patch
    utils:patchModData(containerObject, false)
end

function gutterService:handleObjectPlacedOnTile(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    self:syncSquareModData(square)
    if utils:getModDataHasGutter(square) then
        utils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square))
    end
    -- Can't properly clean up all object types on initial pickup so have to check here
    if utils:getModDataIsGutterConnected(placedObject) then
        utils:modPrint("Object marked as having a gutter after placing: "..tostring(placedObject))
        self:disconnectContainer(placedObject)
    end
end

function gutterService:handleObjectBuiltOnTile(square)
    -- React to the creation of a new iso object on a tile
    self:syncSquareModData(square)
    if utils:getModDataHasGutter(square) then
        utils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
    end
end

function gutterService:handleObjectRemovedFromTile(removedObject)
    -- React to the the removal of an object from a tile
    -- TODO look into how to require disconnecting from gutter before object can be picked up?
    local square = removedObject:getSquare()
    if square then
        self:syncSquareModData(square)
        if utils:getModDataHasGutter(square) then
            if troughUtils:isTrough(removedObject) then
                -- Troughs are a bit of a special case for the OnTileRemoved event:
                -- They currently have a method "ReplaceExistingObject" invoked immediately on placement/build
                -- which removes & replaces the existing object causing the OnTileRemoved event to be triggered (potentially multiple times for multi-tile troughs)
                utils:modPrint("Animal trough removed from tile: "..tostring(removedObject))
                return
            end

            -- Reset the removed object's rain factor if it was connected to a gutter
            -- NOTE: doesn't work if the object's FluidContainer is removed before the event is triggered
            utils:modPrint("Object removed from tile with gutter: "..tostring(removedObject))
            self:disconnectContainer(removedObject)
        end
    end
end

return gutterService