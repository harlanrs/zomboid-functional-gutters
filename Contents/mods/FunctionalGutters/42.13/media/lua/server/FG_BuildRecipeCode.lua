local DrainPipeService = require("pipe/FG_Pipe_Drain")
local VerticalPipeService = require("pipe/FG_Pipe_Vertical")
local GutterPipeService = require("pipe/FG_Pipe_Gutter")

FG_BuildRecipeCode = {}
FG_BuildRecipeCode.pipe = {
    drain = {},
    vertical = {},
    horizontal = {},
    gutter = {},
}

function FG_BuildRecipeCode.pipe.drain.OnCreate(object)
    return DrainPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.drain.OnIsValid(params)
    return DrainPipeService:onIsValid(params)
end

function FG_BuildRecipeCode.pipe.vertical.OnCreate(object)
    return VerticalPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.vertical.OnIsValid(params)
    return VerticalPipeService:onIsValid(params)
end

function FG_BuildRecipeCode.pipe.gutter.OnCreate(object)
    return GutterPipeService:onCreate(object)
end

function FG_BuildRecipeCode.pipe.gutter.OnIsValid(params)
    return GutterPipeService:onIsValid(params)
end