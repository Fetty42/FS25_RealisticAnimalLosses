---@diagnostic disable: lowercase-global
-- Author: Fetty42
-- Date: 31.01.2025
-- Version: 1.0.0.0

local dbPrintfOn = false
local dbInfoPrintfOn = false

local function dbInfoPrintf(...)
	if dbInfoPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintf(...)
	if dbPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrint(...)
	if dbPrintfOn then
    	print(...)
	end
end

local function dbPrintHeader(funcName)
	if dbPrintfOn then
		if g_currentMission ~=nil and g_currentMission.missionDynamicInfo ~=nil then
			print(string.format("Call %s: isDedicatedServer=%s | isServer()=%s | isMasterUser=%s | isMultiplayer=%s | isClient()=%s | farmId=%s",
							funcName, tostring(g_dedicatedServer~=nil), tostring(g_currentMission:getIsServer()), tostring(g_currentMission.isMasterUser), tostring(g_currentMission.missionDynamicInfo.isMultiplayer), tostring(g_currentMission:getIsClient()), tostring(g_currentMission:getFarmId())))
		else
			print(string.format("Call %s: isDedicatedServer=%s | g_currentMission=%s",
							funcName, tostring(g_dedicatedServer~=nil), tostring(g_currentMission)))
		end
	end
end


RealisticAnimalLosses = {}; -- Class

-- global variables
RealisticAnimalLosses.dir = g_currentModDirectory
RealisticAnimalLosses.modName = g_currentModName

RealisticAnimalLosses.isInitSettingUI = false
RealisticAnimalLosses.settings = {}


-- configuration
RealisticAnimalLosses.riskAgeLossesRate = 10
RealisticAnimalLosses.riskWaterLossesRate = 15	-- increase the probability to loss animals for water
RealisticAnimalLosses.riskStrawLossesRate = 5	-- increase the probability to loss animals for straw

RealisticAnimalLosses.riskAnimalAgeInMonths = {HORSE=60, PIG=40, COW=50, SHEEP=30, CHICKEN=30, RABBIT=40, UNKNOWN=36}	-- currently the maximum age of animals in FS22 is 60 months/5 years
RealisticAnimalLosses.warningWaitingHours = 4
RealisticAnimalLosses.hourForAction = 18	-- each day

-- for the routine
RealisticAnimalLosses.numHoursAfterLastWarningAge = {}	-- [husbandry] = numHours
RealisticAnimalLosses.numHoursAfterLastWarningFood = {}	-- [husbandry] = numHours
RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForAge = {}	-- [husbandry] = maxProbability
RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood = {}	-- [husbandry] = maxProbability


function RealisticAnimalLosses:loadMap(name)
    dbPrintHeader("RealisticAnimalLosses:loadMap()")

	if g_currentMission:getIsServer() then
		dbPrintHeader("  - subscribe for event \"HOUR_CHANGED\"")
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, RealisticAnimalLosses.onHourChanged, self)
	end

	-- seed the random with a strongly varying seed
    math.randomseed(g_time or os.clock())
	-- math.randomseed(getDate("%S")+getDate("%M"))

	InGameMenu.onMenuOpened = Utils.appendedFunction(InGameMenu.onMenuOpened, RealisticAnimalLosses.initSettingUI)
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, RealisticAnimalLosses.saveSettings)

	RealisticAnimalLosses:loadSettings()
end


function RealisticAnimalLosses:defaultSettings()
	dbPrintHeader("RealisticAnimalLosses:defaultSettings")

	RealisticAnimalLosses.settings.foodEffectivityThreshold = 90	-- Threshold value for food effectivity below which the "losses rate" begins to increase
end


function RealisticAnimalLosses:saveSettings()
	dbPrintHeader("RealisticAnimalLosses:saveSettings")

	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "RealisticAnimalLosses.xml"
	local createXmlFile = modSettingsDir .. "/" .. fileName

	local xmlFile = createXMLFile("RealisticAnimalLosses", createXmlFile, "RealisticAnimalLosses")
	setXMLInt(xmlFile, "RealisticAnimalLosses.settings#foodEffectivityThreshold",RealisticAnimalLosses.settings.foodEffectivityThreshold)

	saveXMLFile(xmlFile)
	delete(xmlFile)
