-- TODO pull config params from a mod settings file

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

local function modPrint(message)
    if modDebug then
        print("[gutterWaterCollection] --------------------------------> "..message)
    end
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
    -- TODO check against specific sprite names
    if not object then return false end
	local fluidContainer = object:getFluidContainer()
	return fluidContainer and fluidContainer:getRainCatcher() > 0.0F and fluidContainer:canPlayerEmpty()
end


local function getRainCollectorOnTile(square)
    -- NOTE: only first found collector is returned
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


local function hasGutterModData(object)
    if not object:hasModData() then return false end
    return object:getModData()["hasGutter"]
end


local function syncObjectGutterData(object)
    if not isRainCollector(object) then return end

    local hasGutter = hasDrainPipeOnTile(object:getSquare())
    setObjectModData(object, hasGutter)

    modPrint("Rain collector on tile has gutter: "..tostring(hasGutter))
end


local function syncTileGutterData(square)
    local collectorObjects = {}
    local hasGutter = false
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if isRainCollector(object) then
            table.insert(collectorObjects, object)
        end

        if isDrainPipe(object) then
            hasGutter = true
        end
    end

    for _, collectorObject in ipairs(collectorObjects) do
        modPrint('Rain collector on tile has gutter: '..tostring(hasGutter))
        setObjectModData(collectorObject, hasGutter)
    end
end


local function handleObjectPlacedOnTile(object)
    modPrint("Rain collector placed on tile")
    syncObjectGutterData(object)
end


local function handleObjectBuiltOnTile(square)
    modPrint("Rain collector built on tile")
    syncTileGutterData(square)
end


local function handleObjectRemovedFromTile(object)
    -- Reset the flag when container is removed
    if isRainCollector(object) then
        modPrint("Rain collector removed from tile")
        setObjectModData(object, nil)
    end
end


local function handleObjectLoaded(object)
    modPrint("Rain collector loaded")
    syncObjectGutterData(object)
end


local function stampRainCollectorJavaObject(rainCollectorObject, square, north, sprite)
    -- Create new rain collector javaObject based on the existing rain collector
    local cell = square:getCell()
    local baseModData = {}
    local javaObject = IsoThumpable.new(cell, square, sprite, north, baseModData)
    javaObject:setBlockAllTheSquare(rainCollectorObject:isBlockAllTheSquare())
    javaObject:setName(rainCollectorObject:getName())
    javaObject:setIsDismantable(rainCollectorObject:isDismantable())
    javaObject:setModData(copyTable(rainCollectorObject:getModData()))
    javaObject:setMaxHealth(rainCollectorObject:getMaxHealth())
    javaObject:setHealth(rainCollectorObject:getHealth())
    javaObject:setSpecialTooltip(true)

    return javaObject
end


local function replaceCollectorEntityScript(originalEntityScript)
    modPrint("Original entity script: "..originalEntityScript:getName())

    local replacementScriptName = "GutterWaterCollection."..originalEntityScript:getName().."_Enhanced"
    local replacementEntityScript = ScriptManager.instance:getSpecificEntity(replacementScriptName)
    modPrint("Replacement entity script: "..replacementEntityScript:getName())

    -- Copy replacement script over the original script
    originalEntityScript:copyFrom(replacementEntityScript)
end


local function createFromCollectorEntityScript(javaObject, originalEntityScript, square, index)
    replaceCollectorEntityScript(originalEntityScript)

    -- Connect java object with the buffer entity script
    local isFirstTimeCreated = true;
    GameEntityFactory.CreateIsoObjectEntity(javaObject, originalEntityScript, isFirstTimeCreated);

    -- Add java object to the square and transmit to clients
    square:AddSpecialObject(javaObject, index)
    javaObject:transmitCompleteItemToClients()
end


local function resetCollectorEntityScript(originalEntityScript)
    local resetScriptName = "GutterWaterCollection."..originalEntityScript:getName().."_Reset"
    local resetEntityScript = ScriptManager.instance:getSpecificEntity(resetScriptName)
    modPrint("Reset entity script: "..resetEntityScript:getName())

    originalEntityScript:copyFrom(resetEntityScript)
end


-- Intercept creation of a new iso entity object from the build menu
-- and handle mod-specific overrides for rain collector objects
local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo
function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    local needsReset = false
    if isRainCollectorSprite(sprite) and hasDrainPipeOnTile(square) then
        local originalEntityScript = self.objectInfo:getScript():getParent()
        replaceCollectorEntityScript(originalEntityScript)

        needsReset = true
    end

	ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    if needsReset then
        local originalEntityScript = self.objectInfo:getScript():getParent()
        resetCollectorEntityScript(originalEntityScript)

        local rainCollectorObject = getRainCollectorOnTile(square)
        if not rainCollectorObject then
            modPrint("Rain collector not found on tile")
            return
        end

        setObjectModData(rainCollectorObject, true)
    end

end


-- React to the the placement of a new object on a tile
local function handleObjectPlacedOnTile2(placedObject)
    -- Verify that the placed object is a rain collector on a tile with a drain pipe
    if not isRainCollector(placedObject) then return end
    local square = placedObject:getSquare()
    if not hasDrainPipeOnTile(square) then
        setObjectModData(placedObject, false)
        return
    end

    -- Create new IsoThumpable javaObject copy of the rain collector
    local north = false
    local entityIsoSprite = placedObject:getSprite()
    local entityScriptName = placedObject:getName()
    local index = placedObject:getObjectIndex()
    local javaObject = stampRainCollectorJavaObject(placedObject, square, north, entityIsoSprite:getName())

    setObjectModData(javaObject, true)

    -- Remove the original object from the square
    square:transmitRemoveItemFromSquare(placedObject)

    -- Place the new object on the square
    local entityScript = ScriptManager.instance:getGameEntityScript(entityScriptName)
    createFromCollectorEntityScript(javaObject, entityScript, square, index)

    -- Reset the original entity script
    resetCollectorEntityScript(entityScript)
end


-- Listen for on load events for all rain collector sprites
-- for _, collectorSprite in ipairs(rainCollectorSprites) do
--     MapObjects.OnLoadWithSprite(collectorSprite, handleObjectLoaded, 6)
-- end


-- Hooks
Events.OnObjectAdded.Add(handleObjectPlacedOnTile2)
-- Events.OnTileRemoved.Add(handleObjectRemovedFromTile)