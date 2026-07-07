-- Author: Fetty42

RealisticAnimalLossesSettingsEvent = {}
local RealisticAnimalLossesSettingsEvent_mt = Class(RealisticAnimalLossesSettingsEvent, Event)
InitEventClass(RealisticAnimalLossesSettingsEvent, "RealisticAnimalLossesSettingsEvent")

function RealisticAnimalLossesSettingsEvent.emptyNew()
	return Event.new(RealisticAnimalLossesSettingsEvent_mt)
end

function RealisticAnimalLossesSettingsEvent.new(foodEffectivityThreshold)
	local self = RealisticAnimalLossesSettingsEvent.emptyNew()
	self.foodEffectivityThreshold = foodEffectivityThreshold
	return self
end

function RealisticAnimalLossesSettingsEvent:readStream(streamId, connection)
	self.foodEffectivityThreshold = streamReadUInt8(streamId)
	self:run(connection)
end

function RealisticAnimalLossesSettingsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.foodEffectivityThreshold)
end

function RealisticAnimalLossesSettingsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, nil)
	end

	RealisticAnimalLosses.settings.foodEffectivityThreshold = self.foodEffectivityThreshold

	if g_currentMission:getIsServer() then
		RealisticAnimalLosses:saveSettings()
	end
end

function RealisticAnimalLossesSettingsEvent.sendEvent(noEventSend)
	if noEventSend then
		return
	end

	local event = RealisticAnimalLossesSettingsEvent.new(RealisticAnimalLosses.settings.foodEffectivityThreshold)
	if g_server ~= nil then
		g_server:broadcastEvent(event, nil, nil, nil)
	else
		g_client:getServerConnection():sendEvent(event)
	end
end
