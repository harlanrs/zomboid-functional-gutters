local BaseContainerServiceInterface = {};

BaseContainerServiceInterface.Type = "BaseContainerServiceInterface";

function BaseContainerServiceInterface:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
	o.Type= type;
    return o
end

function BaseContainerServiceInterface:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function BaseContainerServiceInterface:isObjectType(object)
    return false
end

function BaseContainerServiceInterface:connectContainer(object)
    assert(false, "Not implemented")
end

-- TODO use object instead of square
function BaseContainerServiceInterface:disconnectContainer(object)
    assert(false, "Not implemented")
end

return BaseContainerServiceInterface;