end


function RealisticAnimalLosses:loadSettings()
	dbPrintHeader("RealisticAnimalLosses:loadSettings")

	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "RealisticAnimalLosses.xml"
	local fileNamePath = modSettingsDir .. "/" .. fileName

	if fileExists(fileNamePath) then
		local xmlFile = loadXMLFile("RealisticAnimalLosses", fileNamePath)
		
		if xmlFile == 0 then
			dbPrintf("  Could not read the data from XML file (%s), maybe the XML file is empty or corrupted, using the default!", fileNamePath)
			RealisticAnimalLosses:defaultSettings()
			return
		end

		local foodEffectivityThreshold = getXMLInt(xmlFile, "RealisticAnimalLosses.settings#foodEffectivityThreshold")
		if foodEffectivityThreshold == nil or foodEffectivityThreshold == 0 then
			dbPrintf("  Could not parse the correct 'foodEffectivityThreshold' value from the XML file, maybe it is corrupted, using the default!")
			foodEffectivityThreshold = 4
		end
		RealisticAnimalLosses.settings.foodEffectivityThreshold = foodEffectivityThreshold

		delete(xmlFile)
	else
		RealisticAnimalLosses:defaultSettings()
		dbPrintf("  NOT any File founded!, using the default settings.")
	end
end


function RealisticAnimalLosses:initSettingUI()
	dbPrintHeader("RealisticAnimalLosses:initSettingUI")
	if not RealisticAnimalLosses.isInitSettingUI then
		local uiSettings = RealisticAnimalLossesUISettings.new(RealisticAnimalLosses.settings, true)
		uiSettings:registerSettings()
		RealisticAnimalLosses.isInitSettingUI = true
	end
end


function RealisticAnimalLosses:onHusbandryAnimalsChanged()
	dbPrintHeader("RealisticAnimalLosses:onHusbandryAnimalsChanged")
end

function RealisticAnimalLosses:onHusbandryAnimalsUpdate(clusters)
	dbPrintHeader("RealisticAnimalLosses:onHusbandryAnimalsUpdate")
end


function RealisticAnimalLosses:onHourChanged(hour)
	dbPrintHeader("RealisticAnimalLosses:onHourChanged")
	dbPrintf("  hour=%s", hour)

	-- check each cluster for healthy and food
	if g_currentMission:getIsServer() then
		-- for all husbandries, grouped by farms
		for _, farm in ipairs(g_farmManager:getFarms()) do
			if farm.showInFarmScreen then	-- only real farms (no FarmManager.SPECTATOR_FARM_ID or AccessHandler.EVERYONE or AccessHandler.NOBODY)
				CheckAllFarmHusbandries(farm.farmId, hour)
			end
		end
	end
end


