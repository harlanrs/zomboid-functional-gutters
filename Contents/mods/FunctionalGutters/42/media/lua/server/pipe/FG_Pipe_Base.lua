if isClient() then return end

require "ISBaseObject"

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

function BasePipeServiceInterface:onRemove(object)
    assert(false, "not implemented")
end

return BasePipeServiceInterface;
