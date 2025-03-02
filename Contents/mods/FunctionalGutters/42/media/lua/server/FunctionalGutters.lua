local gutterUtils = require("FunctionalGutters_Utils")
require "gutterUtils"

local function resetCollectorObject(collectorObject)
    -- Reset to base rain factor from the object's GameEntityScript
    local fluidContainer = collectorObject:getFluidContainer()
    if not fluidContainer then
        gutterUtils:modPrint("Fluid container not found for rain collector")
        return
    end

    local baseRainFactor = gutterUtils:getObjectBaseRainFactor(collectorObject)
    if not baseRainFactor then
        gutterUtils:modPrint("Base rain factor not found for rain collector")
        return
    end

    gutterUtils:modPrint("Resetting rain factor from "..tostring(fluidContainer:getRainCatcher()).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)
    gutterUtils:setGutterModData(collectorObject, false)
end

local function upgradeCollectorObject(collectorObject)
    -- Increase rain factor of the object's FluidContainer
    local fluidContainer = collectorObject:getFluidContainer()
    if not fluidContainer then
        gutterUtils:modPrint("Fluid container not found for rain collector")
        return
    end

    local baseRainFactor = gutterUtils:getObjectBaseRainFactor(collectorObject)
    if not baseRainFactor then
        gutterUtils:modPrint("Base rain factor not found for rain collector")
        return
    end

    local upgradedRainFactor = gutterUtils:getGutterRainFactor()
    gutterUtils:modPrint("Upgrading rain factor from "..tostring(baseRainFactor).." to "..tostring(upgradedRainFactor))
    fluidContainer:setRainCatcher(upgradedRainFactor)
    gutterUtils:setGutterModData(collectorObject, true)
end

------- Game System Interface -------
local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso entity object from the build menu
    -- NOTE: we are using ISBuildIsoEntity:setInfo instead of ISBuildIsoEntity:create as it is possible for the create function to exit early unsuccessfully
    ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    if gutterUtils:isRainCollectorSprite(sprite) and gutterUtils:hasDrainPipeOnTile(square) then
        local builtCollector = gutterUtils:getRainCollectorOnTile(square)
        if not builtCollector then
            gutterUtils:modPrint("Rain collector not found on tile after build")
            return
        end

        -- Upgrade the rain factor if the collector was built on a gutter tile
        upgradeCollectorObject(builtCollector)
    end

end

local function handleObjectPlacedOnTile(placedObject)
    -- React to the the placement of an object on a tile
    if not gutterUtils:isRainCollector(placedObject) then return end
    local square = placedObject:getSquare()
    if not gutterUtils:hasDrainPipeOnTile(square) then
        if not gutterUtils:isBaseCollectorRainFactor(placedObject) then
            -- Reset the rain factor if the collector was previously on a gutter tile and then moved to a non-gutter tile
            resetCollectorObject(placedObject)
        end

        return
    end

    -- Upgrade the rain factor if the collector was previously on a non-gutter tile and then moved to a gutter tile
    upgradeCollectorObject(placedObject)
end

Events.OnObjectAdded.Add(handleObjectPlacedOnTile)