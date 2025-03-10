local utils = require("FG_Utils")

local troughUtils = {}

local troughNorthFieldIndex = nil

function troughUtils:isTrough(isoObject)
    -- TODO also check for sprite name against trough sprites list
    -- Troughs have weird behavior when they are picked up and then placed back down
    -- They become an isoObject instead of an IsoFeedingTrough until the game is reloaded
    return instanceof(isoObject, "IsoFeedingTrough")
end

function troughUtils:isTroughNorth(troughObject)
    if troughNorthFieldIndex == nil then 
        troughNorthFieldIndex = utils:getClassFieldIndex(troughObject, "north")
        utils:modPrint("Set trough field 'north' index: "..tostring(troughNorthFieldIndex))
    end
    local field = getClassField(troughObject,troughNorthFieldIndex)
    local value = getClassFieldVal(troughObject, field)
    return value
end

function troughUtils:isPrimaryTrough(isoObject)
    return isoObject:getLinkedX() == 0 and isoObject:getLinkedY() == 0
end

function troughUtils:getOtherTroughSquare(troughObject)
    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if not linkedX or not linkedY or (linkedX == 0 and linkedY == 0) then
        return nil
    end

    return getSquare(linkedX, linkedY, troughObject:getSquare():getZ())
end

function troughUtils:getTroughFromSquare(square)
    local luaTroughObject = CFeedingTroughSystem.instance:getLuaObjectOnSquare(square)
    if not luaTroughObject then
        return nil
    end

    return luaTroughObject:getIsoObject()
end

function troughUtils:getTroughObjectFromPos(x, y, z)
    local square = getCell():getGridSquare(x, y, z);
    return self:getTroughFromSquare(square)
end

function troughUtils:verifyLinkedTroughs(primaryTroughObject, secondaryTroughObject)
    local primarySquare = primaryTroughObject:getSquare()
    local linkedX = secondaryTroughObject:getLinkedX()
    local linkedY = secondaryTroughObject:getLinkedY()
    if linkedX and linkedY and linkedX == primarySquare:getX() and linkedY == primarySquare:getY() then
        return true
    end

    return false
end

function troughUtils:getPrimaryTroughObject(troughObject)
    -- Multi-tile troughs have:
    -- * a single functional fluid container associated with the 'primary' object/tile
    -- * a single 'shadow' fluid container on the 'secondary' object/tile used to direct context over to the primary object (even referenced as the 'slave' object in the PZ code)
    --
    -- Together these allow interactions with the entire iso object as a single unit.
    -- We want to make sure to always interact with the primary object's fluid container
    -- and the 'primary' object is the one the doesn't have linkedX or linkedY set
    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if linkedX and linkedY and linkedX ~= 0 and linkedY ~= 0 then
        -- The object is the secondary object in a multi-tile trough
        local primaryTroughObject = self:getTroughObjectFromPos(linkedX, linkedY, troughObject:getSquare():getZ())
        if primaryTroughObject == nil then
            utils:modPrint("Primary trough object not found for: "..tostring(troughObject))
            return nil
        end

        return primaryTroughObject
    end

    return troughObject
end

function troughUtils:getSecondaryTroughObject(troughObject)
    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if linkedX and linkedY and linkedX ~= 0 and linkedY ~= 0 then
        -- Provided troughObject is the non-primary in a multi-tile trough
        utils:modPrint("Secondary trough passed in as param: "..tostring(troughObject))
        return troughObject
    end

    local north = self:isTroughNorth(troughObject)
    local troughSquare = troughObject:getSquare()
    local secondaryTroughSquare = utils:getSquare2(troughSquare, north)
    local secondaryTroughObject = self:getTroughFromSquare(secondaryTroughSquare)
    if not secondaryTroughObject or not self:verifyLinkedTroughs(troughObject, secondaryTroughObject) then
        utils:modPrint("Secondary trough not found on square from getSquare2Pos: "..tostring(secondaryTroughSquare))
        return nil
    end

    return secondaryTroughObject
end

return troughUtils