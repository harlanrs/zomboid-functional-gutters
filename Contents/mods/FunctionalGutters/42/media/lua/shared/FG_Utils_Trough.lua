local enums = require("FG_Enums")
local utils = require("FG_Utils")

local troughUtils = {}

local troughNorthFieldIndex = nil
local localFeedingTroughDef = FeedingTroughDef
-- local fluidType = FluidType

function troughUtils:isTroughSprite(spriteName)
    for _, troughSprite in ipairs(enums.troughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

function troughUtils:isTroughObject(isoObject)
    return instanceof(isoObject, "IsoFeedingTrough")
end

function troughUtils:isSingleTileTroughFromSprite(spriteName)
    for _, troughSprite in ipairs(enums.smallTroughSprites) do
        if spriteName == troughSprite then
            return true
        end
    end
    return false
end

function troughUtils:isTrough(isoObject)
    -- NOTE: also checking sprite name due to special trough behavior:
    --       when troughs are picked up and then placed back down,
    --       they become an isoObject instead of an IsoFeedingTrough until the game is reloaded
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

function troughUtils:removeExistingLuaObject(square)
    local troughSystem = SFeedingTroughSystem.instance
	local luaObject = troughSystem:getLuaObjectOnSquare(square)
	if luaObject then
		troughSystem:removeLuaObject(luaObject)
	end
end

-- TODO integrate FeedingTroughDef
function troughUtils:replaceExistingTrough(isoObject)
    if isClient() then return nil end

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

    -- Force the container to be a water container
    -- if isoObject:getContainer() then
    --     isoObject:addWater(fluidType.TaintedWater, 0.1)
    -- end

    isoObject:checkOverlayFull();
    return isoObject
end

function troughUtils:loadTrough(isoObject)
    if isClient() then return nil end
    if not troughUtils:isTroughObject(isoObject) then
        isoObject = troughUtils:replaceExistingTrough(isoObject)
    end

    -- Load the IsoFeedingTrough object into the global objects system
    utils:modPrint("Loading IsoFeedingTrough into global trough system: "..tostring(isoObject))
    SFeedingTroughSystem.instance:loadIsoObject(isoObject)
    return isoObject
end

-- TODO fixme
function troughUtils:upgradeTroughToGlobalObject(primaryTrough)
    -- Use a single isoObject trough to upgrade full trough context to IsoFeedingTrough with global object references
    -- NOTE: param needs to be the primaryTrough not the secondaryTrough
    if isClient() then return nil end
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
                local x, y, z = utils:getSquare2Pos(troughSquare, north)
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

return troughUtils