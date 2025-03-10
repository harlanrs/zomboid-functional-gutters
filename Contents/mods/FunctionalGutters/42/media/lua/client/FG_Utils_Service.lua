local enums = require("FG_Enums")
local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")

local serviceUtils = {}

function serviceUtils:getObjectBaseRainFactor(object)
    -- Note: 
    -- * Trough objects don't have an initial FluidContainer and the rain factor is hard set on trough creation
    -- * Placing single-tile troughs runs into an issue were they become an isoObject instead of an IsoFeedingTrough until the game is reloaded
    if troughUtils:isTrough(object) then
        utils:modPrint("Using trough base rain factor: "..tostring(enums.troughBaseRainFactor))
        return enums.troughBaseRainFactor
    end

    -- Check object's modData
    local baseRainFactor = utils:getModDataBaseRainFactor(object)
    if baseRainFactor and baseRainFactor < 0.6 then
        utils:modPrint("Using mod data rain factor: "..tostring(baseRainFactor))
        return baseRainFactor
    end

    -- Check object's GameEntityScript
    baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        utils:modPrint("Using entity script rain factor: "..tostring(baseRainFactor))
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

return serviceUtils