function CheckAllFarmHusbandries(farmId, hour)
	dbPrintHeader("RealisticAnimalLosses:CheckAllFarmHusbandries")

	for _,husbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do
		local isWarningAge = false
		local isWarningFood = false
		local maxProbabilityToLossAnimalsForAge = 0
		local maxProbabilityToLossAnimalsForFood = 0
			local placeable = husbandry:getPlaceable()
		local placeableFarmId = placeable:getOwnerFarmId()
		if farmId == placeableFarmId then
			local placeableName = placeable:getName()
			local totalFood = placeable:getTotalFood()
			local foodEffectivity, isSequentiel = RealisticAnimalLosses:getFoodEffectivity(placeable)
			local spec_husbandryAnimals = placeable.spec_husbandryAnimals

			dbPrintf("  - husbandry placeables:  placeable farmId=%s | Name=%s | AnimalType=%s | NumOfAnimals=%s | TotalFood=%s | isSequentiel=%s | FoodEffectivity=%s | getNumOfClusters=%s",
				placeableFarmId, placeableName, husbandry.animalTypeName, placeable:getNumOfAnimals(), totalFood, tostring(isSequentiel), foodEffectivity, placeable:getNumOfClusters())

			-- if dbPrintfOn then
			-- 	local str = string.format("Check husbandry placeables: %s (farmId=%s)", placeableName, placeableFarmId)
			-- 	showIngameNotificationEvent.sendEvent(str, FSBaseMission.INGAME_NOTIFICATION_INFO, placeableFarmId)
			-- end

			local probability
			local sumNumRealisticAnimalLossesForAge = 0
			local sumNumRealisticAnimalLossesForFoodAndHealth = 0

			for idx, cluster in ipairs(placeable:getClusters()) do
				dbPrintf("    - Cluster:  numAnimals=%s | age=%s | health=%s | subTypeName=%s | subTypeTitle=%s"
				, cluster.numAnimals, cluster.age, cluster.health, g_currentMission.animalSystem.subTypes[cluster.subTypeIndex].name, g_currentMission.animalSystem.subTypes[cluster.subTypeIndex].visuals[1].store.name)

				-- check age
				local riskAnimalAge = RealisticAnimalLosses.riskAnimalAgeInMonths[husbandry.animalTypeName] or RealisticAnimalLosses.riskAnimalAgeInMonths["UNKNOWN"]
				if cluster.age >= riskAnimalAge then
					isWarningAge = true
					probability = RealisticAnimalLosses.riskAgeLossesRate / g_currentMission.environment.daysPerPeriod
					dbPrintf("      - check current animal age >= %s --> probability=%s%%", riskAnimalAge, probability)
					maxProbabilityToLossAnimalsForAge = math.max(maxProbabilityToLossAnimalsForAge, probability)

					-- Let some animals go away
					if cluster.age > riskAnimalAge and RealisticAnimalLosses.hourForAction == hour then	-- one day after the riskAnimalAge warning
						-- local riskFactor = 100 / RealisticAnimalLosses.riskAnimalAgeInMonths[husbandry.animalTypeName] * (cluster.age - riskAnimalAge + 1)
						-- local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, RealisticAnimalLosses.riskAgeLossesRate * riskFactor / g_currentMission.environment.daysPerPeriod)
						local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, probability)
						if numLostAnimals > 0 then
							local deleted = cluster:changeNumAnimals(numLostAnimals * -1)

							sumNumRealisticAnimalLossesForAge = sumNumRealisticAnimalLossesForAge + numLostAnimals
							dbPrintf("    --> Cluster: %s animals Losses for age", numLostAnimals)
						end
					end
				end

				-- check water
				local specWater = placeable.spec_husbandryWater
				local riskNoWater = 0
				if specWater ~= nil and not specWater.automaticWaterSupply and placeable:getHusbandryFillLevel(specWater.fillType, nil) == 0 then
					riskNoWater = RealisticAnimalLosses.riskWaterLossesRate
					dbPrintf("      - no water --> risk=%s%%", riskNoWater)
				end

				-- check straw
				local specStraw = placeable.spec_husbandryStraw
				local riskNoStraw = 0
				if specStraw ~= nil and placeable:getHusbandryFillLevel(specStraw.inputFillType, nil) == 0 then
					riskNoStraw = RealisticAnimalLosses.riskStrawLossesRate
					dbPrintf("      - no straw --> risk=%s%%", riskNoStraw)
				end

				-- check foodEffectivity and health
				-- cluster.healt: game logic - if foodEffectivity >= 40% then health = 100% else healt = 0%
				local riskForLessFoodEffectivity = 0
				if foodEffectivity < RealisticAnimalLosses.settings.foodEffectivityThreshold then
					-- local riskForLessFoodEffectivity = 0.001 * (100-foodEffectivity)^2.5 -2
					-- local riskForLessFoodEffectivity = 0.001 * (100-foodEffectivity)^2.5 -2 + 1 -- Range: 1.0 --> 68,7%
					-- local riskForLessFoodEffectivity = (100-foodEffectivity)^1.3*0.17+1 -- Range: 1.0 --> 68,7%
					local x = foodEffectivity / RealisticAnimalLosses.settings.foodEffectivityThreshold *100
					riskForLessFoodEffectivity = (100-x)^1.3*0.17+1 -- Range: 1.0 --> 68,7%
				end

				if riskForLessFoodEffectivity >= 1 then
					dbPrintf("      - low foodEffectivity=%s%% and health=%s%% --> risk per period=%s%%", foodEffectivity, cluster.health, riskForLessFoodEffectivity)
				end

				probability = (riskForLessFoodEffectivity + riskNoStraw + riskNoWater) / g_currentMission.environment.daysPerPeriod
				if probability > 0 then
					isWarningFood = true
					maxProbabilityToLossAnimalsForFood = math.max(maxProbabilityToLossAnimalsForFood, probability)

					-- Let some animals go away
					if RealisticAnimalLosses.hourForAction == hour then
						local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, probability)
						if numLostAnimals > 0 then
							local deleted = cluster:changeNumAnimals(numLostAnimals * -1)

							sumNumRealisticAnimalLossesForFoodAndHealth = sumNumRealisticAnimalLossesForFoodAndHealth + numLostAnimals
							dbPrintf("    --> Cluster: %s animals Losses for foodEffectivity and health", numLostAnimals)
						end
					end
				end
			end
				
			-- update visual animals and cluster
			if sumNumRealisticAnimalLossesForAge > 0 or sumNumRealisticAnimalLossesForFoodAndHealth > 0 then
						spec_husbandryAnimals.clusterSystem:updateNow()
				spec_husbandryAnimals:updateVisualAnimals()
			end

			-- display info or warning message for age
			if RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForAge[husbandry] == nil or RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] == nil then
				RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForAge[husbandry] = 0
				RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] = 99
			end
			if sumNumRealisticAnimalLossesForAge > 0 then
				local msgTxt = string.format(g_i18n:getText("txt_ageLossesMsg"), placeableName, sumNumRealisticAnimalLossesForAge, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, sumNumRealisticAnimalLossesForAge > 1))
				dbPrintf("  --> " .. msgTxt)
				showIngameNotificationEvent.sendEvent(msgTxt, FSBaseMission.INGAME_NOTIFICATION_CRITICAL, placeableFarmId)
				RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] = 1
			elseif isWarningAge and (RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] >= RealisticAnimalLosses.warningWaitingHours or RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForAge[husbandry] < maxProbabilityToLossAnimalsForAge) then
				-- display warning when no action has been taken but potential animals would have go away
				local msgTxt = string.format(g_i18n:getText("txt_riskInfoMsgAge"), placeableName, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, true), math.floor(maxProbabilityToLossAnimalsForAge + 0.99))
				dbPrint("  --> " .. msgTxt)
				showIngameNotificationEvent.sendEvent(msgTxt, FSBaseMission.INGAME_NOTIFICATION_INFO, farmId)
				RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] = 1
				RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForAge[husbandry] = maxProbabilityToLossAnimalsForAge
			else
				RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] = RealisticAnimalLosses.numHoursAfterLastWarningAge[husbandry] + 1
			end

			-- display info or warning message for food
			if RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood[husbandry] == nil or RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] == nil then
				RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood[husbandry] = 0
				RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] = 99
			end
			if sumNumRealisticAnimalLossesForFoodAndHealth > 0 then
				local msgTxt = string.format(g_i18n:getText("txt_foodLossesMsg"), placeableName, sumNumRealisticAnimalLossesForFoodAndHealth, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, sumNumRealisticAnimalLossesForFoodAndHealth > 1))
				dbPrintf("  --> " .. msgTxt)
				showIngameNotificationEvent.sendEvent(msgTxt, FSBaseMission.INGAME_NOTIFICATION_CRITICAL, placeableFarmId)
				RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] = 1
			elseif isWarningFood and (RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] >= RealisticAnimalLosses.warningWaitingHours or RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood[husbandry] < maxProbabilityToLossAnimalsForFood) then
				-- display warning when no action has been taken but potential animals would have go away
				local msgTxt = string.format(g_i18n:getText("txt_riskInfoMsgFood"), placeableName, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, true), math.floor(maxProbabilityToLossAnimalsForFood + 0.99))
				if RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood[husbandry] < maxProbabilityToLossAnimalsForFood then
					showIngameNotificationEvent.sendEvent(msgTxt, FSBaseMission.INGAME_NOTIFICATION_CRITICAL, farmId)
					g_currentMission:showBlinkingWarning(msgTxt, 8000)
				else
					showIngameNotificationEvent.sendEvent(msgTxt, FSBaseMission.INGAME_NOTIFICATION_INFO, farmId)
				end
				dbPrint("  --> " .. msgTxt)
				
				RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] = 1
				RealisticAnimalLosses.lastMaxProbabilityToLossAnimalsForFood[husbandry] = maxProbabilityToLossAnimalsForFood
			else
				RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] = RealisticAnimalLosses.numHoursAfterLastWarningFood[husbandry] + 1
			end
		end
	end
