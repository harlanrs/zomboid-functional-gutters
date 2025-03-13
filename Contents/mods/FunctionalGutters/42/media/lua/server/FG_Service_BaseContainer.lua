if isClient() then return end

require "ISBaseObject"

local BaseContainerServiceInterface = ISBaseObject:derive("BaseContainerServiceInterface");

BaseContainerServiceInterface.Type = "BaseContainerServiceInterface";

function BaseContainerServiceInterface:isObjectType(object)
    return false
end

function BaseContainerServiceInterface:connectContainer(object, roofArea)
    assert(false, "Not implemented")
end

function BaseContainerServiceInterface:disconnectContainer(object)
    assert(false, "Not implemented")
end

return BaseContainerServiceInterface;