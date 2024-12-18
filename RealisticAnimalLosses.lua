-- Author: Fetty42
-- Date: 08.12.2024
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

local function dbPrintHeader(ftName)
	if dbPrintfOn then
    	print(string.format("Call %s", ftName))
    	-- print(string.format("Call %s: g_currentMission:getIsServer()=%s | g_currentMission:getIsClient()=%s", ftName, g_currentMission:getIsServer(), g_currentMission:getIsClient()))
	end
end



RealisticAnimalLosses = {}; -- Class

-- global variables
RealisticAnimalLosses.dir = g_currentModDirectory
RealisticAnimalLosses.modName = g_currentModName

-- configuration
RealisticAnimalLosses.noFoodLossesWaitingHours = 3

RealisticAnimalLosses.riskAgeLossesRate = 3
RealisticAnimalLosses.riskAgeLossesWaitingHours = 1
-- RealisticAnimalLosses.riskAnimalAgeInMonths = {HORSE=200, PIG=120, COW=160, SHEEP=80, CHICKEN=80}
RealisticAnimalLosses.riskAnimalAgeInMonths = {HORSE=60, PIG=60, COW=60, SHEEP=60, CHICKEN=60}	-- currently the maximum age of animals in FS22 is 60 months/5 years

RealisticAnimalLosses.warningWaitingHours = 8
RealisticAnimalLosses.hourForAction = 5		-- each first day in period

-- for the routine
RealisticAnimalLosses.numHoursAfterLastWarning = 99
RealisticAnimalLosses.clusterNumHoursWithoutFood = {}	-- {cluster, numHours}


function RealisticAnimalLosses:loadMap(name)
    dbPrintHeader("RealisticAnimalLosses:loadMap()")

	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, RealisticAnimalLosses.onHourChanged, RealisticAnimalLosses)
	-- g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    -- g_messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onHusbandryAnimalsChanged, self)
end


function RealisticAnimalLosses:onHourChanged(hour)
	dbPrintHeader("RealisticAnimalLosses:onHourChanged")
	dbPrintf("  hour=%s | farmId=%s", hour, g_currentMission:getFarmId())
	
	-- check each cluster for healthy and food
	local farmId = g_currentMission:getFarmId();
	local isWarningAge = false
	local isWarningFood = false
	local isLossesNotification = false
	local maxProabilityToLossAnimalsForAge = 0
	local maxProabilityToLossAnimalsForFood = 0

	for _,husbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do
		local placeable = husbandry:getPlaceable()
		if farmId~= nil and farmId ~= 0 and farmId ~= 15 and placeable.ownerFarmId == farmId then
			local placeableName = placeable:getName()
			local totalFood = placeable:getTotalFood()
			local foodEffectivity = RealisticAnimalLosses:getFoodEffectivity(placeable)

			
			local litersPerHour = 0
			if placeable.spec_husbandryFood ~= nil then
				litersPerHour = placeable.spec_husbandryFood.litersPerHour * g_currentMission.environment.timeAdjustment
			end

			dbPrintf("  - husbandry placeables:  Name=%s | AnimalType=%s | NumOfAnimals=%s | TotalFood=%s | FoodEffectivity=%s | getNumOfClusters=%s | litersPerHour=%s"
				, placeableName, husbandry.animalTypeName, placeable:getNumOfAnimals(), totalFood, foodEffectivity, placeable:getNumOfClusters(), litersPerHour)

			local proability
			local sumNumRealisticAnimalLossesForAge = 0
			local sumNumRealisticAnimalLossesForFood = 0


			for idx, cluster in ipairs(placeable:getClusters()) do
				dbPrintf("    - Cluster:  numAnimals=%s | age=%s | health=%s | subTypeName=%s | subTypeTitle=%s"
				, cluster.numAnimals, cluster.age, cluster.health, g_currentMission.animalSystem.subTypes[cluster.subTypeIndex].name, g_currentMission.animalSystem.subTypes[cluster.subTypeIndex].visuals[1].store.name)

				-- check age
				local riskAnimalAge = RealisticAnimalLosses.riskAnimalAgeInMonths[husbandry.animalTypeName]
				if cluster.age >= riskAnimalAge then
					isWarningAge = true
					proability = RealisticAnimalLosses.riskAgeLossesRate / g_currentMission.environment.daysPerPeriod
					maxProabilityToLossAnimalsForAge = math.max(maxProabilityToLossAnimalsForAge, proability)

					-- Let some animals go away
					if RealisticAnimalLosses.hourForAction == hour then
						-- local riskFactor = 100 / RealisticAnimalLosses.riskAnimalAgeInMonths[husbandry.animalTypeName] * (cluster.age - riskAnimalAge + 1)
						-- local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, RealisticAnimalLosses.riskAgeLossesRate * riskFactor / g_currentMission.environment.daysPerPeriod)
						local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, proability)
						if numLostAnimals > 0 then
							cluster.numAnimals = cluster.numAnimals - numLostAnimals
							sumNumRealisticAnimalLossesForAge = sumNumRealisticAnimalLossesForAge + numLostAnimals
							dbPrintf("    --> Cluster: %s aminals Losses for age", numLostAnimals)
						end
					end
				end

				-- check foodEffectivity and health
				proability = math.max(0, 100 - (foodEffectivity * 1.3 + cluster.health))
				dbPrintf("      - check foodEffectivity and health: foodEffectivity=%s | health=%s --> proability=%s", foodEffectivity, cluster.health, proability)
				if proability > 0 then
					isWarningFood = true
					proability = proability / g_currentMission.environment.daysPerPeriod
					maxProabilityToLossAnimalsForFood = math.max(maxProabilityToLossAnimalsForFood, proability)
	
					if RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] == nil then
						RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] = 1
					else
						RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] = RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] + 1
					end

					-- Let some animals go away
					if RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] >= RealisticAnimalLosses.noFoodLossesWaitingHours and RealisticAnimalLosses.hourForAction == hour then
						local numLostAnimals = RealisticAnimalLosses:probabilityCalculationNumOfHits(cluster.numAnimals, proability)
						if numLostAnimals > 0 then
							cluster.numAnimals = cluster.numAnimals - numLostAnimals
							sumNumRealisticAnimalLossesForFood = sumNumRealisticAnimalLossesForFood + numLostAnimals
							dbPrintf("    --> Cluster: %s aminals Losses for foodEffectivity and health", numLostAnimals)
						end
					end
					
				else
					RealisticAnimalLosses.clusterNumHoursWithoutFood[cluster] = 0
				end
				
				-- clean up
				if cluster.numAnimals <= 0 then
					table.remove(placeable:getClusters(), idx)
				end
			end

			if sumNumRealisticAnimalLossesForAge > 0 then
				local msgTxt = string.format(g_i18n:getText("txt_ageLossesMsg"), placeableName, sumNumRealisticAnimalLossesForAge, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, sumNumRealisticAnimalLossesForAge > 1))
				dbPrintf("  --> " .. msgTxt)
				g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgTxt)
				isLossesNotification = true
				RealisticAnimalLosses.numHoursAfterLastWarning = 0
			end

			-- if sumNumRealisticAnimalLossesForHealh > 0 then
			-- 	local msgTxt = string.format(g_i18n:getText("txt_healthLossesMsg"), placeableName, sumNumRealisticAnimalLossesForHealh, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, sumNumRealisticAnimalLossesForHealh > 1))
			-- 	dbPrintf("  --> " .. msgTxt)
			-- 	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgTxt)
			-- 	isLossesNotification = true
			-- 	RealisticAnimalLosses.numHoursAfterLastWarning = 0
			-- end
				
			if sumNumRealisticAnimalLossesForFood > 0 then
				local msgTxt = string.format(g_i18n:getText("txt_foodLossesMsg"), placeableName, sumNumRealisticAnimalLossesForFood, RealisticAnimalLosses:getAnimalTitle(husbandry.animalTypeName, sumNumRealisticAnimalLossesForFood > 1))
				dbPrintf("  --> " .. msgTxt)
				g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgTxt)
				isLossesNotification = true
				RealisticAnimalLosses.numHoursAfterLastWarning = 0
			end
		end
	end

	-- display warning when no action has been taken but potential animals would have go away
	if not isLossesNotification and RealisticAnimalLosses.numHoursAfterLastWarning >= RealisticAnimalLosses.warningWaitingHours then
		RealisticAnimalLosses.numHoursAfterLastWarning = 0

		if isWarningAge then
			local msgTxt = string.format(g_i18n:getText("txt_riskInfoMsgAge"), math.floor(maxProabilityToLossAnimalsForAge + 0.99))
			dbPrint("  --> " .. msgTxt)
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msgTxt)
		end
		if isWarningFood then
			local msgTxt = string.format(g_i18n:getText("txt_riskInfoMsgFood"), math.floor(maxProabilityToLossAnimalsForFood + 0.99))
			dbPrint("  --> " .. msgTxt)
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msgTxt)
		end
	else
		RealisticAnimalLosses.numHoursAfterLastWarning = RealisticAnimalLosses.numHoursAfterLastWarning + 1
	end
