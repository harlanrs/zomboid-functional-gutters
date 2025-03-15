require "TimedActions/ISBaseTimedAction"

local enums = require("FG_Enums")
local options = require("FG_Options")
local utils = require("FG_Utils")

FG_TA_DisconnectContainer = ISBaseTimedAction:derive("FG_TA_DisconnectContainer");

function FG_TA_DisconnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TA_DisconnectContainer:new(character, containerObject, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
	o.containerObject = containerObject
	o.wrench = wrench
	o.maxTime = o:getDuration()
	return o
end

function FG_TA_DisconnectContainer:isValid()
	if not options:getRequireWrench() then
		return true
	end

	return self.wrench and self.character:isEquipped(self.wrench)
end

function FG_TA_DisconnectContainer:update()
	self.character:faceThisObject(self.containerObject)
	self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function FG_TA_DisconnectContainer:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function FG_TA_DisconnectContainer:stop()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self);
end

function FG_TA_DisconnectContainer:perform()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.perform(self)
end

function FG_TA_DisconnectContainer:complete()
	if self.containerObject then
		local args = utils:buildObjectCommandArgs(self.containerObject)
		utils:modPrint("Sending client command disconnectCollector: " .. tostring(args))
		utils:modPrint("enum modCommands: "..tostring(enums.modCommands))
		sendClientCommand(self.character, enums.modName, enums.modCommands.disconnectCollector, args)
	else
		utils:modPrint("Failed to disconnect collector: " .. tostring(self.containerObject))
	end

	return true
end