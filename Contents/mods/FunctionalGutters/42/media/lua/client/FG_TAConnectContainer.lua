-- Action blueprint borrowed from a version of the mod Useful Barrels (https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035)

require "TimedActions/ISBaseTimedAction"

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
local gutterService = require("FG_Service")

FG_TAConnectContainer = ISBaseTimedAction:derive("FG_TAConnectContainer");

function FG_TAConnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TAConnectContainer:new(character, containerObject, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
    o.containerObject = containerObject
	o.wrench = wrench
	o.maxTime = o:getDuration()
	return o
end

function FG_TAConnectContainer:isValid()
	local requireWrench = options:getRequireWrench()
	if requireWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function FG_TAConnectContainer:update()
	self.character:faceThisObject(self.containerObject)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function FG_TAConnectContainer:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function FG_TAConnectContainer:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function FG_TAConnectContainer:perform()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.perform(self)
end

function FG_TAConnectContainer:complete()
	if self.containerObject then
		-- TODO client -> server communication for eventual multiplayer support
		gutterService:connectContainer(self.containerObject)
	else
		utils:modPrint("Failed to connect container: " .. tostring(self.containerObject))
	end

	return true
end