end


function RealisticAnimalLosses:probabilityCalculationNumOfHits(numOfTrials, proability)
	local numOfHits = 0

    for i=1, numOfTrials do
        local randomNumber = math.random(10000)
        if randomNumber <= (proability * 100) then
            numOfHits = numOfHits + 1
        end
    end

    return numOfHits
end


function RealisticAnimalLosses:getAnimalTitle(animalTypeName, isPlural)
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
	end

	local animalTitle = isPlural and plural or singular
	return animalTitle
end


function RealisticAnimalLosses:getFoodEffectivity(husbandry)
	local effectivity = 0
    local spec = husbandry.spec_husbandryFood
	if spec ~= nil and spec.animalTypeIndex ~= nil then
		local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(spec.animalTypeIndex)
		if animalFood ~= nil then
			for _, foodGroup in pairs(animalFood.groups) do
				-- local title = foodGroup.title
				local fillLevel = 0
				-- local capacity = spec.capacity
				for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
					if spec.fillLevels[fillTypeIndex] ~= nil then
						fillLevel = fillLevel + spec.fillLevels[fillTypeIndex]
					end
				end
				if fillLevel > 0 then
					effectivity = effectivity + MathUtil.round(foodGroup.productionWeight*100)
				end
				-- local info = {}
				-- info.title = string.format("%s (%d%%)", title, MathUtil.round(foodGroup.productionWeight*100))
				-- info.value = fillLevel
				-- info.capacity = capacity
				-- info.ratio = 0
				-- if capacity > 0 then
				--     info.ratio = fillLevel / capacity
				-- end
				-- table.insert(foodInfos, info)
			end
		end
	end
    return effectivity
end


function RealisticAnimalLosses:registerActionEvents()end
function RealisticAnimalLosses:onLoad(savegame)end
function RealisticAnimalLosses:onUpdate(dt)end
function RealisticAnimalLosses:deleteMap()end
function RealisticAnimalLosses:keyEvent(unicode, sym, modifier, isDown)end
function RealisticAnimalLosses:mouseEvent(posX, posY, isDown, isUp, button)end

addModEventListener(RealisticAnimalLosses)