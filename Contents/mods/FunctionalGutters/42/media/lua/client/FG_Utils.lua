local gutterEnums = require("FG_Enums")

local debugMode = false

local gutterUtils = {}

function gutterUtils:modPrint(message)
    -- NOTE: since debugMode is set on initialization, a restart will be required if this value is changed in the options menu
    -- We don't want to dynamically check the value as that would add unnecessary overhead
    if debugMode then
        print("["..gutterEnums.modName.."] --------------------------------> "..message)
    end
end

function gutterUtils:roundDecimal(num)
    return tonumber(string.format("%.2f", num))
end

function gutterUtils:getGutterRainFactor()
    -- NOTE: we are dynamically fetching the value so it is possible to change mid-game
    local options = PZAPI.ModOptions:getOptions(gutterEnums.modName)
    local gutterRainFactorOption = options:getOption("GutterRainFactor")
    return gutterRainFactorOption:getValue()
end

function gutterUtils:hasGutterModData(object)
    if not object:hasModData() then return nil end
    return object:getModData()["hasGutter"]
end

function gutterUtils:isGutterConnectedModData(object)
    if not object:hasModData() then return nil end
    return object:getModData()["isGutterConnected"]
end

function gutterUtils:isDrainPipeSprite(spriteName)
    for _, drainPipeSprite in ipairs(gutterEnums.drainPipeSprites) do
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

function gutterUtils:getObjectEntityScript(object)
    -- TODO verify why "Usable Barrel" objects don't have a getName method
    local entityScriptName = object:getName()
    if not entityScriptName then
        return nil
    end

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

    self:modPrint("Base rain factor: "..tostring(baseRainFactor))
    self:modPrint("Current rain factor: "..tostring(rainFactor))

    -- NOTE: normalizing since live value of a float can have extra junk decimal places which might cause false negatives
    return self:roundDecimal(rainFactor) == self:roundDecimal(baseRainFactor)
end

local function predicateNotBroken(item)
	return not item:isBroken()
end

function gutterUtils:playerHasItem(playerInv, itemName)
    return playerInv:containsTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, predicateNotBroken)
end

function gutterUtils:playerGetItem(playerInv, itemName)
    return playerInv:getFirstTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, predicateNotBroken)
end

local function checkDebugMode()
    local options = PZAPI.ModOptions:getOptions(gutterEnums.modName)
    local debugModeOption = options:getOption("Debug")
    debugMode = debugModeOption:getValue()
end

Events.OnLoad.Add(checkDebugMode)

return gutterUtils