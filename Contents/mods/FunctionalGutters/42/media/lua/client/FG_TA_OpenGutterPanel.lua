require "TimedActions/ISBaseTimedAction"

FG_TA_OpenGutterPanel = ISBaseTimedAction:derive("FG_TA_OpenGutterPanel")

function FG_TA_OpenGutterPanel:isValid()
    if not self.gutterDrain then
		return false
	end

    return true
end

function FG_TA_OpenGutterPanel:update()
end

function FG_TA_OpenGutterPanel:start()
end

function FG_TA_OpenGutterPanel:stop()
	ISBaseTimedAction.stop(self)
end

function FG_TA_OpenGutterPanel:perform()
	if self.panelClass and self.panelClass["OpenPanel"] then
		self.panelClass.OpenPanel(self.character, self.gutterDrain, self.source)
	end

	ISBaseTimedAction.perform(self)
end

function FG_TA_OpenGutterPanel:new(character, _gutterDrain, _panelClass, isSource)
	local o = ISBaseTimedAction.new(self, character)

	o.gutterDrain = _gutterDrain;
	o.panelClass = _panelClass;
	o.source = isSource;
	o.maxTime = 10;
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end