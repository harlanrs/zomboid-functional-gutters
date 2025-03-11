-- Action blueprint borrowed from a version of the Useful Barrels mod (https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035)

require "TimedActions/ISBaseTimedAction"

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")
-- local gutterService = require("FG_Service")

FG_TA_ConnectContainer = ISBaseTimedAction:derive("FG_TA_ConnectContainer");

function FG_TA_ConnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TA_ConnectContainer:new(character, containerObject, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
    o.containerObject = containerObject
	o.wrench = wrench
	o.maxTime = o:getDuration()
	return o
end

function FG_TA_ConnectContainer:isValid()
	local requireWrench = options:getRequireWrench()
	if requireWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function FG_TA_ConnectContainer:update()
	self.character:faceThisObject(self.containerObject)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function FG_TA_ConnectContainer:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function FG_TA_ConnectContainer:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function FG_TA_ConnectContainer:perform()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.perform(self)
end

function FG_TA_ConnectContainer:complete()
	if self.containerObject then
		local args = utils:buildObjectCommandArgs(self.containerObject)
		utils:modPrint("Sending client command connectContainer: " .. tostring(args))
		sendClientCommand(self.character, enums.modName, enums.modCommands.connectContainer, args)
	else
		utils:modPrint("Failed to connect container: " .. tostring(self.containerObject))
	end

	return true
end