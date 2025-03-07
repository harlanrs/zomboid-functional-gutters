local gutterConfig = {
    modName = "FunctionalGutters",
}

gutterConfig.enums = {}
gutterConfig.enums.drainPipeSprites = {
    -- Mostly used in water towers
    "industry_02_76",
    "industry_02_77",
    "industry_02_78",
    "industry_02_79",

    -- Vertical pipes with curve bottom
    "industry_02_236",
    "industry_02_237",
    "industry_02_240",
    "industry_02_241",
    "industry_02_242",
    "industry_02_244",
    "industry_02_245",
    "industry_02_246",
    "industry_02_260",
    "industry_02_261",
    "industry_02_262",
    "industry_02_263",
}
gutterConfig.enums.collectorSprites = {
    -- Rain Collectors
    "carpentry_02_54",
    "carpentry_02_120",
    "carpentry_02_122",
    "carpentry_02_124",

    -- Amphora
    "crafted_04_32",
    "crafted_04_33",
}

gutterConfig.options = {
    Debug = nil,
    ShowContextUI = nil,
    GutterRainFactor = nil,
}

local options = PZAPI.ModOptions:create(gutterConfig.modName, "Functional Gutters")

gutterConfig.options.GutterRainFactor = options:addSlider("GutterRainFactor", getText("UI_options_FunctionalGutters_GutterRainFactor"), 0.5, 3.0, 0.1, 0.8, getText("UI_options_FunctionalGutters_GutterRainFactor_tooltip"))

-- NOTE: slider option doesn't appear to display the tooltip so we are including it as a description
-- Also not using getText for the description as it doesn't parse "\n" for newlines
options:addDescription("Rain factor value used by all collectors when connected to a gutter. \nDefaults to 0.8 compared to the crate's base of 0.4 and the barrel's base of 0.25.")

gutterConfig.options.Debug = options:addTickBox("Debug", getText("UI_options_FunctionalGutters_Debug"), false, getText("UI_options_FunctionalGutters_Debug_tooltip"))
gutterConfig.options.ShowContextUI = options:addTickBox("ShowContextUI", getText("UI_options_FunctionalGutters_ShowContextUI"), false, getText("UI_options_FunctionalGutters_ShowContextUI_tooltip"))


return gutterConfig