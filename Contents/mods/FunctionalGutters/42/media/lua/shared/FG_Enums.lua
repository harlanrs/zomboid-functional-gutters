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

enums.buildingType = {
    vanilla = "vanilla",
    custom = "custom",
}

enums.pipes = {
    -- Drain pipes
    -- Water tower
    industry_02_76 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.E,
    }, -- drain facing east
    industry_02_77 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.S,
    }, -- north drain facing south
    industry_02_78 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.N,
    }, -- north drain facing north
    industry_02_79 = {
        type = enums.pipeType.drain,
        position = IsoDirections.NW,
        facing = IsoDirections.W,
    }, -- drain facing west

    -- Standard industrial
    -- industry_02_236 = {}, -- long bottom | nw corner | point south
    -- industry_02_237 = {}, -- long bottom | nw corner | point east
    -- industry_02_240 = {}, -- long bottom
    -- industry_02_241 = {}, -- long bottom
    -- industry_02_242 = {}, -- long bottom
    -- industry_02_244 = {}, -- long bottom
    -- industry_02_245 = {}, -- long bottom
    -- industry_02_246 = {}, -- long bottom
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
        position = IsoDirections.NE,
        facing = IsoDirections.S,
    }, -- ne corner | point south
    industry_02_263 = {
        type = enums.pipeType.drain,
        position = IsoDirections.SW,
        facing = IsoDirections.E,
    }, -- sw corner | point east

    --------------------------------------
    -- Vertical pipes 
    -- Water tower
    industry_02_34 = {
        type = enums.pipeType.vertical,
        position = IsoDirections.NW,
        facing = nil,
    },

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
    -- industry_02_37 = {
    --     type = enums.pipeType.horizontal,
    --     position = IsoDirections.W,
    --     facing = nil,
    -- }, -- TODO verify
    -- industry_02_38 = {
    --     type = enums.pipeType.horizontal,
    --     position = IsoDirections.N,
    --     facing = nil,
    -- }, -- TODO verify north

    -- Standard industrial
    industry_02_226 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.N,
        facing = nil,
    },
    industry_02_230 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.S,
        facing = nil,
    },
    industry_02_224 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.W,
        facing = nil,
    },
    industry_02_231 = {
        type = enums.pipeType.horizontal,
        position = IsoDirections.E,
        facing = nil,
    },

    --------------------------------------
    -- Gutter pipes
    -- Custom sprites
    gutter_01_5 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.W,
        facing = nil,
        roofDirection = IsoDirections.W,
    },
    gutter_01_6 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.N,
        facing = nil,
        roofDirection = IsoDirections.N,
    },
    gutter_01_4 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.NW,
        facing = nil,
        roofDirection = nil,
    },
    gutter_01_8 = {
        type = enums.pipeType.gutter,
        position = IsoDirections.NW,
        facing = nil,
        roofDirection = IsoDirections.NW,
    },
}

enums.gutterAltBuildMap = {
    gutter_01_7 = "gutter_01_6",
    gutter_01_9 = "gutter_01_5",
    gutter_01_10 = "gutter_01_8",
    gutter_01_11 = "gutter_01_4",
}

local function mapPipesByType(pipeCategory)
    local categoryPipes = {}

    for spriteName, spriteDef in pairs(enums.pipes) do
        if spriteDef.type == pipeCategory then
            categoryPipes[spriteName] = spriteDef
        end
    end

    return categoryPipes
end

local function mapPipesByPosition(position)
    local positionPipes = {}

    for spriteName, spriteDef in pairs(enums.pipes) do
        if spriteDef.position == position then
            positionPipes[spriteName] = spriteDef
        end
    end

    return positionPipes
end

enums.pipeAtlas = {}
enums.pipeAtlas.type = {}
enums.pipeAtlas.type[enums.pipeType.drain] = mapPipesByType(enums.pipeType.drain)
enums.pipeAtlas.type[enums.pipeType.vertical] = mapPipesByType(enums.pipeType.vertical)
enums.pipeAtlas.type[enums.pipeType.horizontal] = mapPipesByType(enums.pipeType.horizontal)
enums.pipeAtlas.type[enums.pipeType.gutter] = mapPipesByType(enums.pipeType.gutter)

enums.pipeAtlas.position = {}
enums.pipeAtlas.position[IsoDirections.N] = mapPipesByPosition(IsoDirections.NW)
enums.pipeAtlas.position[IsoDirections.S] = mapPipesByPosition(IsoDirections.SE)
enums.pipeAtlas.position[IsoDirections.E] = mapPipesByPosition(IsoDirections.NE)
enums.pipeAtlas.position[IsoDirections.W] = mapPipesByPosition(IsoDirections.SW)
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

enums.woodenPoleSprite = "walls_exterior_wooden_01_27"

enums.options = {
    debug = "Debug",
    roofRainFactor = "RoofRainFactor",
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
    -- Collector object
    baseRainFactor = "FG_baseRainFactor",
    isGutterConnected = "FG_isGutterConnected",
    -- Drain square
    roofArea = "FG_roofArea",
    buildingType = "FG_buildingType",
    maxLevel = "FG_maxLevel",
    -- Drain object
    drainCleared = "FG_drainCleared",
    -- Roof square
    isRoofSquare = "FG_roofSquare",
}

-- Use to map old mod data keys to new keys (if needed during update)
enums.oldModDataKey = {}

enums.modCommands = {
    connectCollector = "connectCollector",
    disconnectCollector = "disconnectCollector",
}

enums.modEvents = {
    OnGutterTileUpdate ="OnGutterTileUpdate"
}

enums.troughBaseRainFactor = 0.55
enums.maxRoofCrawlSteps = 4
enums.maxGutterCrawlSteps = 36
enums.maxBuildingBoundCrawlSteps = 25
enums.defaultDrainPipeSearchRadius = 16
enums.defaultDrainPipeSearchHeight = 1
enums.gutterSectionPerimeterLength = 9
enums.gutterSectionCapacityRatio = 0.25
enums.gutterSectionOverflowEfficiency = 0.25

enums.textures = {}
enums.textures.build = {
    gutter = "media/textures/FG_Build_Pipe_Gutter.png",
    drain = "media/textures/FG_Build_Pipe_Drain.png",
    vertical = "media/textures/FG_Build_Pipe_Vertical.png",
    corner = "media/textures/FG_Build_Pipe_Corner.png",
    cornerSmall = "media/textures/FG_Build_Pipe_Corner_Small.png",
}
enums.textures.icon = {
    fluidDropOn = "media/ui/FG_Fluid_Drop_Icon.png",
    fluidDropOff = "media/ui/FG_Fluid_Drop_Icon_Off.png",
    plumbOn = "media/ui/FG_Plumb_Icon.png",
    plumbOff = "media/ui/FG_Plumb_Icon_Off.png",
    collectorOn = "media/ui/FG_Collector_Icon.png",
    collectorOff = "media/ui/FG_Collector_Icon_Off.png",
}

return enums