require "TimedActions/ISBaseTimedAction"

local options = require("FG_Options")
local utils = require("FG_Utils")
local gutterService = require("FG_Service")

FG_TADisconnectContainer = ISBaseTimedAction:derive("FG_TADisconnectContainer");

function FG_TADisconnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TADisconnectContainer:new(character, containerObject, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
    o.containerObject = containerObject
	o.wrench = wrench
	o.maxTime = o:getDuration()
	return o
end

function FG_TADisconnectContainer:isValid()
	local requireWrench = options:getRequireWrench()
	if requireWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function FG_TADisconnectContainer:update()
	self.character:faceThisObject(self.containerObject)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function FG_TADisconnectContainer:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function FG_TADisconnectContainer:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function FG_TADisconnectContainer:perform()
	self.character:stopOrTriggerSound(self.sound)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function FG_TADisconnectContainer:complete()
	if self.containerObject then
		-- TODO client -> server communication for eventual multiplayer support
		gutterService:disconnectContainer(self.containerObject)
        
        -- Re-evaluate if the container's square has a gutter pipe
        local square = self.containerObject:getSquare()
        if square then
			gutterService:syncSquareModData(square)
        end
	else
		utils:modPrint("Failed to disconnect container: " .. tostring(self.containerObject))
	end

	return true
end