local enums = {}

enums.modName = "FunctionalGutters"
enums.modDisplayName = "Functional Gutters"
enums.drainPipeSprites = {
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

enums.options = {
    debug = "Debug",
    showContextUI = "ShowContextUI", -- Deprecated: rolled into debug
    gutterRainFactor = "GutterRainFactor",
    requireWrench = "RequireWrench",
}

-- Adding prefix to avoid potential namespace conflicts
-- and make it easier to find in generic search
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

return enums