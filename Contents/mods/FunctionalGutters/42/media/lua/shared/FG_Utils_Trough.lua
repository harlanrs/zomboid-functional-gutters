local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")

local troughUtils = {}

local troughNorthFieldIndex = nil
local localFeedingTroughDef = FeedingTroughDef
local table_insert = table.insert

local function parseFeedingTroughDef()
    -- Iterate through FeedingTroughDef and create a map of trough sprites
    local troughSprites = table.newarray()
    local primaryTroughSprites = table.newarray()
    local smallTroughSprites = table.newarray()
    local northTroughSprites = table.newarray()

    for _, troughDef in pairs(localFeedingTroughDef) do
        local troughLength = #troughDef.spriteN -- NOTE: atm spriteN and spriteW are always the same length
        for i=1, troughLength do
            local spriteN = troughDef.spriteN[i]
            local spriteW = troughDef.spriteW[i]

            table_insert(troughSprites, spriteN)
            table_insert(troughSprites, spriteW)

            table_insert(northTroughSprites, spriteN)

            if i == 1 then
                -- The first sprite in the definition table is the primary trough sprite
                table_insert(primaryTroughSprites, spriteN)
                table_insert(primaryTroughSprites, spriteW)

                if troughLength == 1 then
                    -- Single tile troughs
                    table_insert(smallTroughSprites, spriteN)
                    table_insert(smallTroughSprites, spriteW)
                end
            end
        end
    end

    -- Override base enum references with the parsed trough sprites
    enums.troughSprites = troughSprites
    enums.primaryTroughSprites = primaryTroughSprites
    enums.smallTroughSprites = smallTroughSprites
    enums.northTroughSprites = northTroughSprites

    utils:modPrint("FeedingTroughDef parsed. Trough sprites: " .. tostring(#enums.troughSprites) .. ", Primary trough sprites: " .. tostring(#enums.primaryTroughSprites) .. ", Small trough sprites: " .. tostring(#enums.smallTroughSprites))
end

---Checks sprite name against a list of known trough sprites
---@param spriteName any
---@return boolean
function troughUtils:isTroughSprite(spriteName)
    local troughSprites = enums:getTroughSprites()
    for i=1, #troughSprites do
        local troughSprite = troughSprites[i]
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

---@param spriteName any
---@return boolean
function troughUtils:isSingleTileTroughFromSprite(spriteName)
    local smallTroughSprites = enums:getSmallTroughSprites()
    for i=1, #smallTroughSprites do
        local troughSprite =smallTroughSprites[i]
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
    end
    local field = getClassField(troughObject,troughNorthFieldIndex)
    local value = getClassFieldVal(troughObject, field)
    return value
end

---@param troughSpriteName string
---@return boolean
function troughUtils:isTroughSpriteNorth(troughSpriteName)
    local northTroughSprites = enums:getNorthTroughSprites()
    for i=1, #northTroughSprites do
        local northTroughSprite = northTroughSprites[i]
        if troughSpriteName == northTroughSprite then
            return true
        end
    end
    return false
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
        -- The 1st sprite in the definition table is the primary trough sprite
		if def.spriteN[1] == troughSpriteName or def.spriteW[1] == troughSpriteName then
			return true
		end
    end

    return false
end


---@param troughObject IsoFeedingTrough|IsoObject
---@return IsoFeedingTrough|IsoObject|nil primaryTrough
function troughUtils:getPrimaryTrough(troughObject)
    if self:isTroughObject(troughObject) then
        -- If troughObject is already an IsoFeedingTrough, return its master trough
        return troughObject:getMasterTrough()
    end

    -- Trough is still an IsoObject, so we need to find the primary trough based on its sprite name
    local troughSpriteName = troughObject:getSpriteName()
    if self:isPrimaryTroughSprite(troughSpriteName) then
        -- Provided troughObject is the primary trough
        return troughObject
    end

    -- Trough is a 'secondary' object, so we need to check the sprite grid
    local troughSprite = troughObject:getSprite()
    local troughSpriteGrid = troughSprite:getSpriteGrid()
    if not troughSpriteGrid then
        utils:modPrint("Trough sprite grid not found for: "..tostring(troughSpriteName))
        return nil
    end

    -- .getSpriteGridPosX(this.sprite);
    --         int var9 = var5.getSpriteGridPosY(this.sprite);
    --         this.setLinkedX(var1.getX() + var5.getWidth() - var8 - 1);
    --         this.setLinkedY(var1.getY() + var5.getHeight() - var9 - 1);

    for _, def in pairs(localFeedingTroughDef) do
        -- local troughLength = #def.spriteN -- NOTE: atm spriteN and spriteW are always the same length
        -- for i=1, troughLength do
        --     local spriteN = def.spriteN[i]
        --     local spriteW = def.spriteW[i]

        --     if spriteN == troughSpriteName or spriteW == troughSpriteName then
        --         -- Provided troughObject is the primary trough
        --         return troughObject
        --     end
        -- end

        if def.spriteN[1] == troughSpriteName or def.spriteW[1] == troughSpriteName then
            -- Provided troughObject is the primary trough
            return troughObject
        end

        if def.spriteN[2] == troughSpriteName or def.spriteW[2] == troughSpriteName then
            local north = def.spriteN[2] == troughSpriteName
            local x, y, z = isoUtils:getSquare2PosReverse(troughObject:getSquare(), north)
            local primarySquare = getCell():getGridSquare(x, y, z)
            local primarySpriteName = north and def.spriteN[1] or def.spriteW[1]
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

    -- TODO if IsoFeedingTroughs are automatically converted on build, we can simplify
    -- However, we now have triple & quad tile troughs so secondary troughs need to be handled differently

    for _, def in pairs(localFeedingTroughDef) do
        if def.spriteN[2] == troughSpriteName or def.spriteW[2] == troughSpriteName then
            -- Provided troughObject is the secondary trough
            return troughObject
        end

        if def.spriteN[1] == troughSpriteName or def.spriteW[1] == troughSpriteName then
            local north = def.spriteN[1] == troughSpriteName
            local x, y, z = isoUtils:getSquare2Pos(troughObject:getSquare(), north)
            local secondarySquare = getCell():getGridSquare(x, y, z)
            local secondarySpriteName = north and def.spriteN[2] or def.spriteW[2]
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

-- TODO MULTI - will need support for 3+ tile troughs
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

Events.OnInitWorld.Add(function()
    parseFeedingTroughDef()
end)

return troughUtils

-- TODO
-- Troughs now how 2 objects on each tile - 
-- 1 is the original IsoObject and the other is the converted IsoFeedingTrough
-- Appears to be a bug in 42.10