end


function RealisticAnimalLosses:probabilityCalculationNumOfHits(numOfTrials, probability)
	-- dbPrintHeader("RealisticAnimalLosses:probabilityCalculationNumOfHits")
	local numOfHits = 0

    for i=1, numOfTrials do
        local randomNumber = math.random(10000)
        if randomNumber <= (probability * 100) then
            numOfHits = numOfHits + 1
        end
    end

    return numOfHits
end


function RealisticAnimalLosses:getAnimalTitle(animalTypeName, isPlural)
	-- dbPrintHeader("RealisticAnimalLosses:getAnimalTitle")
	local singular = "animal"
	local plural = "animals"
	
	if animalTypeName == "HORSE" then
		singular, plural = string.match(g_i18n:getText("txt_horse"), "([^,]+),([^,]+)")
	elseif animalTypeName == "PIG" then
		singular, plural = string.match(g_i18n:getText("txt_pig"), "([^,]+),([^,]+)")
	elseif animalTypeName == "COW" then
		singular, plural = string.match(g_i18n:getText("txt_cow"), "([^,]+),([^,]+)")
	elseif animalTypeName == "SHEEP" then
		singular, plural = string.match(g_i18n:getText("txt_sheep"), "([^,]+),([^,]+)")
	elseif animalTypeName == "CHICKEN" then
		singular, plural = string.match(g_i18n:getText("txt_chicken"), "([^,]+),([^,]+)")
	else
		local animalType = g_currentMission.animalSystem:getTypeByName(animalTypeName)
		if animalType ~= nil then
			local animalName = animalType.groupTitle
			singular = animalName
			plural = animalName	-- no plural
		else
			singular = "animal"
			plural = "animals"
		end
	end

	local animalTitle = isPlural and plural or singular
	return animalTitle
