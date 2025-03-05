-- TODO pull config params from a mod settings file

-- NEW UPDATE METHODS
-- IsoFeedingTrough:createFluidContainer
-- TODO support for feeding troughs?
-- TODO support for placed objects?
-- TODO stacked/multi tier rain collectors with connected pipe?

-- TODO settings
local modDebug = true
local gutterRainFactorMultiplier = 3

local drainPipeSprites = {
    "industry_02_260",
    "industry_02_261",
    "industry_02_263",
    -- TODO Add other drain pipe sprite identifiers
}

local rainCollectorSprites = {
    "carpentry_02_54",
    "carpentry_02_120",
    "carpentry_02_122",
    "carpentry_02_124",
}

----- HELPERS ------
local function modPrint(message)
    if modDebug then
        print("[gutterWaterCollection] --------------------------------> "..message)
    end
end


local function roundDownDecimal(num)
    local scale = 100 -- Scale to shift decimal 2 places
    return math.floor(num * scale) / scale
end


local function isRainCollectorSprite(spriteName)
    for _, collectorSprite in ipairs(rainCollectorSprites) do
        if spriteName == collectorSprite then
            return true
        end
    end
    return false
end


local function isDrainPipeSprite(spriteName)
    for _, drainPipeSprite in ipairs(drainPipeSprites) do
        if spriteName == drainPipeSprite then
            return true
        end
    end
    return false
end


local function isDrainPipe(object)
    if not object then return false end

    local sprite = object:getSprite()
    if not sprite then return false end
    
    return isDrainPipeSprite(sprite:getName())
end


local function hasDrainPipeOnTile(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if isDrainPipe(object) then
            return true
        end
    end
    return false
end


local function isRainCollector(object)
    if not object then return false end
	local fluidContainer = object:getFluidContainer()
	return fluidContainer and fluidContainer:getRainCatcher() > 0.0F and fluidContainer:canPlayerEmpty()
end


local function getRainCollectorOnTile(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if isRainCollector(object) then
            return object
        end
    end
    return nil
end


local function setObjectModData(object, hasGutter)
    object:getModData()["hasGutter"] = hasGutter
end


local function getObjectEntityScript(object)
    local entityScriptName = object:getName()
    return ScriptManager.instance:getGameEntityScript(entityScriptName)
end


local function getObjectRainFactor(object)
    -- Get the current rain factor from the object's FluidContainer
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then return nil end

    return fluidContainer:getRainCatcher()
end


local function getObjectBaseRainFactor(object)
    -- Get the base rain factor from the object's entity script
    local entityScript = getObjectEntityScript(object)
    if not entityScript then
        modPrint("Entity script not found: "..tostring(object))
        return nil
    end

    local fluidContainerScript = entityScript:getComponentScriptFor(ComponentType.FluidContainer)
    if not fluidContainerScript then
        modPrint("Fluid container script not found: "..tostring(entityScript))
        return nil
    end

    return fluidContainerScript:getRainCatcher()
end


local function isBaseCollectorRainFactor(collectorObject)
    -- Compare the object's current rain factor against the base rain factor from the object's entity script
    -- NOTE: rounding since live value of crate object has extra decimal places
    local baseRainFactor = roundDownDecimal(getObjectBaseRainFactor(collectorObject))
    local rainFactor = roundDownDecimal(getObjectRainFactor(collectorObject))
    modPrint("Rain factor: "..tostring(rainFactor))
    modPrint("Base rain factor: "..tostring(baseRainFactor))
    return rainFactor == baseRainFactor
end


local function resetCollectorObject(collectorObject)
    -- Reset to base rain factor from the object's entity script
    local fluidContainer = collectorObject:getFluidContainer()
    local baseRainFactor = getObjectBaseRainFactor(collectorObject)
    modPrint("Resetting rain factor from "..tostring(getObjectRainFactor(collectorObject)).." to "..tostring(baseRainFactor))
    fluidContainer:setRainCatcher(baseRainFactor)
    setObjectModData(collectorObject, false)
end


local function upgradeCollectorObject(collectorObject)
    -- Increase rain factor of the object's FluidContainer
    local fluidContainer = collectorObject:getFluidContainer()
    local baseRainFactor = getObjectBaseRainFactor(collectorObject)
    local upgradedRainFactor = roundDownDecimal(baseRainFactor * gutterRainFactorMultiplier)
    modPrint("Upgrading rain factor from "..tostring(baseRainFactor).." to "..tostring(upgradedRainFactor))
    fluidContainer:setRainCatcher(upgradedRainFactor)
    setObjectModData(collectorObject, true)
end


local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- Intercept method used in the creation of a new iso entity object from the build menu
    -- and handle mod-specific overrides for rain collector objects
	ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    if isRainCollectorSprite(sprite) and hasDrainPipeOnTile(square) then
        local builtCollector = getRainCollectorOnTile(square)
        if not builtCollector then
            modPrint("Rain collector not found on tile after build")
            return
        end

        upgradeCollectorObject(builtCollector)
    end

end


local function handleObjectPlacedOnTile(placedObject)
    -- React to the the placement of an object on a tile
    if not isRainCollector(placedObject) then return end
    local square = placedObject:getSquare()
    if not hasDrainPipeOnTile(square) then
        if not isBaseCollectorRainFactor(placedObject) then
            resetCollectorObject(placedObject)
        end
        return
    end

    upgradeCollectorObject(placedObject)
end


Events.OnObjectAdded.Add(handleObjectPlacedOnTile)