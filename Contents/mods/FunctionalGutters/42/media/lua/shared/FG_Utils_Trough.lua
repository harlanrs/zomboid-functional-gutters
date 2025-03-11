local enums = require("FG_Enums")
local utils = require("FG_Utils")

local troughUtils = {}

local troughNorthFieldIndex = nil
local localCFeedingTroughSystem = CFeedingTroughSystem
local localSFeedingTroughSystem = SFeedingTroughSystem

function troughUtils:isTroughSprite(spriteName)
    for _, troughSprite in ipairs(enums.troughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

function troughUtils:isSingleTileTroughFromSprite(spriteName)
    for _, troughSprite in ipairs(enums.smallTroughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

function troughUtils:isTroughObject(isoObject)
    return instanceof(isoObject, "IsoFeedingTrough")
end

function troughUtils:isTrough(isoObject)
    -- NOTE: also checking sprite name due to special trough behavior:
    -- When troughs are picked up and then placed back down
    -- They become an isoObject instead of an IsoFeedingTrough until the game is reloaded
    return self:isTroughObject(isoObject) or self:isTroughSprite(isoObject:getSpriteName())
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

function troughUtils:isSecondaryTrough(isoObject)
    return isoObject:getLinkedX() > 0 and isoObject:getLinkedY() > 0
end

function troughUtils:isPrimaryTrough(isoObject)
    return not self:isSecondaryTrough(isoObject)
end

function troughUtils:getIsoObjectFromSquare(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if self:isTroughSprite(object:getSpriteName()) then
            return object
        end
    end
    return nil
end

function troughUtils:getTroughFromSquare(square)
    local luaTroughObject = nil
    if isServer() then
        luaTroughObject = localSFeedingTroughSystem.instance:getLuaObjectOnSquare(square)
    else
        luaTroughObject = localCFeedingTroughSystem.instance:getLuaObjectOnSquare(square)
    end

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

function troughUtils:getPrimaryTrough(troughObject)
    -- Multi-tile troughs have:
    -- * a single functional fluid container associated with the 'primary' object/tile
    -- * a single 'shadow' fluid container on the 'secondary' object/tile used to direct context over to the primary object (even referenced as the 'slave' object in the PZ code)
    --
    -- Together these allow interactions with the entire iso object as a single unit.
    -- We want to make sure to always interact with the primary object's fluid container
    -- and the 'primary' object is the one the doesn't have linkedX or linkedY set

    -- NOTE:
    -- in the situation that the troughObject is in its isoObject mode we can't rely on any of the IsoFeedingTrough methods such as getLinkedX or getLinkedY
    -- so we need to check the sprite name to determine if it is a single-tile trough
    if not self:isTroughObject(troughObject) then
        utils:modPrint("Trough object is not an IsoFeedingTrough yet: "..tostring(troughObject))
        if self:isSingleTileTroughFromSprite(troughObject:getSpriteName()) then
            return troughObject
        end

        return nil
    end

    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if linkedX and linkedY and linkedX > 0 and linkedY > 0 then
        local primaryTroughObject = self:getTroughObjectFromPos(linkedX, linkedY, troughObject:getSquare():getZ())
        if primaryTroughObject == nil then
            utils:modPrint("Primary trough object not found for: "..tostring(troughObject))
            return nil
        end

        return primaryTroughObject
    end

    return troughObject
end

function troughUtils:getSecondaryTrough(troughObject)
    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if linkedX and linkedY and linkedX > 0 and linkedY > 0 then
        utils:modPrint("Secondary trough passed in as param: "..tostring(troughObject))
        return troughObject
    end

    local north = self:isTroughNorth(troughObject)
    local primaryTroughSquare = troughObject:getSquare()
    local secondaryTroughSquare = utils:getSquare2(primaryTroughSquare, north, nil)
    local secondaryTroughObject = self:getTroughFromSquare(secondaryTroughSquare)
    if not secondaryTroughObject or not self:verifyLinkedTroughs(troughObject, secondaryTroughObject) then
        utils:modPrint("Secondary trough not found on square: "..tostring(secondaryTroughSquare))
        return nil
    end

    return secondaryTroughObject
end

function troughUtils:getOtherTroughSquare(troughObject)
    local linkedX = troughObject:getLinkedX()
    local linkedY = troughObject:getLinkedY()
    if linkedX and linkedY and linkedX > 0 and linkedY > 0 then
        return getCell():getGridSquare(linkedX, linkedY, troughObject:getSquare():getZ())
    end

    local north = self:isTroughNorth(troughObject)
    local troughSquare = troughObject:getSquare()
    return utils:getSquare2(troughSquare, north, nil)
end

function troughUtils:getOtherTrough(troughObject)
    if self:isSingleTileTroughFromSprite(troughObject:getSpriteName()) then
        return nil
    end

    if troughUtils:isPrimaryTrough(troughObject) then
        -- Load secondary
        local secondaryTrough = troughUtils:getSecondaryTrough(troughObject)
        if not secondaryTrough then
            utils:modPrint("Secondary trough not found for: "..tostring(troughObject))
            return nil
        end

        return secondaryTrough
    else
        -- Load primary
        local primaryTrough = troughUtils:getPrimaryTrough(troughObject)
        if not primaryTrough then
            utils:modPrint("Primary trough not found for: "..tostring(troughObject))
            return nil
        end

        return primaryTrough
    end
end

return troughUtils