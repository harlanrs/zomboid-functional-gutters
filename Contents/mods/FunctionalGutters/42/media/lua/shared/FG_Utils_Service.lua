local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

local serviceUtils = {}

function serviceUtils:isFluidContainerObject(containerObject)
    return instanceof(containerObject, "IsoObject") and containerObject:getFluidContainer() ~= nil
end

function serviceUtils:isValidContainerObject(containerObject)
    return troughUtils:isTrough(containerObject) or self:isFluidContainerObject(containerObject)
end

function serviceUtils:getObjectBaseRainFactor(object)
    -- Note: trough objects don't have an initial FluidContainer and the rain factor is hard coded on initial creation
    if troughUtils:isTrough(object) then
        return enums.troughBaseRainFactor
    end

    -- Check object's modData
    local baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Check object's GameEntityScript
    baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end

function serviceUtils:getObjectBaseRainFactorHeavy(object)
    -- Swap the order of checks to prioritize the GameEntityScript over the modData
    if troughUtils:isTrough(object) then
        return enums.troughBaseRainFactor
    end

    -- Check object's GameEntityScript
    local baseRainFactor = utils:getObjectScriptRainFactor(object)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Check object's modData
    baseRainFactor = utils:getModDataBaseRainFactor(object, nil)
    if baseRainFactor then
        return baseRainFactor
    end

    -- Fallback to 0.0 if no base rain factor found
    utils:modPrint("Base rain factor not found for object: "..tostring(object))
    return 0.0
end


function serviceUtils:setDrainPipeModData(square, squareModData, full)
    utils:modPrint("Setting drain pipe mod data for square: "..tostring(square))
    -- The square has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = true

    -- Calculate the number of 'roof' tiles above the drain pipe
    if full or not utils:getModDataRoofArea(square, squareModData) then
        squareModData[enums.modDataKey.roofArea] = isoUtils:getGutterRoofArea(square)
    end
end

function serviceUtils:cleanupDrainPipeModData(square, squareModData)
    utils:modPrint("Clearing drain pipe mod data for square: "..tostring(square))
    -- The square no longer has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = nil
    squareModData[enums.modDataKey.roofArea] = nil
end

function serviceUtils:setVerticalPipeModData(square, squareModData, full)
    utils:modPrint("Setting vertical pipe mod data for square: "..tostring(square))
    -- The square has a vertical pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = true
end

function serviceUtils:cleanupVerticalPipeModData(square, squareModData)
    utils:modPrint("Clearing vertical pipe mod data for square: "..tostring(square))
    -- The square no longer has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = nil
end

function serviceUtils:syncSquareModData(square, full)
    -- Avoid initializing mod data if we don't need to
    local squareHasModData = square:hasModData()
    local index, pipeObject, spriteName, spriteCategory = utils:getSpriteCategoryMemberOnTile(square)
    if not squareHasModData and not pipeObject then
        -- No mod data, no pipes, no worries
        return nil
    end

    local squareModData = square:getModData()
    if not pipeObject then
        if utils:getModDataHasGutter(square, squareModData) then
            -- The square no longer has a drain pipe - ensure the square's mod data reflects this
            self:cleanupDrainPipeModData(square, squareModData)
        elseif utils:getModDataHasVerticalPipe(square, squareModData) then
            -- The square no longer has a vertical pipe - ensure the square's mod data reflects this
            self:cleanupVerticalPipeModData(square, squareModData)
        end

        -- TODO general cleanup of any/all mod data keys?

        return squareModData
    end

    local hasDrainPipe = spriteCategory == enums.pipeCategory.drain
    local hasVerticalPipe = spriteCategory == enums.pipeCategory.vertical
    -- local hasHorizontalPipe = spriteCategory == enums.pipeCategory.horizontal

    if hasDrainPipe then
        self:setDrainPipeModData(square, squareModData, full)
    elseif hasVerticalPipe then
        self:setVerticalPipeModData(square, squareModData, full)
    end

    return squareModData
end

local function wrapSyncSquareModData(square, full)
    local squareModData = serviceUtils:syncSquareModData(square, full)
    if squareModData == nil then
        return false -- breaks
    end

    return nil -- continues
end

function serviceUtils:syncSquareStackModData(square, full)
    local z = isoUtils:applyToSquareStack(square, function(sq) return wrapSyncSquareModData(sq, full) end)
    utils:modPrint("Called syncSquareModData up to level: "..tostring(z))
end

return serviceUtils