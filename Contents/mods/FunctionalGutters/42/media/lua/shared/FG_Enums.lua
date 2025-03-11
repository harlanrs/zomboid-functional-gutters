local enums = {}

enums.modName = "FunctionalGutters"
enums.modDisplayName = "Functional Gutters"
enums.drainPipeSprites = table.newarray(
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
    "industry_02_263"
)

-- TODO auto source from FeedingTroughDef?
-- ugh 'accessories' is misspelled in sprite names
enums.troughSprites = table.newarray(
    "location_farm_accesories_01_4", -- Wood Double West
    "location_farm_accesories_01_5", -- Wood Double West
    "location_farm_accesories_01_6", -- Wood Double North
    "location_farm_accesories_01_7", -- Wood Double North
    "location_farm_accesories_01_14", -- Wood Single West
    "location_farm_accesories_01_15", -- Wood Single North
    "location_farm_accesories_01_34", -- Metal Double West
    "location_farm_accesories_01_35", -- Metal Double West
    "location_farm_accesories_01_32", -- Metal Double North
    "location_farm_accesories_01_33" -- Metal Double North
)

enums.smallTroughSprites = table.newarray(
    "location_farm_accesories_01_14", -- Wood Single West
    "location_farm_accesories_01_15" -- Wood Single North
)

enums.options = {
    debug = "Debug",
    showContextUI = "ShowContextUI", -- Deprecated: rolled into debug
    gutterRainFactor = "GutterRainFactor",
    requireWrench = "RequireWrench",
}

-- Adding prefix to avoid potential namespace conflicts
-- and make it easier to find in blanket search
enums.modDataKey = {
    hasGutter = "FG_hasGutter",
    baseRainFactor = "FG_baseRainFactor",
    isGutterConnected = "FG_isGutterConnected",
}

-- Keep for a bit to phase out
enums.oldModDataKey = {
    hasGutter = "hasGutter",
    baseRainFactor = "baseRainFactor",
    isGutterConnected = "isGutterConnected",
}

enums.containerType = {
    fluidContainer = "fluidContainer",
    trough = "trough",
}

enums.troughBaseRainFactor = 0.55

enums.modCommands = {
    connectContainer = "connectContainer",
    disconnectContainer = "disconnectContainer",
}

return enums