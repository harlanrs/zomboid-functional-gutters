local enums = require("FG_Enums")

local options = {}
local modOptions = nil

local function loadModOptions()
    modOptions = PZAPI.ModOptions:create(enums.modName, enums.modDisplayName)

    options.roofRainFactorOption = modOptions:addSlider(enums.options.roofRainFactor, getText("UI_options_FunctionalGutters_"..enums.options.roofRainFactor), 0.0, 2.0, 0.1, 1.0, getText("UI_options_FunctionalGutters_"..enums.options.roofRainFactor.."_tooltip"))

    -- NOTE: slider option doesn't appear to display the tooltip so including it again as a description
    modOptions:addDescription(getText("UI_options_FunctionalGutters_"..enums.options.roofRainFactor.."_tooltip"))

    options.requireWrench = modOptions:addTickBox(enums.options.requireWrench, getText("UI_options_FunctionalGutters_"..enums.options.requireWrench), true, getText("UI_options_FunctionalGutters_"..enums.options.requireWrench.."_tooltip"))

    options.debugOption = modOptions:addTickBox(enums.options.debug, getText("UI_options_FunctionalGutters_"..enums.options.debug), false, getText("UI_options_FunctionalGutters_"..enums.options.debug.."_tooltip"))
end

function options:getRoofRainFactor()
    return self.roofRainFactorOption:getValue()
end

function options:getRequireWrench()
    return self.requireWrench:getValue()
end

function options:getDebug()
    return self.debugOption:getValue()
end

function options:getModOptions()
    return modOptions
end

Events.OnMainMenuEnter.Add(function()
    loadModOptions()
end)

return options