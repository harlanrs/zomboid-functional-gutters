if isClient() then return end

local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")

local globalObjectUtils = {}

---@param square IsoGridSquare
function globalObjectUtils:removeExistingLuaObject(square)
    local troughSystem = SFeedingTroughSystem.instance
	local luaObject = troughSystem:getLuaObjectOnSquare(square)
	if luaObject then
		troughSystem:removeLuaObject(luaObject)
	end
end

---Copied from MOFeedingTrough with minor tweaks
---@param isoObject IsoObject
---@return IsoFeedingTrough
function globalObjectUtils:replaceExistingTrough(isoObject)
    utils:modPrint('Upgrading IsoObject to IsoFeedingTrough: '..tostring(isoObject))

    local square = isoObject:getSquare()
	local spriteName = isoObject:getSprite():getName()
	local index = isoObject:getObjectIndex()
    local isNorth = troughUtils:isTroughSpriteNorth(spriteName)

	self:removeExistingLuaObject(square)

	square:transmitRemoveItemFromSquare(isoObject)
	isoObject = IsoFeedingTrough.new(square, spriteName, nil)
	isoObject:setNorth(isNorth);
	isoObject:initWithDef()
	square:AddSpecialObject(isoObject, index)
	isoObject:transmitCompleteItemToClients()
	isoObject:checkOverlayFull();

    return isoObject
end

-----@param object IsoFeedingTrough|IsoObject -- commented out type def since typing wasn't following full context and throwing a warning
---@return IsoFeedingTrough
function globalObjectUtils:loadTrough(object)
    if not troughUtils:isTroughObject(object) then
        object = self:replaceExistingTrough(object)
    end

    -- Load the IsoFeedingTrough object into the global objects system
    utils:modPrint("Loading IsoFeedingTrough into global trough system: "..tostring(object))
    SFeedingTroughSystem.instance:loadIsoObject(object)
    return object
end

-- TODO REDO support any amount of secondary troughs now that triple & quad troughs exist
---@param troughObject IsoFeedingTrough|IsoObject
---@return IsoFeedingTrough|nil primaryTrough, IsoFeedingTrough|nil secondaryTrough
function globalObjectUtils:loadFullTrough(troughObject)
    local objectSpriteName = troughObject:getSpriteName()
    if not troughUtils:isTroughSprite(objectSpriteName) then return nil end

    -- Ignore if this is already a global trough object
    if troughUtils:isTroughObject(troughObject) then return nil end

    -- TODO REDO response won't work for non-loaded troughs
    local primaryTrough = troughUtils:getPrimaryTrough(troughObject)
    if not primaryTrough then
        -- Primary through hasn't been placed yet
        return nil
    end

    -- If single tile primary trough, load it
    if troughUtils:isSingleTileTroughFromSprite(objectSpriteName) then
        return self:loadTrough(primaryTrough), nil
    end

    local secondaryTrough = troughUtils:getSecondaryTrough(troughObject)
    if not secondaryTrough then
        -- Secondary through hasn't been placed yet
        return nil
    end

    primaryTrough = self:loadTrough(primaryTrough)
    secondaryTrough = self:loadTrough(secondaryTrough)

    return primaryTrough, secondaryTrough
end

return globalObjectUtils