local enums = require("FG_Enums")

local options = {}

local function loadModOptions()
    local modOptions = PZAPI.ModOptions:create(enums.modName, enums.modDisplayName)

    options.gutterRainFactorOption = modOptions:addSlider("GutterRainFactor", getText("UI_options_FunctionalGutters_GutterRainFactor"), 1.0, 10.0, 0.1, 1.6, getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

    -- NOTE: slider option doesn't appear to display the tooltip so including it again as a description
    modOptions:addDescription(getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

    options.requireWrench = modOptions:addTickBox("RequireWrench", getText("UI_options_FunctionalGutters_RequireWrench"), true, getText("UI_options_FunctionalGutters_RequireWrench_tooltip"))

    options.debugOption = modOptions:addTickBox("Debug", getText("UI_options_FunctionalGutters_Debug"), false, getText("UI_options_FunctionalGutters_Debug_tooltip"))
end

function options:getGutterRainFactor()
    return self.gutterRainFactorOption:getValue()
end

function options:getRequireWrench()
    return self.requireWrench:getValue()
end

function options:getDebug()
    return self.debugOption:getValue()
end

function options:getModOptions()
    return options
end

Events.OnMainMenuEnter.Add(function()
    loadModOptions()
end)

return options