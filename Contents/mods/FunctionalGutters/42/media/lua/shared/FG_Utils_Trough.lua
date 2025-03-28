local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")

local troughUtils = {}

local troughNorthFieldIndex = nil
local localFeedingTroughDef = FeedingTroughDef

---Checks sprite name against a list of known trough sprites
---@param spriteName any
---@return boolean
function troughUtils:isTroughSprite(spriteName)
    for _, troughSprite in ipairs(enums.troughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

---@param spriteName any
---@return boolean
function troughUtils:isSingleTileTroughFromSprite(spriteName)
    for _, troughSprite in ipairs(enums.smallTroughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

---Checks for specific IsoFeedingTrough instance type
---@param object IsoObject
---@return boolean
function troughUtils:isTroughObject(object)
    return instanceof(object, "IsoFeedingTrough")
end

-- Check if object is either an IsoFeedingTrough or has a trough sprite
---@param object IsoObject
---@return boolean
function troughUtils:isTrough(object)
    return self:isTroughObject(object) or self:isTroughSprite(object:getSpriteName())
end

---@param troughObject IsoFeedingTrough|IsoObject
---@return boolean
function troughUtils:isTroughNorth(troughObject)
    if troughNorthFieldIndex == nil then
        troughNorthFieldIndex = utils:getClassFieldIndex(troughObject, "north")
        utils:modPrint("Set trough field 'north' index: "..tostring(troughNorthFieldIndex))
    end
    local field = getClassField(troughObject,troughNorthFieldIndex)
    local value = getClassFieldVal(troughObject, field)
    return value
end

---@param troughObject IsoFeedingTrough|IsoObject
---@return boolean
function troughUtils:isSecondaryTrough(troughObject)
    return troughObject:getLinkedX() > 0 and troughObject:getLinkedY() > 0
end

---@param troughObject IsoFeedingTrough|IsoObject
---@return boolean
function troughUtils:isPrimaryTrough(troughObject)
    return not self:isSecondaryTrough(troughObject)
end

---@param troughSpriteName string
---@return boolean
function troughUtils:isPrimaryTroughSprite(troughSpriteName)
    for _, def in pairs(localFeedingTroughDef) do
		if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
			return true
		end
    end

    return false
end

---@param troughObject IsoFeedingTrough|IsoObject
---@return IsoFeedingTrough|IsoObject|nil primaryTrough
function troughUtils:getPrimaryTrough(troughObject)
    local troughSpriteName = troughObject:getSpriteName()

    for _, def in pairs(localFeedingTroughDef) do
        if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
            -- Provided troughObject is the primary trough
            return troughObject
        end

        if def.sprite2 == troughSpriteName or def.spriteNorth2 == troughSpriteName then
            local north = def.spriteNorth2 == troughSpriteName
            local x, y, z = isoUtils:getSquare2PosReverse(troughObject:getSquare(), north)
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

---@param troughObject IsoFeedingTrough|IsoObject
---@return IsoFeedingTrough|IsoObject|nil secondaryTrough
function troughUtils:getSecondaryTrough(troughObject)
    local troughSpriteName = troughObject:getSpriteName()

    for _, def in pairs(localFeedingTroughDef) do
        if def.sprite2 == troughSpriteName or def.spriteNorth2 == troughSpriteName then
            -- Provided troughObject is the secondary trough
            return troughObject
        end

        if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
            local north = def.spriteNorth1 == troughSpriteName
            local x, y, z = isoUtils:getSquare2Pos(troughObject:getSquare(), north)
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

---@param troughObject IsoFeedingTrough|IsoObject
---@return IsoFeedingTrough|IsoObject|nil otherTrough
function troughUtils:getOtherTroughObject(troughObject)
    local spriteName = troughObject:getSpriteName()

    if troughUtils:isSingleTileTroughFromSprite(spriteName) then
        return nil
    end

    if self:isPrimaryTroughSprite(spriteName) then
        return self:getSecondaryTrough(troughObject)
    end

    return self:getPrimaryTrough(troughObject)
end

return troughUtils