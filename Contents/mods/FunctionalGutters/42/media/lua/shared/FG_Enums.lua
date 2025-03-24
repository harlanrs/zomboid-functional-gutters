local enums = {}

enums.modName = "FunctionalGutters"
enums.modDisplayName = "Functional Gutters"

enums.pipeType = {
    drain = "drain",
    vertical = "vertical",
    horizontal = "horizontal",
    gutter = "gutter",
}

enums.collectorType = {
    fluidContainer = "fluidContainer",
    trough = "trough",
}

enums.pipes = {
    -- Drain pipes
    -- Mostly used in water towers
    industry_02_76 = {
        type = enums.pipeType.drain,
        position = IsoDirections.W, -- verify
        facing = IsoDirections.E,
    }, -- drain facing east
    industry_02_77 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW, -- verify
        facing = IsoDirections.S,
    }, -- north drain facing south
    industry_02_78 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW, -- verify
        facing = IsoDirections.N,
    }, -- north drain facing north
    industry_02_79 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NE, -- verify
        facing = IsoDirections.W,
    }, -- drain facing west

    -- Vertical pipes with curve bottom
    -- industry_02_236 = {}, -- vertical pipes with curve bottom
    -- industry_02_237 = {},
    -- industry_02_240 = {},
    -- industry_02_241 = {},
    -- industry_02_242 = {},
    -- industry_02_244 = {},
    -- industry_02_245 = {},
    -- industry_02_246 = {},
    industry_02_260 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.S,
    }, -- nw corner | point south 
    industry_02_261 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.E,
    }, -- nw corner | point east
    industry_02_262 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.S,
    }, -- nw corner | point south
    industry_02_263 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.E,
    }, -- nw corner | point east

    --------------------------------------
    -- Vertical pipes 
    -- water tower
    -- industry_02_34 = {}, -- TBD

    -- Standard industrial
    industry_02_238 = {
        type = enums.pipeType.vertical,
        position = IsoDirections.NW,
        facing = nil,
    }, -- nw corner
    industry_02_239 = {
        type = enums.pipeType.vertical,
        position = IsoDirections.SE,
        facing = nil,
    }, -- se corner
    industry_02_243 = {
        type = enums.pipeType.vertical,
        position = IsoDirections.NE,
        facing = nil,
    }, -- ne corner
    industry_02_247 = {
        type = enums.pipeType.vertical,
        position = IsoDirections.SW,
        facing = nil,
    }, -- sw corner

    --------------------------------------
    -- Horizontal pipes
    -- Water tower
    industry_02_37 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.W,
        facing = nil,
    }, -- TODO verify
    industry_02_38 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.N,
        facing = nil,
    }, -- TODO verify north
    industry_02_226 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.W,
        facing = nil,
    }, -- TODO verify
    industry_02_230 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.W,
        facing = nil,
    }, -- TODO verify
    industry_02_224 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.N,
        facing = nil,
    },  -- TODO verify north
    industry_02_231 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.N,
        facing = nil,
    },   -- TODO verify north
    -- "roofs_06_6", -- roof gutter south
    -- "roofs_06_7", -- roof gutter east
    -- "roofs_06_21", -- roof south east corner small
    -- "roofs_06_20" -- roof north west corner large

    -- Custom sprites
    gutter_01_5 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.W,
        facing = nil,
    },
    gutter_01_6 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.N,
        facing = nil,
    },
    gutter_01_4 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.NW,
        facing = nil,
    },
    gutter_01_8 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.NW,
        facing = nil,
    },
}

local function mapPipesByType(pipeCategory)
    local categoryPipes = {}

    for spriteName, spriteDef in ipairs(enums.pipes) do
        if spriteDef.type == pipeCategory then
            categoryPipes[spriteName] = spriteDef
        end
    end

    return categoryPipes
end

local function mapPipesByPosition(position)
    local positionPipes = {}

    for spriteName, spriteDef in ipairs(enums.pipes) do
        if spriteDef.position == position then
            positionPipes[spriteName] = spriteDef
        end
    end

    return positionPipes
end

enums.drainPipeSprites = mapPipesByType(enums.pipeType.drain)

enums.verticalPipeSprites = mapPipesByType(enums.pipeType.vertical)

enums.horizontalPipeSprites = mapPipesByType(enums.pipeType.horizontal)

enums.gutterPipeSprites = mapPipesByType(enums.pipeType.gutter)

enums.pipeAtlas = {}
enums.pipeAtlas.type = {}
enums.pipeAtlas.type[enums.pipeType.drain] = enums.drainPipeSprites
enums.pipeAtlas.type[enums.pipeType.vertical] = enums.verticalPipeSprites
enums.pipeAtlas.type[enums.pipeType.horizontal] = enums.horizontalPipeSprites
enums.pipeAtlas.type[enums.pipeType.gutter] = enums.gutterPipeSprites

enums.pipeAtlas.position = {}
enums.pipeAtlas.position[IsoDirections.NW] = mapPipesByPosition(IsoDirections.NW)
enums.pipeAtlas.position[IsoDirections.NE] = mapPipesByPosition(IsoDirections.NE)
enums.pipeAtlas.position[IsoDirections.SW] = mapPipesByPosition(IsoDirections.SW)
enums.pipeAtlas.position[IsoDirections.SE] = mapPipesByPosition(IsoDirections.SE)

-- TODO auto source from FeedingTroughDef?
-- NOTE: 'accessories' is misspelled in sprite names
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

enums.customProps = {
    IsDrainPipe = "IsDrainPipe",
    IsVerticalPipe = "IsVerticalPipe",
    IsGutterPipe = "IsGutterPipe",
}

-- Adding prefix to avoid potential namespace conflicts
-- and make it easier to find in blanket search
enums.modDataKey = {
    hasGutter = "FG_hasGutter", -- TODO remove now that props are used
    hasVerticalPipe = "FG_hasVerticalPipe", -- TODO remove now that props are used
    hasHorizontalPipe = "FG_hasHorizontalPipe", -- TODO remove now that props are used
    hasGutterPipe = "FG_hasGutterPipe", -- TODO remove now that props are used
    baseRainFactor = "FG_baseRainFactor",
    isGutterConnected = "FG_isGutterConnected",
    isPipeConnected = "FG_isPipeConnected", -- TODO verify unused
    roofArea = "FG_roofArea",
    isRoofSquare = "FG_roofSquare",

    -- pipeConnectedUp
    -- pipeConnectedDown
    -- pipeConnectedNorth
    -- pipeConnectedSouth
    -- pipeConnectedEast
    -- pipeConnectedWest
    -- hasSlopedRoofNorth
    -- hasSlopedRoofWest
}

-- Keep for a bit to phase out
enums.oldModDataKey = {
    hasGutter = "hasGutter",
    baseRainFactor = "baseRainFactor",
    isGutterConnected = "isGutterConnected",
}

enums.troughBaseRainFactor = 0.55

enums.modCommands = {
    connectCollector = "connectCollector",
    disconnectCollector = "disconnectCollector",
}

enums.modEvents = {
    OnGutterTileUpdate ="OnGutterTileUpdate"
}

return enums