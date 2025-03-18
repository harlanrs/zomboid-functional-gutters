local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local troughUtils = require("FG_Utils_Trough")

local localIsoDirections = IsoDirections

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


function serviceUtils:setDrainPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting drain pipe mod data for square: "..tostring(square))
    -- The square has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = true

    -- TODO
    -- Test setting object property
    -- local pipeSpriteProps = pipeObject:getSprite():getProperties()
    -- -- if not pipeObjectProps:Is("IsDrainPipe") then
    -- pipeSpriteProps:Set("IsDrainPipe", "", true)
    -- -- end

    -- -- Calculate the number of 'roof' tiles above the drain pipe
    if full or not utils:getModDataRoofArea(square, squareModData) then
        squareModData[enums.modDataKey.roofArea] = isoUtils:getGutterRoofArea(square)
    end
end

function serviceUtils:cleanupDrainPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing drain pipe mod data for square: "..tostring(square))
    -- The square no longer has a drain pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutter] = nil
    squareModData[enums.modDataKey.roofArea] = nil
end

function serviceUtils:setVerticalPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting vertical pipe mod data for square: "..tostring(square))
    -- The square has a vertical pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = true

    -- local pipeSpriteProps = pipeObject:getSprite():getProperties()
    -- if not pipeObjectProps:Is("IsVerticalPipe") then
    -- pipeSpriteProps:Set("IsVerticalPipe", "", true)
    -- end
end

function serviceUtils:cleanupVerticalPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing vertical pipe mod data for square: "..tostring(square))
    -- The square no longer has a vertical pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasVerticalPipe] = nil
end

function serviceUtils:setGutterPipeModData(square, squareModData, pipeObject, full)
    utils:modPrint("Setting gutter pipe mod data for square: "..tostring(square))
    -- The square has a gutter pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutterPipe] = true

    -- TODO gutterWest, gutterEast, gutterNorth, gutterSouth
    local spriteName = pipeObject:getSpriteName()
    local pipeDef = enums.pipes[spriteName]
    if not pipeDef then
        utils:modPrint("Pipe definition not found for sprite: "..tostring(spriteName))
        return
    end

    -- Test
    local hasGutterPipeProp = square:getProperties():Is("IsGutterPipe")
    utils:modPrint("Has gutter pipe prop: "..tostring(hasGutterPipeProp))

    -- TODO move to dedicated section
    -- if pipeDef.position == localIsoDirections.N then
    --     -- TODO check for sloped roof north
    --     local upNorthSquare = square:getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ() + 1)
    --     utils:modPrint('Up north square: '..tostring(upNorthSquare:getX())..','..tostring(upNorthSquare:getY())..','..tostring(upNorthSquare:getZ()))
    --     local hasSlopedRoofNorth = square:Has(IsoObjectType.WestRoofB) or square:Has(IsoObjectType.WestRoofM) or square:Has(IsoObjectType.WestRoofT)
    --     local hasSlopedRoofNorth2 = square:HasSlopedRoofNorth()
    --     utils:modPrint("Has sloped roof north: "..tostring(hasSlopedRoofNorth))
    -- elseif pipeDef.position == localIsoDirections.W then
    --     -- TODO check for sloped roof west
    --     local upWestSquare = square:getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ() + 1)
    --     utils:modPrint('Up west square: '..tostring(upWestSquare:getX())..','..tostring(upWestSquare:getY())..','..tostring(upWestSquare:getZ()))
    --     local hasSlopedRoofWest = square:Has(IsoObjectType.WestRoofB) or square:Has(IsoObjectType.WestRoofM) or square:Has(IsoObjectType.WestRoofT)
    --     local hasSlopedRoofWest2 = square:HasSlopedRoofWest()
    --     utils:modPrint("Has sloped roof west: "..tostring(hasSlopedRoofWest))
    -- end
end

function serviceUtils:cleanupGutterPipeModData(square, squareModData)
    -- TODO check cases where squareModData is nil
    if squareModData == nil then
        squareModData = square:getModData()
    end

    utils:modPrint("Clearing gutter pipe mod data for square: "..tostring(square))
    -- The square no longer has a gutter pipe - ensure the square's mod data reflects this
    squareModData[enums.modDataKey.hasGutterPipe] = nil

    local hasGutterPipeProp = square:getProperties():Is("IsGutterPipe")
    utils:modPrint("Has gutter pipe prop: "..tostring(hasGutterPipeProp))

    -- TODO gutterWest, gutterEast, gutterNorth, gutterSouth
end

function serviceUtils:syncSquareModData(square, full)
    local objects = square:getObjects()
    local pipeObjects = table.newarray()
    local squareModData = nil

    local hasDrainPipe
    local hasVerticalPipe
    local hasGutterPipe

    for i = 0, objects:size() - 1 do
        -- Check object for pipe sprite category
        local object = objects:get(i)
        local spriteName = object:getSpriteName()
        local spriteCategory = utils:getSpriteCategory(spriteName)
        if spriteCategory then
            table.insert(pipeObjects, object)
            if squareModData == nil then
                squareModData = square:getModData()
            end

            if spriteCategory == enums.pipeType.drain then
                hasDrainPipe = true
                self:setDrainPipeModData(square, squareModData, object, full)
            end

            if spriteCategory == enums.pipeType.vertical then
                hasVerticalPipe = true
                self:setVerticalPipeModData(square, squareModData, object, full)
            end

            if spriteCategory == enums.pipeType.gutter then
                hasGutterPipe = true
                self:setGutterPipeModData(square, squareModData, object,  full)
            end

            -- local hasHorizontalPipe = spriteCategory == enums.pipeType.horizontal
        end
    end

    -- Cleanup square mod data if pipes were removed
    if utils:getModDataHasGutter(square, squareModData) and not hasDrainPipe then
        self:cleanupDrainPipeModData(square, squareModData)
    end

    if utils:getModDataHasVerticalPipe(square, squareModData) and not hasVerticalPipe then
        self:cleanupVerticalPipeModData(square, squareModData)
    end

    if utils:getModDataHasGutterPipe(square, squareModData) and not hasGutterPipe then
        self:cleanupGutterPipeModData(square, squareModData)
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