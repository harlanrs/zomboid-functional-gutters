local gutterConfig = {
    modName = "FunctionalGutters",
}

gutterConfig.enums = {}
gutterConfig.enums.drainPipeSprites = {
    "industry_02_260",
    "industry_02_261",
    "industry_02_263",
    -- TODO Add other drain pipe sprite identifiers
}
gutterConfig.enums.collectorSprites = {
    "carpentry_02_54",
    "carpentry_02_120",
    "carpentry_02_122",
    "carpentry_02_124",
}

gutterConfig.options = {
    Debug = nil,
    ShowContextUI = nil,
    GutterRainFactor = nil,
}

local options = PZAPI.ModOptions:create(gutterConfig.modName, "Functional Gutters")

gutterConfig.options.Debug = options:addTickBox("Debug", getText("UI_options_FunctionalGutters_Debug"), false, getText("UI_options_FunctionalGutters_Debug_tooltip"))
gutterConfig.options.ShowContextUI = options:addTickBox("ShowContextUI", getText("UI_options_FunctionalGutters_ShowContextUI"), true, getText("UI_options_FunctionalGutters_ShowContextUI_tooltip"))
gutterConfig.options.GutterRainFactor = options:addSlider("GutterRainFactor", getText("UI_options_FunctionalGutters_GutterRainFactor"), 0.5, 3.0, 0.1, 0.8, getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

-- NOTE: slider option doesn't appear to display the tooltip so we are including it as a description
-- Also not using getText for the description as it doesn't parse "\n" for newlines
options:addDescription("Rain factor value used by all collectors when connected to a gutter. \nDefaults to 0.8 compared to the crate's base of 0.4 and the barrel's base of 0.25.")

return gutterConfig