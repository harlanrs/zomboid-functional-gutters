local enums = require("FG_Enums")

local options = {}
local modOptions = nil

local function loadModOptions()
    modOptions = PZAPI.ModOptions:create(enums.modName, enums.modDisplayName)

    -- NOTE: will eventually need to be a sandbox option for multiplayer
    options.roofRainFactorOption = modOptions:addSlider(enums.options.roofRainFactor,
        getText("UI_options_FunctionalGutters_" .. enums.options.roofRainFactor), 0.0, 2.0, 0.1, 1.0,
        getText("UI_options_FunctionalGutters_" .. enums.options.roofRainFactor .. "_tooltip"))

    -- NOTE: slider option doesn't appear to display the tooltip so including it again as a description
    modOptions:addDescription(getText("UI_options_FunctionalGutters_" .. enums.options.roofRainFactor .. "_tooltip"))

    -- NOTE: will eventually need to be a sandbox option for multiplayer
    options.requireWrench = modOptions:addTickBox(enums.options.requireWrench,
        getText("UI_options_FunctionalGutters_" .. enums.options.requireWrench), true,
        getText("UI_options_FunctionalGutters_" .. enums.options.requireWrench .. "_tooltip"))

    options.debugOption = modOptions:addTickBox(enums.options.debug,
        getText("UI_options_FunctionalGutters_" .. enums.options.debug), false,
        getText("UI_options_FunctionalGutters_" .. enums.options.debug .. "_tooltip"))
end

function options:getRoofRainFactor()
    -- TEMP until sandbox settings are implemented
    if isServer() then
        return 1.0
    end
    return self.roofRainFactorOption:getValue()
end

function options:getRequireWrench()
    -- TEMP until sandbox settings are implemented
    if isServer() then
        return true
    end
    return self.requireWrench:getValue()
end

function options:getDebug()
    -- TEMP until sandbox settings are implemented
    if isServer() then
        return false
    end
    return self.debugOption:getValue()
end

function options:getModOptions()
    return modOptions
end

Events.OnMainMenuEnter.Add(function()
    loadModOptions()
end)

return options
