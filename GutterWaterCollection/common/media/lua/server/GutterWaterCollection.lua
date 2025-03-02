-- TODO pull config params from a mod settings file

-- TODO settings
local modDebug = true
local gutterRainFactorMultiplier = 3

local drainPipeSprites = {
    "industry_02_260",
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
        print("[gutterRainCollection] --------------------------------> "..message)
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


-- Proxy function to extend rainwater collection
-- NOTE: 
--     ISBuildIsoEntity:create can exit early so we need to hook into
--     ISBuildIsoEntity:setInfo instead as it is called at the very end of the ISBuildIsoEntity:create
--     
local ISBuildIsoEntity_setInfo = ISBuildIsoEntity.setInfo

function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
	ISBuildIsoEntity_setInfo(self, square, north, sprite, openSprite)

    if isRainCollectorSprite(sprite) then
        handleObjectBuiltOnTile(square)
    end
end


local FluidContainer_getRainCatcher = FluidContainer.getRainCatcher
function FluidContainer:getRainCatcher()
    local rainCatcher  = FluidContainer_getRainCatcher(self)
    -- if not self.hasGutter then return end

    modPrint("Inside rain collector proxy")
    -- setObjectModData(self, true)

    return rainCatcher
end

-- FluidContainer.load

-- local LocalFluidContainer = FluidContainer
-- function LocalFluidContainer:getRainCatcher()
--     if self.rainCatcher <= 0.0F then
--         return self.rainCatcher
--     end

--     modPrint("Fluid Container Rain Catcher: "..tostring(self.rainCatcher * gutterRainFactorMultiplier))
--     return self.rainCatcher * gutterRainFactorMultiplier
-- end


-- local IsoObject_getFluidContainer = IsoObject.getFluidContainer
-- function IsoObject:getFluidContainer()
--     modPrint("Getting wrapped fluid container")
--     local fluidContainer = IsoObject_getFluidContainer(self)
--     if not fluidContainer or not hasGutterModData(self) then
--         return fluidContainer
--     end

--     -- 'Cast' the base fluid container to the extended fluid container
--     setmetatable(fluidContainer, {__index = LocalFluidContainer})
--     return fluidContainer
-- end

-- Primary function to extend rainwater collection
local function checkGutterRainCollection()
    modPrint("Tick")
    -- Skip if not raining
    if not RainManager:isRaining() then return end
    -- if not climateManager:isRaining() then return end

    modPrint("Is raining")

    local rain = RainManager:getRainIntensity()
    
    -- Process all loaded water collectors
    local rainBarrelSystemInstance = SRainBarrelSystem.instance
    local rainBarrelCount = rainBarrelSystemInstance:getLuaObjectCount()
    modPrint("Rain collectors found: " .. rainBarrelCount)
    -- for i = 1, rainBarrelCount do
    --     local luaObject = rainBarrelSystemInstance:getLuaObjectByIndex(i)

    --     -- Skip if the collector is full
    --     if luaObject.waterAmount >= luaObject.waterMax then
    --         return
    --     end

    --     local isoObject = luaObject:getIsoObject()
    --     if isoObject:getModData()["hasGutter"] then
    --         print("[gutterRainCollection] Adding additional water to collector from gutter")
    --         -- Use fluid system to add water to the collector
    --         local fluidContainer = isoObject:getFluidContainer()
    --         local currentFluidAmount = fluidContainer:getAmount()
    --         local maxAmount = fluidContainer:getCapacity()
    --         local rainFactor = math.min(rain * 0.01) -- Regular rain fill factor
    --         local extraAmount = rainFactor -- Additional amount from gutter
            
    --         if fluidContainer:isFull() then
    --             -- Don't exceed max capacity
    --             return
    --         elseif currentFluidAmount + extraAmount <= maxAmount then
    --             -- Add additional water from gutter
    --             fluidContainer:addFluid(Fluid.TaintedWater, extraAmount)
    --         else
    --             -- Fill to max capacity
    --             fluidContainer:addFluid(Fluid.TaintedWater, fluidContainer:getFreeCapacity())
    --         end
    --     end
    -- end
end




-- Listen for on load events for all rain collector sprites
for _, collectorSprite in ipairs(rainCollectorSprites) do
    MapObjects.OnLoadWithSprite(collectorSprite, handleObjectLoaded, 6)
end


-- local PRIORITY = 6
-- MapObjects.OnLoadWithSprite("carpentry_02_124", LoadCollector, PRIORITY)
-- MapObjects.OnLoadWithSprite("carpentry_02_122", LoadCollector, PRIORITY)
-- MapObjects.OnLoadWithSprite("carpentry_02_54", LoadCollector, PRIORITY)
-- MapObjects.OnLoadWithSprite("carpentry_02_120", LoadCollector, PRIORITY)



-- IsoWorldInventoryObject (for things plaed on ground like pots not buildables)
-- isWaterSource
-- getWaterMax
-- getWaterAmount
-- setWaterAmount(amount, tainted_bool)

-- IsoCell
-- StaticUpdaterObjectList
-- getProcessWorldItems
-- getStaticUpdaterObjectList

-- IsoGridSquare
-- getObjects
-- isOutside
-- getOpenAir
-- RainFactor


-- SRainBarrelSystem.lua
-- RainManager.isRaining()



-- local function onWaterAmountChange(object, previousAmount)
--     if object:getModData()["hasGutter"] then
        
--     end
-- end

-- Hook into the event that fills rain collectors
-- TODO OnRainStart has been deprecated, use OnClimateTick maybe? (climateManager)
-- Events.OnClimateTick.Add(checkGutterRainCollection)
-- Events.EveryTenMinutes.Add(checkGutterRainCollection)

-- Hook into fluid change in object
-- Events.OnWaterAmountChange.Add(onWaterAmountChange)

-- OnWeatherPeriodStart - period:getRainThreshold()
-- OnWeatherPeriodEnd - period:getRainThreshold()


-- Hooks
Events.OnObjectAdded.Add(handleObjectPlacedOnTile)
Events.OnTileRemoved.Add(handleObjectRemovedFromTile)