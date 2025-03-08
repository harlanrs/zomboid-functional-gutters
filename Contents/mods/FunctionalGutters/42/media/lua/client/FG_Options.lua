local gutterEnums = require("FG_Enums")

require "PZAPI"

local gutterOptions = {}

local options = PZAPI.ModOptions:create(gutterEnums.modName, gutterEnums.modDisplayName)

gutterOptions.gutterRainFactorOption = options:addSlider("GutterRainFactor", getText("UI_options_FunctionalGutters_GutterRainFactor"), 0.5, 3.0, 0.1, 0.8, getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

-- NOTE: slider option doesn't appear to display the tooltip so we are including it again as a description
options:addDescription(getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

gutterOptions.requireWrench = options:addTickBox("RequireWrench", getText("UI_options_FunctionalGutters_RequireWrench"), true, getText("UI_options_FunctionalGutters_RequireWrench_tooltip"))


gutterOptions.debugOption = options:addTickBox("Debug", getText("UI_options_FunctionalGutters_Debug"), false, getText("UI_options_FunctionalGutters_Debug_tooltip"))
gutterOptions.showContextUIOption = options:addTickBox("ShowContextUI", getText("UI_options_FunctionalGutters_ShowContextUI"), false, getText("UI_options_FunctionalGutters_ShowContextUI_tooltip"))


function gutterOptions:getGutterRainFactor()
    return self.gutterRainFactorOption:getValue()
end

function gutterOptions:getRequireWrench()
    return self.requireWrench:getValue()
end

function gutterOptions:getDebug()
    return self.debugOption:getValue()
end

function gutterOptions:getShowContextUI()
    return self.showContextUIOption:getValue()
end

function gutterOptions:getModOptions()
    return options
end

return gutterOptions