end


function RealisticAnimalLosses:getFoodEffectivity(husbandry)
	-- dbPrintHeader("RealisticAnimalLosses:getFoodEffectivity")
	local effectivity = 0
    local specFood = husbandry.spec_husbandryFood
	local specMeadow = husbandry.spec_husbandryMeadow
	local isSequentiel = nil
	if specFood ~= nil and specFood.animalTypeIndex ~= nil then
		local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(specFood.animalTypeIndex)
		if animalFood ~= nil then
			isSequentiel = animalFood.consumptionType == 1
			for _, foodGroup in pairs(animalFood.groups) do
				-- local title = foodGroup.title
				local fillLevel = 0
				-- local capacity = spec.capacity
				for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
					if specFood.fillLevels[fillTypeIndex] ~= nil then
						fillLevel = fillLevel + specFood.fillLevels[fillTypeIndex]
					end
					if specMeadow ~= nil and specMeadow.fillLevels ~= nil and specMeadow.fillLevels[fillTypeIndex] ~= nil then
						dbPrintf("  - Meadow filltype (%s) found for food effectivity calculation (fill level=%s)", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), specMeadow.fillLevels[fillTypeIndex])
						fillLevel = fillLevel + specMeadow.fillLevels[fillTypeIndex]
						if specMeadow.fillLevels[fillTypeIndex] > 0  and foodGroup.productionWeight ~= specMeadow.productionWeight then
							dbPrintf("    - Attention: Meadow productionWeight (%s) ~= foodGroup productionWeight (%s) --> Using foodGroup productionWeight", specMeadow.productionWeight, foodGroup.productionWeight)
						end
					end
				end
				if fillLevel > 0 then
					if isSequentiel then
						effectivity = math.max(effectivity, MathUtil.round(foodGroup.productionWeight*100))
					else
						effectivity = effectivity + MathUtil.round(foodGroup.productionWeight*100)
					end
				end
			end
		end
	end
    return effectivity, isSequentiel
