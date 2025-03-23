local enums = require("FG_Enums")
local utils = require("FG_Utils")

-- Handle conversion of all placable gutters
-- Picked up items are naive iso objects based on the sprite when initially placed on the map
-- and need to be converted to the proper entity again
local function newGutter(gutterObject)
    utils:modPrint("New gutter: "..tostring(gutterObject))
end

local function loadGutter(gutterObject)
    utils:modPrint("Loading gutter: "..tostring(gutterObject))
end

local PRIORITY = 6

-- MapObjects.OnNewWithSprite("gutter_01_5", newGutter, PRIORITY)
-- MapObjects.OnLoadWithSprite("gutter_01_5", loadGutter, PRIORITY)
-- MapObjects.OnNewWithSprite("gutter_01_6", newGutter, PRIORITY)
-- MapObjects.OnLoadWithSprite("gutter_01_6", loadGutter, PRIORITY)

-- Events.OnLoad.Add(AddCustomSpriteProps)
-- Events.OnGameStart.Add(AddCustomSpriteProps)
-- Events.OnServerStarted.Add(AddCustomSpriteProps)

-- for spriteName, def in pairs(enums.pipeAtlas.type[enums.pipeType.gutter]) do
--     utils:modPrint("Adding gutter map object: "..spriteName)
--     MapObjects.OnNewWithSprite(spriteName, newGutter, PRIORITY)
--     MapObjects.OnLoadWithSprite(spriteName, loadGutter, PRIORITY)
-- end