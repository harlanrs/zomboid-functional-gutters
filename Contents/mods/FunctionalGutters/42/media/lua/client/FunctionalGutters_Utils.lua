local gutterConfig = require("FunctionalGutters_Config")
require "gutterConfig"

local options = PZAPI.ModOptions:getOptions(gutterConfig.modName)
local debugModeOption = options:getOption("Debug")
local debugMode = debugModeOption:getValue()
local gutterRainFactorOption = options:getOption("GutterRainFactor")

local gutterUtils = {}

function gutterUtils:modPrint(message)
    -- NOTE: since debugMode is set on initialization, a restart will be required if this value is changed in the options menu
    -- We don't want to dynamically check the value as that would add unnecessary overhead
    if debugMode then
        print("["..gutterConfig.modName.."] --------------------------------> "..message)
    end
end

function gutterUtils:roundDecimal(num)
    -- TODO - surely there is an internal function for this?
    local scale = 100
    return math.floor(num * scale) / scale
end

function gutterUtils:getGutterRainFactor()
    -- NOTE: we are dynamically fetching the value so it is possible to change midgame
    return gutterRainFactorOption:getValue()
end

function gutterUtils:hasGutterModData(object)
    if not object:hasModData() then return false end
    return object:getModData()["hasGutter"]
end

function gutterUtils:setGutterModData(object, hasGutter)
    object:getModData()["hasGutter"] = hasGutter
end

function gutterUtils:isRainCollectorSprite(spriteName)
    for _, collectorSprite in ipairs(gutterConfig.enums.collectorSprites) do
        if spriteName == collectorSprite then
            return true
        end
    end
    return false
end

function gutterUtils:isDrainPipeSprite(spriteName)
    for _, drainPipeSprite in ipairs(gutterConfig.enums.drainPipeSprites) do
        if spriteName == drainPipeSprite then
            return true
        end
    end
    return false
end

function gutterUtils:isDrainPipe(object)
    if not object then return false end

    local sprite = object:getSprite()
    if not sprite then return false end

    return self:isDrainPipeSprite(sprite:getName())
end

function gutterUtils:hasDrainPipeOnTile(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if self:isDrainPipe(object) then
            return true
        end
    end
    return false
end

function gutterUtils:isRainCollector(object)
    if not object then return false end
    local fluidContainer = object:getFluidContainer()
    return fluidContainer and fluidContainer:getRainCatcher() > 0.0 and fluidContainer:canPlayerEmpty()
end

function gutterUtils:getRainCollectorOnTile(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if self:isRainCollector(object) then
            return object
        end
    end
    return nil
end

function gutterUtils:getObjectEntityScript(object)
    local entityScriptName = object:getName()
    return ScriptManager.instance:getGameEntityScript(entityScriptName)
end

function gutterUtils:getObjectRainFactor(object)
    -- Get the current rain factor from the object's FluidContainer
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then return nil end

    return fluidContainer:getRainCatcher()
end

function gutterUtils:getObjectBaseRainFactor(object)
    -- Get the base rain factor from the object's GameEntityScript
    local entityScript = self:getObjectEntityScript(object)
    if not entityScript then
        self:modPrint("Entity script not found: "..tostring(object))
        return nil
    end

    local fluidContainerScript = entityScript:getComponentScriptFor(ComponentType.FluidContainer)
    if not fluidContainerScript then
        self:modPrint("Fluid container script not found: "..tostring(entityScript))
        return nil
    end

    return fluidContainerScript:getRainCatcher()
end

function gutterUtils:isBaseCollectorRainFactor(collectorObject)
    -- Compare the object's current rain factor against the base rain factor from the object's GameEntityScript
    local baseRainFactor = self:getObjectBaseRainFactor(collectorObject)
    if not baseRainFactor then return nil end

    local rainFactor = self:getObjectRainFactor(collectorObject)
    if not rainFactor then return nil end

    self:modPrint("Rain factor: "..tostring(rainFactor))
    self:modPrint("Base rain factor: "..tostring(baseRainFactor))

    -- NOTE: normalizing since live value of a float can have extra junk decimal places which might cause false negatives
    return self:roundDecimal(rainFactor) == self:roundDecimal(baseRainFactor)
end

Events.OnLoad.Add(function()
    -- Reload the debug option
    debugMode = debugModeOption:getValue()
end)

return gutterUtils