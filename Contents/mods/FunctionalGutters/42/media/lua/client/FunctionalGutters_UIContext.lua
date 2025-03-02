local gutterConfig = require("FunctionalGutters_Config")
require "gutterConfig"

local gutterUtils = require("FunctionalGutters_Utils")
require "gutterUtils"

local options = PZAPI.ModOptions:getOptions(gutterConfig.modName)
local showContextUIOption = options:getOption("ShowContextUI")
local showContextUI = showContextUIOption:getValue()

local function AddWaterContainerContext(player, context, worldobjects, test)
    if not showContextUI then return end

    for i,v in ipairs(worldobjects) do
        local fluidContainer = v:getFluidContainer()
        if fluidContainer and gutterUtils:isRainCollector(v) then
            local subMenuOption = context:addOption("["..gutterConfig.modName.."] "..v:getName(), getSpecificPlayer(player), nil);
            local subMenu = context:getNew(context)
            context:addSubMenu(subMenuOption, subMenu)

            local rainFactor = fluidContainer:getRainCatcher()
            subMenu:addOption("Rain Factor: " .. tostring(rainFactor), getSpecificPlayer(player), nil)

            local hasGutter = gutterUtils:hasGutterModData(v)
            subMenu:addOption("Has Gutter: " .. tostring(hasGutter), getSpecificPlayer(player), nil)
            break
        end
    end
end

Events.OnLoad.Add(function()
    -- Reload the showContextUI option
    showContextUI = showContextUIOption:getValue()
end)

Events.OnFillWorldObjectContextMenu.Add(AddWaterContainerContext)