require "TimedActions/ISBaseTimedAction"

FG_TA_OpenGutterPanel = ISBaseTimedAction:derive("FG_TA_OpenGutterPanel")

function FG_TA_OpenGutterPanel:isValid()
    -- TODO swap for validate gutter object
    -- if self.container then
    --     return ISFluidUtil.validateContainer(self.container)
    -- end
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
		self.panelClass.OpenPanel(self.character, self.gutter, self.source)
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function FG_TA_OpenGutterPanel:new(character, _gutter, _panelClass, isSource)
	local o = ISBaseTimedAction.new(self, character)
    -- TODO
    -- if not ISFluidUtil.validateContainer(_gutter) then
    --     print("FG_TA_OpenGutterPanel not a valid (ISFluidContainer) container?")
    -- end
	o.gutter = _gutter;
	o.panelClass = _panelClass;
	o.source = isSource;
	o.maxTime = 10;
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end