local spawnedWeeds = 0
local weedPlants = {}
local isPickingUp, isProcessing = false, false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		local coords = GetEntityCoords(PlayerPedId())

		if GetDistanceBetweenCoords(coords, Config.CircleZones.WeedField.coords, true) < 50 then
			SpawnWeedPlants()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.CircleZones.WeedProcessing.coords, true) < 1 then
			if not isProcessing then
				ESX.ShowHelpNotification(_U('weed_processprompt'))
			end

			if IsControlJustReleased(0, 46) and not isProcessing then   --This was 38 ( Made it work with a Gamepad - Jay <3 )
				if Config.LicenseEnable then
					ESX.TriggerServerCallback('esx_license:checkLicense', function(hasProcessingLicense)
						if hasProcessingLicense then
							ProcessWeed()
						else
							OpenBuyLicenseMenu('weed_processing')
						end
					end, GetPlayerServerId(PlayerId()), 'weed_processing')
				else
					ProcessWeed()
				end
			end
		else
			Citizen.Wait(500)
		end
	end
end)

function ProcessWeed()
	isProcessing = true

	ESX.ShowNotification(_U('weed_processingstarted'))
	TriggerServerEvent('esx_drugs:processCannabis')
	local timeLeft = Config.Delays.WeedProcessing / 1000
	local playerPed = PlayerPedId()

	while timeLeft > 0 do
		Citizen.Wait(1000)
		timeLeft = timeLeft - 1

		if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones.WeedProcessing.coords, false) > 4 then
			ESX.ShowNotification(_U('weed_processingtoofar'))
			TriggerServerEvent('esx_drugs:cancelProcessing')
			break
		end
	end

	isProcessing = false
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #weedPlants, 1 do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(weedPlants[i]), false) < 1 then
				nearbyObject, nearbyID = weedPlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then
			if not isPickingUp then
				ESX.ShowHelpNotification(_U('weed_pickupprompt'))
			end

			if IsControlJustReleased(0, 46) and not isPickingUp then  --This was 38 ( Made it work with a Gamepad - Jay <3 )
				isPickingUp = true

				ESX.TriggerServerCallback('esx_drugs:canPickUp', function(canPickUp)
					if canPickUp then
						TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)

						Citizen.Wait(2000)
						ClearPedTasks(playerPed)
						Citizen.Wait(1500)

						ESX.Game.DeleteObject(nearbyObject)

						table.remove(weedPlants, nearbyID)
						spawnedWeeds = spawnedWeeds - 1

						TriggerServerEvent('esx_drugs:pickedUpCannabis')
					else
						ESX.ShowNotification(_U('weed_inventoryfull'))
					end

					isPickingUp = false
				end, 'cannabis')
			end
		else
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(weedPlants) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnWeedPlants()

		-- altered quite a bit by Jay to make the plants grow in the plots within the outdoor weed farm
		local weedCoords = GenerateWeedCoords()
		local ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_02'), 1, 0, 0)
		local nilCoords = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('nothingObject'), 0, 0, 0)
		local oldWeedCoords --, newWeedCoords
		local weedplotCoords = {}
		print ("Closest weed: " .. ClosestWeed)
		while ClosestWeed ~= nilCoords and ClosestWeed ~= nil do
		    --if not IsEntityAMissionEntity(ClosestWeed) then
					  oldWeedCoords --[[ vector3 ]] = GetEntityCoords(ClosestWeed)
						--table.insert(weedplotCoords, oldWeedCoords)
						--print("INSERTED: " .. oldWeedCoords)
						SetEntityAsMissionEntity(ClosestWeed, true, true)
						ESX.Game.DeleteObject(ClosestWeed)
						print("Deleted 02 at: " .. oldWeedCoords)
			  --end

		  	Citizen.Wait(0)
				weedCoords = GenerateWeedCoords()
		  	ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_02'), 1, 0, 0)
		end
		ClosestWeed = nil
		ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_01'), 1, 0, 0)
		while ClosestWeed ~= nilCoords and ClosestWeed ~= nil  do
			  --if not IsEntityAMissionEntity(ClosestWeed) then
					  oldWeedCoords --[[ vector3 ]] = GetEntityCoords(ClosestWeed)
						--table.insert(weedplotCoords, oldWeedCoords)
						--print("INSERTED: " .. oldWeedCoords)
						SetEntityAsMissionEntity(ClosestWeed, true, true)
						ESX.Game.DeleteObject(ClosestWeed)
						print("Deleted 01 at: " .. oldWeedCoords)
			  --end
				Citizen.Wait(0)
				weedCoords = GenerateWeedCoords()
				ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_01'), 1, 0, 0)
		end
		ClosestWeed = nil
		--local prop_weed_table = {'prop_weed_01', 'prop_weed_02'}
		--[[local keyset = {}
		for k in pairs(weedplotCoords) do
        table.insert(keyset, k)
    end]]--

		while spawnedWeeds < 25 do
				Citizen.Wait(0)
				--if next(keyset) == nil then
				weedCoords = GenerateWeedCoords()
				--[[    print("Table was nil, generating new cords.")
				else
	    			weedCoords = weedplotCoords[keyset[math.random(#keyset)] ]
						print("Using weedplots to obtain coords for next weed plant.")
				end]]--
				print("generating plant #" .. spawnedWeeds .. " at " .. weedCoords)
			  ESX.Game.SpawnLocalObject('prop_weed_01', weedCoords, function(obj)
	  			  PlaceObjectOnGroundProperly(obj)
				    FreezeEntityPosition(obj, true)
				    SetEntityAsMissionEntity(obj, true, true)
	  			  table.insert(weedPlants, obj)
				    spawnedWeeds = spawnedWeeds + 1
	  		end)
		end
end

function ValidateWeedCoord(plantCoord)
	if spawnedWeeds > 0 then
		local validate = true

		for k, v in pairs(weedPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.WeedField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateWeedCoords()
	while true do
		Citizen.Wait(1)

		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-8, 8)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-2, 2)

		weedCoordX = Config.CircleZones.WeedField.coords.x + modX
		weedCoordY = Config.CircleZones.WeedField.coords.y + modY

		--2215 .. 2235 = 20 = 10x2
		--5574 .. 5580 = 6 = 3x2

		--2225 x 5577 x

		local coordZ = GetCoordZ(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		if ValidateWeedCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 52.68, 52.69, 52.70, 52.71, 52.72, 52.73, 52.74, 52.75, 52.76, 52.77, 52.78, 52.79, 52.80, 52.81, 52.82, 52.83, 52.84, 52.85, 52.86, 52.87, 52.88, 52.89, 52.90, 52.91, 52.92, 52.93, 52.94, 52.95, 52.96, 52.97, 52.98, 52.99, 53.00, 53.01, 53.02, 53.03, 53.04, 53.05 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 43.0
end
