local options = require("FG_Options")
local enums = require("FG_Enums")

local utils = {}

local debugMode = false

function utils:modPrint(message)
    if debugMode then
        print("["..enums.modName.."] --------------------------------> "..message)
    end
end


function utils:isSpriteCategoryMember(spriteName, spriteCategoryList)
    for i = 1, #spriteCategoryList do
        if spriteName == spriteCategoryList[i] then
            return true
        end
    end
    return false
end

function utils:isSpriteCategoryObject(object, spriteCategoryList)
    if not object then return false end

    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    return self:isSpriteCategoryMember(spriteName, spriteCategoryList)
end

function utils:hasSpriteCategoryMemberOnTile(square, spriteCategoryList)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if self:isSpriteCategoryObject(object, spriteCategoryList) then
            return true
        end
    end
    return false
end

function utils:isDrainPipeSprite(spriteName)
    return self:isSpriteCategoryMember(spriteName, enums.drainPipeSprites)
end

function utils:isDrainPipe(object)
    return self:isSpriteCategoryObject(object, enums.drainPipeSprites)
end

function utils:isVerticalPipe(object)
    return self:isSpriteCategoryObject(object, enums.verticalPipeSprites)
end

function utils:isHorizontalPipe(object)
    return self:isSpriteCategoryObject(object, enums.horizontalPipeSprites)
end

function utils:hasVerticalPipeOnTile(square)
    return self:hasSpriteCategoryMemberOnTile(square, enums.verticalPipeSprites)
end

function utils:hasHorizontalPipeOnTile(square)
    return self:hasSpriteCategoryMemberOnTile(square, enums.horizontalPipeSprites)
end

function utils:hasDrainPipeOnTile(square)
    return self:hasSpriteCategoryMemberOnTile(square, enums.drainPipeSprites)
end

function utils:getModDataKeyValue(object, loadedModData, key)
    local modData = loadedModData
    if not modData and not object:hasModData() then
        -- Ignore if object has no existing mod data to avoid unwanted initialization
        return nil
    elseif not modData then
        -- Load mod data if not provided
        modData = object:getModData()
    end
    return modData[key]
end

function utils:getModDataIsGutterConnected(object, loadedModData)
    return self:getModDataKeyValue(object, loadedModData, enums.modDataKey.isGutterConnected)
end

function utils:getModDataHasGutter(object, loadedModData)
    return self:getModDataKeyValue(object, loadedModData, enums.modDataKey.hasGutter)
end

function utils:getModDataBaseRainFactor(object, loadedModData)
    return self:getModDataKeyValue(object, loadedModData, enums.modDataKey.baseRainFactor)
end

function utils:getModDataRoofArea(object, loadedModData)
    return self:getModDataKeyValue(object, loadedModData, enums.modDataKey.roofArea)
end

function utils:getObjectEntityScript(object)
    local entityScriptName = object:getName()
    if not entityScriptName then
        return nil
    end

    return ScriptManager.instance:getGameEntityScript(entityScriptName)
end

function utils:getObjectRainFactor(object)
    -- Get the current rain factor from the object's FluidContainer
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then return nil end

    return fluidContainer:getRainCatcher()
end

function utils:getObjectScriptRainFactor(object)
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

local function predicateNotBroken(item)
    return not item:isBroken()
end

function utils:playerHasItem(playerInv, itemName)
    return playerInv:containsTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, predicateNotBroken)
end

function utils:playerGetItem(playerInv, itemName)
    return playerInv:getFirstTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, predicateNotBroken)
end

function utils:patchModData(object, replace)
    if not object:hasModData() then return end

    local objectModData = object:getModData()
    for internalKey,oldKey in pairs(enums.oldModDataKey) do
        if objectModData[oldKey] then
            if replace then
                -- Copy the old key's value over to the new key
                objectModData[internalKey] = objectModData[oldKey]
            end

            -- Clear the old key
            objectModData[oldKey] = nil
        end
    end

    return objectModData
end

function utils:getSpecificIsoObjectFromSquare(square, spriteName)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if spriteName == object:getSpriteName() then
            return object
        end
    end
    return nil
end

function utils:getClassFieldIndex(classObject, fieldName)
    local i = 0
    while true do
        local field = getClassField(classObject, i)
        if field:getName() == fieldName then
            return i
        end
        i = i + 1
    end
end

function utils:getObjectDisplayName(object)
    local objectName = object:getTileName()
    if objectName then
        return objectName
    end

    objectName = object:getFluidContainer():getTranslatedContainerName()
    if objectName then
        return objectName
    end

    objectName = object:getName()
    if objectName then
        return objectName
    end

    objectName = object:getObjectName()
    if objectName then
        return objectName
    end

    return "Unknown"
end

function utils:buildObjectCommandArgs(object)
    return {
        x = object:getX(),
        y = object:getY(),
        z = object:getZ(),
        index = object:getObjectIndex()
    }
end

function utils:parseObjectCommandArgs(args)
    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if not square then
        return nil
    end

    local squareObjects = square:getObjects()
    if squareObjects and squareObjects:size() > args.index then
        return squareObjects:get(args.index)
    end

    return nil
end

local function checkDebugMode()
    debugMode = options:getDebug()
end

Events.OnLoad.Add(checkDebugMode)

return utils