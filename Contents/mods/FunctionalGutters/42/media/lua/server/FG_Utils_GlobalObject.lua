if isClient() then return end

local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

local globalObjectUtils = {}

local localFeedingTroughDef = FeedingTroughDef

function globalObjectUtils:removeExistingLuaObject(square)
    local troughSystem = SFeedingTroughSystem.instance
	local luaObject = troughSystem:getLuaObjectOnSquare(square)
	if luaObject then
		troughSystem:removeLuaObject(luaObject)
	end
end

-- TODO integrate FeedingTroughDef
function globalObjectUtils:replaceExistingTrough(isoObject)
    utils:modPrint('Upgrading IsoObject to IsoFeedingTrough: '..tostring(isoObject))
    local square = isoObject:getSquare()
    local spriteName = isoObject:getSprite():getName()
    local index = isoObject:getObjectIndex()
    self:removeExistingLuaObject(square)
    square:transmitRemoveItemFromSquare(isoObject)
    local north = true;
    if "location_farm_accesories_01_14" == spriteName or "location_farm_accesories_01_4" == spriteName or "location_farm_accesories_01_5" == spriteName or "location_farm_accesories_01_34" == spriteName or "location_farm_accesories_01_35" == spriteName then
        north = false;
    end
    isoObject = IsoFeedingTrough.new(square, spriteName, nil)
    isoObject:setNorth(north);
    if "location_farm_accesories_01_5" == spriteName then
        isoObject:setLinkedX(square:getX());
        isoObject:setLinkedY(square:getY() + 1);
    end
    if "location_farm_accesories_01_6" == spriteName then
        isoObject:setLinkedX(square:getX() + 1);
        isoObject:setLinkedY(square:getY());
    end
    if "location_farm_accesories_01_32" == spriteName then
        isoObject:setLinkedX(square:getX() + 1);
        isoObject:setLinkedY(square:getY());
    end
    if "location_farm_accesories_01_35" == spriteName then
        isoObject:setLinkedX(square:getX());
        isoObject:setLinkedY(square:getY() + 1);
    end
    isoObject:initWithDef();
    square:AddSpecialObject(isoObject, index)
    isoObject:transmitCompleteItemToClients()

    isoObject:checkOverlayFull();
    return isoObject
end

function globalObjectUtils:loadTrough(isoObject)
    if not troughUtils:isTroughObject(isoObject) then
        isoObject = self:replaceExistingTrough(isoObject)
    end

    -- Load the IsoFeedingTrough object into the global objects system
    utils:modPrint("Loading IsoFeedingTrough into global trough system: "..tostring(isoObject))
    SFeedingTroughSystem.instance:loadIsoObject(isoObject)
    return isoObject
end

-- TODO fixme
function globalObjectUtils:upgradeTroughToGlobalObject(primaryTrough)
    -- Use a single isoObject trough to upgrade full trough context to IsoFeedingTrough with global object references
    -- NOTE: param needs to be the primaryTrough not the secondaryTrough
    local troughSprite = primaryTrough:getSprite()
    local troughSpriteName = troughSprite:getName()
    local troughSquare = primaryTrough:getSquare()

    for i,def in pairs(localFeedingTroughDef) do
        if def.sprite1 == troughSpriteName or def.spriteNorth1 == troughSpriteName then
            -- Upgrade the primary trough IsoObject -> IsoFeedingTrough w/ global object
            local north = def.spriteNorth1 == troughSpriteName
            troughSquare:transmitRemoveItemFromSquare(primaryTrough)
            SFeedingTroughSystem.instance:addTrough(troughSquare, def, north, false)

            if def.sprite2 then
                local x, y, z = isoUtils:getSquare2Pos(troughSquare, north)
                local secondarySquare = getCell():getGridSquare(x, y, z)
                if not secondarySquare then
                    utils:modPrint("Secondary square not found for getSquare2Pos: "..tostring(x)..","..tostring(y)..","..tostring(z))
                    return false
                end

                local secondaryTrough = utils:getSpecificIsoObjectFromSquare(secondarySquare, def.sprite2)
                if not secondaryTrough then
                    utils:modPrint("Secondary trough not found on square: "..tostring(secondarySquare:getX())..","..tostring(secondarySquare:getY())..","..tostring(secondarySquare:getZ()))
                    return false
                end

                -- Upgrade the secondary trough IsoObject -> IsoFeedingTrough w/ global object
                secondarySquare:transmitRemoveItemFromSquare(secondaryTrough);
                SFeedingTroughSystem.instance:addTrough(secondarySquare, def, north, true)
            end

            return true
        end
    end

    utils:modPrint("Trough sprite name not found in FeedingTroughDef: "..tostring(troughSpriteName))
    return false
end

function globalObjectUtils:loadFullTrough(troughObject)
    local objectSpriteName = troughObject:getSpriteName()
    if not troughUtils:isTroughSprite(objectSpriteName) then return nil end

    -- Ignore if this is already a global trough object
    if troughUtils:isTroughObject(troughObject) then return nil end

    local primaryTrough = troughUtils:getPrimaryTroughFromDef(troughObject)
    if not primaryTrough then
        -- Primary through hasn't been placed yet
        return nil
    end

    -- If single tile primary trough, load it
    if troughUtils:isSingleTileTroughFromSprite(objectSpriteName) then
        return self:loadTrough(primaryTrough)
    end

    local secondaryTrough = troughUtils:getSecondaryTroughFromDef(troughObject)
    if not secondaryTrough then
        -- Secondary through hasn't been placed yet
        return nil
    end

    primaryTrough = self:loadTrough(primaryTrough)
    self:loadTrough(secondaryTrough)

    return primaryTrough
end

return globalObjectUtils