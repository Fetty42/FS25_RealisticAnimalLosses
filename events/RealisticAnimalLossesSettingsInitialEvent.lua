-- Author: Fetty42

RealisticAnimalLossesSettingsInitialEvent = {}
local RealisticAnimalLossesSettingsInitialEvent_mt = Class(RealisticAnimalLossesSettingsInitialEvent, Event)
InitEventClass(RealisticAnimalLossesSettingsInitialEvent, "RealisticAnimalLossesSettingsInitialEvent")

function RealisticAnimalLossesSettingsInitialEvent.emptyNew()
	return Event.new(RealisticAnimalLossesSettingsInitialEvent_mt)
end

function RealisticAnimalLossesSettingsInitialEvent.new(foodEffectivityThreshold)
	local self = RealisticAnimalLossesSettingsInitialEvent.emptyNew()
	self.foodEffectivityThreshold = foodEffectivityThreshold
	return self
end

function RealisticAnimalLossesSettingsInitialEvent:readStream(streamId, connection)
	self.foodEffectivityThreshold = streamReadUInt8(streamId)
	self:run(connection)
end

function RealisticAnimalLossesSettingsInitialEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.foodEffectivityThreshold)
end

function RealisticAnimalLossesSettingsInitialEvent:run(connection)
	RealisticAnimalLosses.settings.foodEffectivityThreshold = self.foodEffectivityThreshold
end
