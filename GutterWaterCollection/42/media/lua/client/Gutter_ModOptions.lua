local config = {
    modName = "GutterWaterCollection",
    options = {
        Debug = false,
        GutterMultiplier = 3.0,
    },
    enums = {
        drainPipeSprites = {
            "industry_02_260",
            "industry_02_261",
            "industry_02_263",
            -- TODO Add other drain pipe sprite identifiers
        },
        collectorSprites = {
            "carpentry_02_54",
            "carpentry_02_120",
            "carpentry_02_122",
            "carpentry_02_124",
        }
    },
}

local options = PZAPI.ModOptions:create(config.modName, "Gutter Water Collection")

config.options.Debug = options:addTickBox("Debug", getText("UI_options_GutterWaterCollection_Debug"), false, getText("UI_options_GutterWaterCollection_Debug_tooltip"))
config.options.GutterMultiplier = options:addSlider("GutterMultiplier", getText("UI_options_GutterWaterCollection_GutterMultiplier"), 0.0, 10.0, 0.5, 3.0, getText("UI_options_GutterWaterCollection_GutterMultiplier_tooltip"))

return config