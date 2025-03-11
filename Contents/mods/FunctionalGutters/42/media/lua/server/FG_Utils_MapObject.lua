local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")

local localSFeedingTroughSystem = SFeedingTroughSystem

local mapObjectUtils = {}

function mapObjectUtils:removeExistingLuaObject(square)
	local luaObject = localSFeedingTroughSystem.instance:getLuaObjectOnSquare(square)
	if luaObject then
		localSFeedingTroughSystem.instance:removeLuaObject(luaObject)
	end
end

-- Copied local func over from MOFeedingTrough so will need to watch for drift in the future
function mapObjectUtils:replaceExistingTrough(isoObject)
    utils:modPrint('Internal replaceExistingTrough called')
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

    isoObject:checkOverlayFull();
    return isoObject
end

function mapObjectUtils:loadTrough(isoObject)
    -- Convert isoObject -> IsoFeedingTrough
    utils:modPrint("Internal load trough")
    if not troughUtils:isTroughObject(isoObject) then
        isoObject = mapObjectUtils:replaceExistingTrough(isoObject)
    end

    -- Load the IsoFeedingTrough object into the global objects system
    localSFeedingTroughSystem.instance:loadIsoObject(isoObject)
    return isoObject
end


-- function mapObjectUtils:placeTrough(x, y, z, north)
--     local sq = getWorld():getCell():getGridSquare(x, y, z);
--     localSFeedingTroughSystem.instance:addTrough(sq,self.def,north,false)
--     if self.def.sprite2 then
--         local x1, y1, z1 = self:getSquare2Pos(sq,north)
--         local sq2 = getWorld():getCell():getGridSquare(x1,y1,z1)
--         if sq2 then
--             localSFeedingTroughSystem.instance:addTrough(sq2,self.def,north,true)
--         end
--     end

return mapObjectUtils