local enums = require("FG_Enums")
local utils = require("FG_Utils")

local troughUtils = {}

local troughNorthFieldIndex = nil
local localFeedingTroughDef = FeedingTroughDef

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

function troughUtils:isPrimaryTroughSprite(troughSpriteName)
    for i,def in pairs(localFeedingTroughDef) do
		if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
			return true
		end
    end

    return false
end

function troughUtils:getPrimaryTroughFromDef(troughObject)
    local troughSpriteName = troughObject:getSpriteName()

    for i,def in pairs(localFeedingTroughDef) do
        if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
            -- Provided troughObject is the primary trough
            return troughObject
        end

        if def.sprite2 == troughSpriteName or def.spriteNorth2 == troughSpriteName then
            local north = def.spriteNorth2 == troughSpriteName
            local x, y, z = utils:getSquare2PosReverse(troughObject:getSquare(), north)
            local primarySquare = getCell():getGridSquare(x, y, z)
            local primarySpriteName = north and def.spriteNorth1 or def.sprite1
            local primaryTrough = utils:getSpecificIsoObjectFromSquare(primarySquare, primarySpriteName)
            if not primaryTrough then
                return nil
            end

            return primaryTrough
        end
    end

    utils:modPrint("Primary trough not found for: "..tostring(troughObject))
    return nil
end

function troughUtils:getSecondaryTroughFromDef(troughObject)
    local troughSpriteName = troughObject:getSpriteName()

    for i,def in pairs(localFeedingTroughDef) do
        if def.sprite2 == troughSpriteName or def.spriteNorth2 == troughSpriteName then
            -- Provided troughObject is the secondary trough
            return troughObject
        end

        if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
            local north = def.spriteNorth1 == troughSpriteName
            local x, y, z = utils:getSquare2Pos(troughObject:getSquare(), north)
            local secondarySquare = getCell():getGridSquare(x, y, z)
            local secondarySpriteName = north and def.spriteNorth2 or def.sprite2
            local secondaryTrough = utils:getSpecificIsoObjectFromSquare(secondarySquare, secondarySpriteName)
            if not secondaryTrough then
                return nil
            end

            return secondaryTrough
        end
    end

    utils:modPrint("Secondary trough not found for: "..tostring(troughObject))
    return nil
end

return troughUtils