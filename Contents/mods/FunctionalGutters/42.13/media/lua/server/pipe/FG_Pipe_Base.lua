local utils = require("FG_Utils")

local BasePipeServiceInterface = {}
BasePipeServiceInterface.Type = "BasePipeServiceInterface"

function BasePipeServiceInterface:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = type;
    return o
end

function BasePipeServiceInterface:isObjectType(object)
    return utils:isAnyPipeType(object)
end

function BasePipeServiceInterface:onCreate(createParams)
end

function BasePipeServiceInterface:onIsValid(buildParams)
    return false
end

function BasePipeServiceInterface:onRemove(object)
    assert(false, "not implemented")
end

return BasePipeServiceInterface;
