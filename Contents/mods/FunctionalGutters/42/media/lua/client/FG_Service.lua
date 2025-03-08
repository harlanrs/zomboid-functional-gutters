local gutterUtils = require("FG_Utils")

local gutterService = {}

function gutterService:syncSquareModData(square)
    local squareModData = square:getModData()
    local hasDrainPipe = gutterUtils:hasDrainPipeOnTile(square)
    squareModData["hasGutter"] = hasDrainPipe
    return squareModData
end

function gutterService:resetCollectorObject(collectorObject)
    -- Reset to base rain factor from the object's GameEntityScript
    local fluidContainer = collectorObject:getFluidContainer()
    if not fluidContainer then
        gutterUtils:modPrint("Fluid container not found for collector: "..tostring(collectorObject))
        return
    end

    -- Attempt to get the base rain factor from the object's GameEntityScript
    local baseRainFactor = gutterUtils:getObjectBaseRainFactor(collectorObject)
    if not baseRainFactor then
        -- If no fluid container component exists on the object's GameEntityScript, reset the current rain factor to 0
        -- This should only be hit for modded objects that don't have an initial FluidContainer such as "Upgraded Barrels"
        gutterUtils:modPrint("Base rain factor not found for collector: "..tostring(collectorObject))

        -- Reset to 0 as fallback catchall
        baseRainFactor = 0.0
    end

    gutterUtils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)
    
    local collectorObjectModData = collectorObject:getModData()
    collectorObjectModData["isGutterConnected"] = false
end

function gutterService:upgradeCollectorObject(collectorObject)
    -- Increase rain factor of the object's FluidContainer
    local fluidContainer = collectorObject:getFluidContainer()
    if not fluidContainer then
        gutterUtils:modPrint("Fluid container not found for collector: "..tostring(collectorObject))
        return
    end

    local baseRainFactor = gutterUtils:getObjectBaseRainFactor(collectorObject)
    if not baseRainFactor then
        -- If no fluid container component exists on the object's GameEntityScript, reset the current rain factor to 0
        -- This should only be relevant for modded objects that don't have an initial FluidContainer such as "Upgraded Barrels"
        gutterUtils:modPrint("Base rain factor not found for collector: "..tostring(collectorObject))

        -- Set local baseRainFactor to 0
        baseRainFactor = 0.0
    end

    local upgradedRainFactor = gutterUtils:getGutterRainFactor()
    gutterUtils:modPrint("Upgrading rain factor from "..tostring(baseRainFactor).." to "..tostring(upgradedRainFactor))
    fluidContainer:setRainCatcher(upgradedRainFactor)

    local collectorObjectModData = collectorObject:getModData()
    collectorObjectModData["isGutterConnected"] = true
end

function gutterService:handleObjectPlacedOnTile(placedObject)
    -- React to the placement of an existing iso object on a tile
    local square = placedObject:getSquare()
    local squareModData = self:syncSquareModData(square)
    if squareModData["hasGutter"] then
        gutterUtils:modPrint("Tile marked as having a gutter after placing object: "..tostring(square)..", "..tostring(placedObject))
    end
end


function gutterService:handleObjectBuiltOnTile(square)
    -- React to the creation of a new iso object on a tile
    local squareModData = self:syncSquareModData(square)
    if squareModData["hasGutter"] then
        gutterUtils:modPrint("Tile marked as having a gutter after building object: "..tostring(square))
    end
end

function gutterService:handleObjectRemovedFromTile(removedObject)
    -- TODO WTF why is this called when a feeding trough is placed?

    -- React to the the removal of an object from a tile
    -- TODO require disconnecting from gutter before object can be picked up
    -- That way the only time a connected object should make it to this function would be for destruction-/deletion-type events
    -- In which case, we only need to care about state on the square and can ignore the object itself
    local square = removedObject:getSquare()
    if square and self:syncSquareModData(square)["hasGutter"] then
        -- Reset the removed object's rain factor if it was connected to a gutter
        gutterUtils:modPrint("Object removed from tile with gutter: "..tostring(removedObject)..", "..tostring(square))
        self:resetCollectorObject(removedObject)
    end
end

return gutterService