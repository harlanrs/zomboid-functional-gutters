local options = require("FG_Options")
local enums = require("FG_Enums")

local utils = {}

local debugMode = false
local localIsoObjectType = IsoObjectType

---@param message string
function utils:modPrint(message)
    if debugMode then
        print("["..enums.modName.."] --------------------------------> "..message)
    end
end

---@param spriteName string
---@return table|nil spriteDef
function utils:getPipeSpriteDef(spriteName)
    local spriteDef = enums.pipes[spriteName]
    if spriteDef then
        return spriteDef
    end
    return nil
end

---@param spriteName string
---@return string|nil spriteDef
function utils:getSpriteCategory(spriteName)
    local spriteDef = enums.pipes[spriteName]
    if spriteDef and spriteDef.type then
        return spriteDef.type
    end
    return nil
end

---@param spriteName string
---@param spriteCategory string
---@return boolean
function utils:isSpriteCategoryMember(spriteName, spriteCategory)
    local foundSpriteCategory = self:getSpriteCategory(spriteName)
    if foundSpriteCategory == spriteCategory then
        return true
    end
    return false
end

---@param object IsoObject
---@param spriteCategory string
---@return boolean
function utils:isSpriteCategoryObject(object, spriteCategory)
    if not object then return false end

    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    return self:isSpriteCategoryMember(spriteName, spriteCategory)
end

-- NOTE: Unused atm since pipes are all handled by tile properties
---@param square IsoGridSquare
---@param spriteCategory string
---@return boolean
function utils:hasSpriteCategoryMemberOnTile(square, spriteCategory)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local foundSpriteCategory = self:getSpriteCategory(object:getSpriteName())
        if foundSpriteCategory == spriteCategory then
            return true
        end
    end

    return false
end

-- TODO return table instead
---@param square IsoGridSquare
---@param spriteCategory string
---@return number|nil index, IsoObject|nil spriteObject, string|nil spriteName, string|nil spriteCategory
function utils:getSpriteCategoryMemberOnTile(square, spriteCategory)
    -- NOTE: This function returns the first object found on the tile
    -- We do allow multiple pipe objects on a single tile but only one of each type
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local spriteName = object:getSpriteName()
        local foundSpriteCategory = self:getSpriteCategory(object:getSpriteName())
        if foundSpriteCategory == spriteCategory then
            return i, object, spriteName, foundSpriteCategory
        end
    end

    return nil, nil, nil, nil
end

---@param spriteName string
---@return boolean
function utils:isAnyPipeSprite(spriteName)
    if self:getSpriteCategory(spriteName) then
        return true
    end

    return false
end

---@param spriteName string
---@return boolean
function utils:isDrainPipeSprite(spriteName)
    local spriteCategory = self:getSpriteCategory(spriteName)
    if spriteCategory == enums.pipeType.drain then
        return true
    end
    return false
end

---@param object IsoObject
---@return boolean
function utils:isAnyPipe(object)
    local spriteName = object:getSpriteName()
    return self:isAnyPipeSprite(spriteName)
end

---@param object IsoObject
---@return boolean
function utils:isDrainPipe(object)
    return self:isSpriteCategoryObject(object, enums.pipeType.drain)
end

---@param object IsoObject
---@return boolean
function utils:isVerticalPipe(object)
    return self:isSpriteCategoryObject(object, enums.pipeType.vertical)
end

---@param object IsoObject
---@return boolean
function utils:isHorizontalPipe(object)
    return self:isSpriteCategoryObject(object, enums.pipeType.horizontal)
end

---@param object IsoObject
---@return boolean
function utils:isGutterPipe(object)
    return self:isSpriteCategoryObject(object, enums.pipeType.gutter)
end

---@param object IsoObject|IsoGridSquare
---@param key string
---@param loadedModData table|nil
---@return any|nil value
function utils:getModDataKeyValue(object, key, loadedModData)
    if not loadedModData and not object:hasModData() then
        -- Ignore if object has no existing mod data to avoid unwanted initialization
        return nil
    elseif not loadedModData then
        -- Load mod data if not provided
        loadedModData = object:getModData()
    end
    return loadedModData[key]
end

---@param object IsoObject
---@param loadedModData table|nil
---@return any|nil value
function utils:getModDataIsGutterConnected(object, loadedModData)
    return self:getModDataKeyValue(object, enums.modDataKey.isGutterConnected, loadedModData)
end

---@param object IsoObject
---@param loadedModData table|nil
---@return number|nil value
function utils:getModDataBaseRainFactor(object, loadedModData)
    return self:getModDataKeyValue(object, enums.modDataKey.baseRainFactor, loadedModData)
end

---@param object IsoObject
---@param loadedModData table|nil
---@return boolean|nil
function utils:getModDataDrainCleared(object, loadedModData)
    return self:getModDataKeyValue(object,  enums.modDataKey.drainCleared, loadedModData)
