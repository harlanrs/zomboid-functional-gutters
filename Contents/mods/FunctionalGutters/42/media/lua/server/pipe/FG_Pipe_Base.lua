if isClient() then return end

require "ISBaseObject"

local enums = require("FG_Enums")
local utils = require("FG_Utils")

local BasePipeServiceInterface = ISBaseObject:derive("BasePipeServiceInterface");

function BasePipeServiceInterface:isObjectType(object)
    return utils:isAnyPipeType(object)
end

function BasePipeServiceInterface:onCreate(object)
end

function BasePipeServiceInterface:onIsValid(buildParams)
    return false
end

function BasePipeServiceInterface:getAdjacentPipe(object, dir)
    -- TODO should this be a higher-level function?
    assert(false, "not implemented")
end

return BasePipeServiceInterface;



-- Base Methods
-- Get next pipe
-- Get previous pipe

-- type
-- def
-- find nearest connected drain -- todo utils for system as a whole