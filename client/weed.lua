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
		local ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_02'), 0, 0, 0)
		local nilCoords = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('nothingObject'), 0, 0, 0)
		local oldWeedCoords --, newWeedCoords
		local weedplotCoords = {}
		print ("Closest weed: " .. ClosestWeed)
		while ClosestWeed ~= nilCoords and ClosestWeed ~= nil do
			  print("deleting 02 plants.")
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
		  	ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_02'), 0, 0, 0)
		end
		ClosestWeed = nil
		ClosestWeed = GetClosestObjectOfType(weedCoords, 100.0, GetHashKey('prop_weed_01'), 1, 0, 0)
		while ClosestWeed ~= nilCoords and ClosestWeed ~= nil  do
			  print("deleting 01 plants.")
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

		while spawnedWeeds < 18 do
			  --print("spawnedWeeds: " .. spawnedWeeds .. "/18")
				Citizen.Wait(0)
				--if next(keyset) == nil then
				weedCoords = GenerateWeedCoords()
				--print("trying these coords: " .. weedCoords)
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
				--print("plant spawned.")
		end
end

function ValidateWeedCoord(plantCoord)
	if spawnedWeeds > 0 then
		local validate = true

		for k, v in pairs(weedPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 2 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.WeedField.coords, false) > 50 then
			validate = false
		end

    --print("validation: " .. tostring(validate))
		return validate
	else
		return true
	end
end

function GenerateWeedCoords()
	while true do
		Citizen.Wait(5)
    --print("generating coords")
		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-10, 10)
    --print("Generated modX: " .. modX .. " -- sleeping 100")

		Citizen.Wait(100)
		math.randomseed(GetGameTimer())
		local modY = math.random(-2, 2)
		--print("Generated modY: " .. modY)

		weedCoordX = Config.CircleZones.WeedField.coords.x + modX
		weedCoordY = Config.CircleZones.WeedField.coords.y + modY

		if weedCoordY == 5576 then
			  --print("modY is 5576... fixing.")
			  local x = 0
			  while true do
					  --print("x is: " .. x)
						math.randomseed(GetGameTimer())
				    Citizen.Wait(5)
					  x = math.random(-1, 3)
						if x == 1 then
								break
						elseif x == -2 then
								break
						elseif x == 3 then
								break
						end
			  end
				weedCoordY = weedCoordY + x
				--print("shifting plant " .. x)
	  elseif weedCoordY == 5578 then
			  --print("modY is 5578... fixing.")
		    local x = 0
		    while true do
					  --print("x is: " .. x)
						math.randomseed(GetGameTimer())
    				Citizen.Wait(5)
				    x = math.random(-3, 1)
						if x == 1 then
							  break
					  elseif x == -1 then
							  break
					  elseif x == -3 then
							  break
						end
		    end
				weedCoordY = weedCoordY + x
				--print("shifting plant " .. x)
	  end


		--2215 .. 2235 = 20 = 10x2
		--5574 .. 5580 = 6 = 3x2

		--2225 x 5577 x

		--print("getting coordZ.")
		local coordZ = GetCoordZ(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		--print("validating...")
		if ValidateWeedCoord(coord) then
			--print("returning " .. coord)
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 53.79, 53.8, 53.9, 54.0, 54.1, 54.2, 54.3}
	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 53.8
end