end


function RealisticAnimalLosses:registerActionEvents()end
function RealisticAnimalLosses:onLoad(savegame)end
function RealisticAnimalLosses:onUpdate(dt)end
function RealisticAnimalLosses:deleteMap()end
function RealisticAnimalLosses:keyEvent(unicode, sym, modifier, isDown)end
function RealisticAnimalLosses:mouseEvent(posX, posY, isDown, isUp, button)end

addModEventListener(RealisticAnimalLosses)

-- ----------------------------------------------------------------------------

showIngameNotificationEvent = {}
showIngameNotificationEvent_mt = Class(showIngameNotificationEvent, Event)
InitEventClass(showIngameNotificationEvent,"showIngameNotificationEvent")

function showIngameNotificationEvent.emptyNew()
	-- dbPrintHeader("showIngameNotificationEvent.emptyNew")
    local self = Event.new(showIngameNotificationEvent_mt)
    self.className = "showIngameNotificationEvent"
    return self
end

function showIngameNotificationEvent.new(msgTxt, notificationType, farmId)
	dbPrintHeader("showIngameNotificationEvent.new")
    local self = showIngameNotificationEvent.emptyNew()
    self.msgTxt = msgTxt
	self.notificationType = notificationType
    self.farmId = farmId
    return self
end;

function showIngameNotificationEvent:readStream(streamId, connection)
	dbPrintHeader("showIngameNotificationEvent:readStream")
	self.msgTxt = streamReadString(streamId)
	local notificationTypeAsString = streamReadString(streamId)
    self.farmId = streamReadInt8(streamId)

	-- convert string to enum
	self.notificationType = FSBaseMission.INGAME_NOTIFICATION_INFO
	if notificationTypeAsString == "FSBaseMission.INGAME_NOTIFICATION_CRITICAL" then
		self.notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
	elseif notificationTypeAsString == "FSBaseMission.INGAME_NOTIFICATION_WARNING" then
		self.notificationType = FSBaseMission.INGAME_NOTIFICATION_WARNING
	elseif notificationTypeAsString == "FSBaseMission.INGAME_NOTIFICATION_OK" then
		self.notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
	end

	self:run(connection)
end

function showIngameNotificationEvent:writeStream(streamId, connection)
    dbPrintHeader("showIngameNotificationEvent:writeStream")

	-- convert enum to string
	local notificationTypeAsString = "FSBaseMission.INGAME_NOTIFICATION_INFO"
	if self.notificationType == FSBaseMission.INGAME_NOTIFICATION_CRITICAL then
		notificationTypeAsString = "FSBaseMission.INGAME_NOTIFICATION_CRITICAL"
	elseif self.notificationType == FSBaseMission.INGAME_NOTIFICATION_WARNING then
		notificationTypeAsString = "FSBaseMission.INGAME_NOTIFICATION_WARNING"
	elseif self.notificationType == FSBaseMission.INGAME_NOTIFICATION_OK then
		notificationTypeAsString = "FSBaseMission.INGAME_NOTIFICATION_OK"
	end

	streamWriteString(streamId, self.msgTxt)
	streamWriteString(streamId, notificationTypeAsString)
    streamWriteInt8(streamId, self.farmId)
end

function showIngameNotificationEvent:run(connection)
	dbPrintHeader("showIngameNotificationEvent:run")
	g_currentMission:addIngameNotification(self.notificationType, self.msgTxt)
end

function showIngameNotificationEvent.sendEvent(msgTxt, notificationType, farmId)
    dbPrintHeader("showIngameNotificationEvent.sendEvent")

	if g_currentMission:getFarmId() == farmId and farmId ~= FarmManager.SPECTATOR_FARM_ID then
		g_currentMission:addIngameNotification(notificationType, msgTxt)
		dbPrintf("  --> open IngameNotification direct for farmId=%s", tostring(farmId))
	else
		g_currentMission:broadcastEventToFarm(showIngameNotificationEvent.new(msgTxt, notificationType, farmId), farmId, true)
		dbPrintf("  --> have sent broadcastEventToFarm to farmId=%s", tostring(farmId))
	end
end