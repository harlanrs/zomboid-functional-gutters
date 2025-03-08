require "TimedActions/ISBaseTimedAction"

local gutterOptions = require("FG_Options")
local gutterUtils = require("FG_Utils")
local gutterService = require("FG_Service")

FG_TA_DisconnectContainer = ISBaseTimedAction:derive("FG_TA_DisconnectContainer");

function FG_TA_DisconnectContainer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function FG_TA_DisconnectContainer:new(character, collectorObj, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.collectorObj = collectorObj;
	o.wrench = wrench;
	o.maxTime = o:getDuration();
	return o;
end

function FG_TA_DisconnectContainer:isValid()
	local requireWrench = gutterOptions:getRequireWrench()
	if requireWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function FG_TA_DisconnectContainer:update()
	self.character:faceThisObject(self.collectorObj)
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
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function FG_TA_DisconnectContainer:complete()
	if self.collectorObj then
		gutterService:resetCollectorObject(self.collectorObj)
        
        -- Re-evaluate if the container's square has a gutter pipe
        local square = self.collectorObj:getSquare()
        if square then
			gutterService:syncSquareModData(square)
        end
	else
		gutterUtils:modPrint("Failed to connect container: " .. tostring(self.collectorObj))
	end

	return true;
end