local DrainPipeService = nil    -- will be set on server/game start
local VerticalPipeService = nil -- will be set on server/game start
local GutterPipeService = nil   -- will be set on server/game start

FG_BuildRecipeCode = {}
FG_BuildRecipeCode.pipe = {
    drain = {},
    vertical = {},
    horizontal = {},
    gutter = {},
}

function FG_BuildRecipeCode.pipe.drain.OnCreate(object)
    if not DrainPipeService then
        return
    end
    return DrainPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.drain.OnIsValid(params)
    if not DrainPipeService then
        return false
    end
    return DrainPipeService:onIsValid(params)
end

function FG_BuildRecipeCode.pipe.vertical.OnCreate(object)
    if not VerticalPipeService then
        return
    end
    return VerticalPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.vertical.OnIsValid(params)
    if not VerticalPipeService then
        return false
    end
    return VerticalPipeService:onIsValid(params)
end

function FG_BuildRecipeCode.pipe.gutter.OnCreate(object)
    if not GutterPipeService then
        return
    end
    return GutterPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.gutter.OnIsValid(params)
    if not GutterPipeService then
        return false
    end
    return GutterPipeService:onIsValid(params)
end

local function initializeServices()
    DrainPipeService = require("pipe/FG_Pipe_Drain")
    VerticalPipeService = require("pipe/FG_Pipe_Vertical")
    GutterPipeService = require("pipe/FG_Pipe_Gutter")
end

Events.OnServerStarted.Add(function()
    -- For mutli-player games
    initializeServices()
end)


Events.OnGameStart.Add(function()
    -- For single-player games
    initializeServices()
end)
