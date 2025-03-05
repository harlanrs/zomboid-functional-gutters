local config = require("Gutter_ModOptions")
require "config"


------- Settings -------
local options = PZAPI.ModOptions:getOptions(config.modName)
local debugModeOption = options:getOption("Debug")
local debugMode = debugModeOption:getValue()
local gutterMultiplierOption = options:getOption("GutterMultiplier")


local function getGutterMultiplier()
    return gutterMultiplierOption:getValue()
end


------- Utils -------
local function modPrint(message)
    if debugMode then
        print("["..config.modName.."] --------------------------------> "..message)
    end
end


local function roundDownDecimal(num)
    -- TODO - surely there is an internal function for this?
    local scale = 100
    return math.floor(num * scale) / scale
end


local function isRainCollectorSprite(spriteName)
    for _, collectorSprite in ipairs(config.enums.collectorSprites) do
        if spriteName == collectorSprite then
            return true
        end
    end
    return false
end


local function isDrainPipeSprite(spriteName)
    for _, drainPipeSprite in ipairs(config.enums.drainPipeSprites) do
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


------- Getter & Setters ------
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
    -- Get the base rain factor from the object's GameEntityScript
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


local function setObjectModData(object, hasGutter)
    object:getModData()["hasGutter"] = hasGutter
end


------- Service -------
local function isBaseCollectorRainFactor(collectorObject)
    -- Compare the object's current rain factor against the base rain factor from the object's GameEntityScript
    -- NOTE: rounding down since live value of float can have extra junk decimal places
    local baseRainFactor = roundDownDecimal(getObjectBaseRainFactor(collectorObject))
    local rainFactor = roundDownDecimal(getObjectRainFactor(collectorObject))
    modPrint("Rain factor: "..tostring(rainFactor))
    modPrint("Base rain factor: "..tostring(baseRainFactor))
    return rainFactor == baseRainFactor
end


local function resetCollectorObject(collectorObject)
    -- Reset to base rain factor from the object's GameEntityScript
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
    local upgradedRainFactor = roundDownDecimal(baseRainFactor * getGutterMultiplier())
    modPrint("Upgrading rain factor from "..tostring(baseRainFactor).." to "..tostring(upgradedRainFactor))
    fluidContainer:setRainCatcher(upgradedRainFactor)
    setObjectModData(collectorObject, true)
end


------- Interface -------
local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    -- React to the creation of a new iso entity object from the build menu
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