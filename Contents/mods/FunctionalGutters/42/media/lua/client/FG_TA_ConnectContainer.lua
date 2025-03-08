-- Action blueprint borrowed from the the mod Useful Barrels (https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035)

require "TimedActions/ISBaseTimedAction"

local gutterOptions = require("FG_Options")
local gutterUtils = require("FG_Utils")
local gutterService = require("FG_Service")

FG_TA_ConnectContainer = ISBaseTimedAction:derive("FG_TA_ConnectContainer");

function FG_TA_ConnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TA_ConnectContainer:new(character, collectorObj, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.collectorObj = collectorObj;
	o.wrench = wrench;
	o.maxTime = o:getDuration();
	return o;
end

function FG_TA_ConnectContainer:isValid()
	local requireWrench = gutterOptions:getRequireWrench()
	if requireWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function FG_TA_ConnectContainer:update()
	self.character:faceThisObject(self.collectorObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function FG_TA_ConnectContainer:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function FG_TA_ConnectContainer:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function FG_TA_ConnectContainer:perform()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.perform(self);
end

function FG_TA_ConnectContainer:complete()
	if self.collectorObj then
		-- TODO explore client -> server communication for eventual multiplayer support
		local square = self.collectorObj:getSquare()
		if square then
			local squareModData = gutterService:syncSquareModData(square)
			if not squareModData["hasGutter"] then
				gutterUtils:modPrint("Failed to connect container - no gutter found on tile: " .. tostring(self.collectorObj))
				return true
			end

			gutterService:upgradeCollectorObject(self.collectorObj)
		end
	else
		gutterUtils:modPrint("Failed to connect container: " .. tostring(self.collectorObj))
	end

	return true;
end