end

---@param square IsoGridSquare
---@param loadedModData table|nil
---@return integer|nil roofArea
function utils:getModDataRoofArea(square, loadedModData)
    return self:getModDataKeyValue(square, enums.modDataKey.roofArea, loadedModData)
end

---@param square IsoGridSquare
---@param loadedModData table|nil
---@return integer|nil roofArea
function utils:getModDataBuildingType(square, loadedModData)
    return self:getModDataKeyValue(square, enums.modDataKey.buildingType, loadedModData)
end

---@param square IsoGridSquare
---@param loadedModData table|nil
---@return integer|nil roofArea
function utils:getModDataMaxLevel(square, loadedModData)
    return self:getModDataKeyValue(square, enums.modDataKey.maxLevel, loadedModData)
end

---@param square IsoGridSquare
---@param loadedModData table|nil
---@return boolean|nil
function utils:getModDataIsRoofSquare(square, loadedModData)
    return self:getModDataKeyValue(square, enums.modDataKey.isRoofSquare, loadedModData)
end

---@param square IsoGridSquare
---@param propName string
---@param props table|nil
---@return boolean
function utils:checkProp(square, propName, props)
    if not props then
        props = square:getProperties()
    end
    return props:Is(propName)
end

---@param square IsoGridSquare
---@param props table|nil
---@return boolean
function utils:isDrainPipeSquare(square, props)
    return self:checkProp(square, enums.customProps.IsDrainPipe, props)
end

---@param square IsoGridSquare
---@param props table|nil
---@return boolean
function utils:isVerticalPipeSquare(square, props)
    return self:checkProp(square, enums.customProps.IsVerticalPipe, props)
end

---@param square IsoGridSquare
---@param props table|nil
---@return boolean
function utils:isGutterPipeSquare(square, props)
    return self:checkProp(square, enums.customProps.IsGutterPipe, props)
end

---@param square IsoGridSquare
---@param props table|nil
---@return boolean
function utils:isAnyPipeSquare(square, props)
    if not props then
        props = square:getProperties()
    end
    return self:isDrainPipeSquare(square, props) or self:isVerticalPipeSquare(square, props) or self:isGutterPipeSquare(square, props)
end

---@param object IsoObject
---@return GameEntityScript|nil
function utils:getObjectEntityScript(object)
    local entityScriptName = object:getName()
    if not entityScriptName then
        return nil
    end

    return ScriptManager.instance:getGameEntityScript(entityScriptName)
end

---@param object IsoObject
---@return number|nil
function utils:getObjectRainFactor(object)
    -- Get the current rain factor from the object's FluidContainer
    local fluidContainer = object:getFluidContainer()
    if not fluidContainer then return nil end

    return fluidContainer:getRainCatcher()
end

---@param object IsoObject
---@return integer|nil
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

---@param item InventoryItem
---@return boolean
local function predicateNotBroken(item)
    return not item:isBroken()
end

---@param playerInv ItemContainer
---@param itemName string
---@return boolean
function utils:playerHasItem(playerInv, itemName)
    return playerInv:containsTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, predicateNotBroken)
end

---@param playerInv ItemContainer
---@param itemName string
---@return InventoryItem|nil item
function utils:playerGetItem(playerInv, itemName)
    return playerInv:getFirstTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, predicateNotBroken)
end

---@param object IsoObject|IsoGridSquare
---@param replace boolean
---@return table|nil objectModData
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

---@param square IsoGridSquare
---@param spriteName string
---@return IsoFeedingTrough|IsoObject|nil object
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

---@param square IsoGridSquare
---@return boolean
function utils:hasRoofProp(square)
    return square:Has(localIsoObjectType.WestRoofB) or square:Has(localIsoObjectType.WestRoofM) or square:Has(localIsoObjectType.WestRoofT)
end

---@param object IsoObject
---@return boolean
function utils:isRoofObject(object)
    if not object then return false end

    local objectType = object:getType()
    if objectType == localIsoObjectType.WestRoofB or objectType == localIsoObjectType.WestRoofM or objectType == localIsoObjectType.WestRoofT then
        return true
    end

    return false
end

---@param classObject table
---@param fieldName string
---@return integer fieldIndex
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

---@param object IsoObject
---@return string
function utils:getObjectDisplayName(object)
    local objectName = object:getEntityDisplayName()
    if objectName then
        return objectName
    end

    objectName = object:getTileName()
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

---@param object IsoObject
---@return table
function utils:buildObjectCommandArgs(object)
    return {
        x = object:getX(),
        y = object:getY(),
        z = object:getZ(),
        index = object:getObjectIndex()
    }
end

---@param args table
---@return IsoObject|nil
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

LuaEventManager.AddEvent(enums.modEvents.OnGutterTileUpdate)

Events.OnLoad.Add(checkDebugMode)

return utils