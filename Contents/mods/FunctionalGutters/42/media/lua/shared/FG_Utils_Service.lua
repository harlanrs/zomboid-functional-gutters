local enums = require("FG_Enums")
local utils = require("FG_Utils")
local troughUtils = require("FG_Utils_Trough")

local serviceUtils = {}

function serviceUtils:isFluidContainerObject(containerObject)
    return instanceof(containerObject, "IsoObject") and containerObject:getFluidContainer() ~= nil
end

function serviceUtils:isValidContainerObject(containerObject)
    return troughUtils:isTrough(containerObject) or self:isFluidContainerObject(containerObject)
end

function serviceUtils:getObjectBaseRainFactor(object)
    -- Note: 
    -- * Trough objects don't have an initial FluidContainer and the rain factor is hard set on trough creation
    -- * Placing single-tile troughs runs into an issue were they become an isoObject instead of an IsoFeedingTrough until the game is reloaded
    if troughUtils:isTrough(object) then
        utils:modPrint("Using trough base rain factor: "..tostring(enums.troughBaseRainFactor))
        return enums.troughBaseRainFactor
    end

    -- Check object's modData
    local baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
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

function serviceUtils:getObjectBaseRainFactorDeep(object)
    -- Swap the order of checks to prioritize the GameEntityScript over the modData
    if troughUtils:isTrough(object) then
        utils:modPrint("Using trough base rain factor: "..tostring(enums.troughBaseRainFactor))
        return enums.troughBaseRainFactor
    end

    -- Check object's GameEntityScript
    local baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        utils:modPrint("Using entity script rain factor: "..tostring(baseRainFactor))
        return baseRainFactor
    end

    -- Check object's modData
    baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
        utils:modPrint("Using mod data rain factor: "..tostring(baseRainFactor))
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

function serviceUtils:syncSquareModData(square)
    -- Avoid initializing mod data if we don't need to
    local squareHasModData = square:hasModData()
    local hasDrainPipe = utils:hasDrainPipeOnTile(square)
    if not squareHasModData and not hasDrainPipe then
        -- No mod data, no drain pipe, no worries
        return nil
    end

    -- Temp patch
    utils:patchModData(square, true) -- TODO needed?

    local squareModData = square:getModData()
    if hasDrainPipe then
        -- The square has a drain pipe - ensure the square's mod data reflects this
        squareModData[enums.modDataKey.hasGutter] = true
    else
        if utils:getModDataHasGutter(square, squareModData) then
            -- The square no longer has a drain pipe - ensure the square's mod data reflects this
            squareModData[enums.modDataKey.hasGutter] = nil
        end
    end

    return squareModData
end

return serviceUtils