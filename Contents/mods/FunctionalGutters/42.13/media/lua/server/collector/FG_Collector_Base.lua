if isClient() then return end

require "ISBaseObject"

local BaseCollectorServiceInterface = ISBaseObject:derive("BaseCollectorServiceInterface");

function BaseCollectorServiceInterface:isObjectType(object)
    return false
end

function BaseCollectorServiceInterface:connectCollector(object, gutterRainFactor)
    assert(false, "Not implemented")
end

function BaseCollectorServiceInterface:disconnectCollector(object)
    assert(false, "Not implemented")
end

return BaseCollectorServiceInterface;