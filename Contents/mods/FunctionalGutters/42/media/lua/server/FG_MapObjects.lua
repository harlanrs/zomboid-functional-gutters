local enums = require("FG_Enums")
local utils = require("FG_Utils")

-- Handle conversion of all placable gutters
-- Picked up items are naive iso objects based on the sprite when initially placed on the map
-- and need to be converted to the proper entity again

-- TODO not being called
local function AddCustomSpriteProps()
    utils:modPrint("Adding custom sprite properties")
    for spriteName, spriteDef in pairs(enums.pipes) do
        local tile = IsoSpriteManager.instance:getSprite(spriteName)
        local props = tile:getProperties()
        
        if spriteDef.type == enums.pipeType.drain then
            utils:modPrint("Adding drain pipe properties to: "..spriteName)
            props:Set("IsDrainPipe", "")
            props:CreateKeySet()
            utils:modPrint("Props: "..tostring(props:Is("IsDrainPipe")))
        elseif spriteDef.type == enums.pipeType.vertical then
            utils:modPrint("Adding vertical pipe properties to: "..spriteName)
            props:Set("IsVerticalPipe", "")
            props:CreateKeySet()
            utils:modPrint("Props: "..tostring(props:Is("IsVerticalPipe")))
        end
    end
end

local function newGutter(gutterObject)
    utils:modPrint("New gutter: "..tostring(gutterObject))
end

local function loadGutter(gutterObject)
    utils:modPrint("Loading gutter: "..tostring(gutterObject))
end

local PRIORITY = 6

MapObjects.OnNewWithSprite("gutter_01_5", newGutter, PRIORITY)
MapObjects.OnLoadWithSprite("gutter_01_5", loadGutter, PRIORITY)
MapObjects.OnNewWithSprite("gutter_01_6", newGutter, PRIORITY)
MapObjects.OnLoadWithSprite("gutter_01_6", loadGutter, PRIORITY)

-- Events.OnLoad.Add(AddCustomSpriteProps)
-- Events.OnGameStart.Add(AddCustomSpriteProps)
-- Events.OnServerStarted.Add(AddCustomSpriteProps)

-- for spriteName, def in pairs(enums.pipeAtlas.type[enums.pipeType.gutter]) do
--     utils:modPrint("Adding gutter map object: "..spriteName)
--     MapObjects.OnNewWithSprite(spriteName, newGutter, PRIORITY)
--     MapObjects.OnLoadWithSprite(spriteName, loadGutter, PRIORITY)
-- end