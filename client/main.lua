local canSync = false

-- Sync Thread
Citizen.CreateThread(function()
    local lastSyncEntity = nil
    local lastPos = vector3(0.0, 0.0, 0.0)
    local timeStill = 0

    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle == nil or lastSyncEntity ~= vehicle then
            lastSyncEntity = vehicle
            canSync = false
            goto continue
        end


        -- Check if the vehicle siren is on
        if IsVehicleSirenOn(vehicle) == false then
            canSync = false
            goto continue
        end

        -- Preset the last pos if it's 0, 0, 0
        if lastSyncEntity ~= vehicle then
            lastPos = GetEntityCoords(vehicle)
            timeStill = 0
        end

        -- Check if the vehicle is a fleet vehicle
        local fleetName, fleetData = GetModelHashFleet(GetEntityModel(vehicle))
        if fleetName == nil or fleetData == nil then 
            canSync = false
            goto continue
        end
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "FleetName = " .. fleetName)

        -- Check if the player has moved
        local currentPos = GetEntityCoords(vehicle)
        if #(currentPos - lastPos) <= 1.5 then
            timeStill = DevJacobLib.Ternary(timeStill >= Config["IdleTimeRequired"], timeStill, timeStill + 500)
        else
            timeStill = 0
        end

        lastPos = currentPos
        lastSyncEntity = vehicle
        canSync = timeStill >= Config["IdleTimeRequired"]
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "timeStill = " .. timeStill)
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "canSync = " .. DevJacobLib.Ternary(canSync, "true", "false"))

        ::continue::
    end
end)

-- Sync Thread
Citizen.CreateThread(function()
    local _promise = nil
    local syncedEntity = nil

    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then vehicle = nil end

        if canSync == false or syncedEntity ~= vehicle then
            if vehicle == nil then
                syncedEntity = nil
                goto continue
            end
            
            local _vehicleNetId = VehToNet(vehicle)
            _promise = promise.new()
            CallbackManager.TriggerServerCallback("DevJacob:FleetSync:Server:IsVehicleCommander", function(result)
                _promise:resolve(result)
            end, _vehicleNetId)
            local _isCommander = Citizen.Await(_promise)
            _promise = nil

            if _isCommander == true then
                TriggerServerEvent("DevJacob:FleetSync:Server:ReleaseVehicleAsCommander", _vehicleNetId)
            else 
                TriggerServerEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", _vehicleNetId)
            end
            
            syncedEntity = vehicle

            goto continue
        end

        if vehicle == nil then
            goto continue
        end

        -- Check if the vehicle is a fleet vehicle
        local fleetName, fleetData = GetModelHashFleet(GetEntityModel(vehicle))
        if fleetName == nil or fleetData == nil then 
            goto continue
        end
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "FleetName = " .. fleetName)

        -- Check if player's vehicle is a commander
        local vehicleNetId = VehToNet(vehicle)
        _promise = promise.new()
        CallbackManager.TriggerServerCallback("DevJacob:FleetSync:Server:IsVehicleCommander", function(result)
            _promise:resolve(result)
        end, vehicleNetId)
        local isPlayerVehCommander = Citizen.Await(_promise)
        _promise = nil
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "isPlayerVehCommander = " .. DevJacobLib.Ternary(isPlayerVehCommander, "true", "false"))

        -- Check if we have another fleet vehicle nearby
        local nearbyFleetVehs = GetFleetVehiclesInRange(fleetData, { vehicle })
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], "NearbyFleetVehs = " .. #nearbyFleetVehs)
        if nearbyFleetVehs == nil or #nearbyFleetVehs == 0 then
            if isPlayerVehCommander == false then
                TriggerServerEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", vehicleNetId)
            end
            goto continue
        end

        -- Ensure our commander exists if stored
        local syncedCommanderNetId = nil
        _promise = promise.new()
        CallbackManager.TriggerServerCallback("DevJacob:FleetSync:Server:GetCommanderForVehicle", function(result)
            _promise:resolve(result)
        end, vehicleNetId)
        local syncedCommanderNetId = Citizen.Await(_promise)
        _promise = nil

        if isPlayerVehCommander == true then
            goto continue
        end

        local isSynced = syncedCommanderId ~= nil
        local myPos = GetEntityCoords(vehicle)
        if isSynced then
            -- If we are synced, ensure we are within the radius of the commander
            local myCommanderPos = GetEntityCoords(myCommanderHandle)
            if isSynced and #(myCommanderPos - myPos) > Config["CommanderRadius"] then
                TriggerServerEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", vehicleNetId)
                goto continue
            end

        else
            -- Try to find the closest commander
            local closestCommanderNetId = nil
            local lastCommanderDist = math.huge
            for i = 1, #nearbyFleetVehs do
                local targetVeh = nearbyFleetVehs[i]
                local targetVehNetId = VehToNet(targetVeh)

                _promise = promise.new()
                CallbackManager.TriggerServerCallback("DevJacob:FleetSync:Server:IsVehicleCommander", function(result)
                    _promise:resolve(result)
                end, targetVehNetId)
                local targetIsCommander = Citizen.Await(_promise)
                _promise = nil
                DevJacobLib.Logger.DebugIf(Config["DebugMode"], "veh " .. targetVehNetId ..  " commander = " .. DevJacobLib.Ternary(targetIsCommander, "true", "false"))

                if targetIsCommander then
                    local targetPos = GetEntityCoords(targetVeh)
                    local dist = #(targetPos - myPos)
                    if dist < lastCommanderDist then
                        closestCommanderNetId = targetVehNetId
                        lastCommanderDist = dist
                    end
                end
            end
            
            -- If none in the radius is a commander, become one
            if closestCommanderNetId == nil then
                TriggerServerEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", vehicleNetId)
                goto continue
            end

            -- If we have a commander in range, sync to them
            if closestCommanderNetId ~= nil and closestCommanderNetId ~= syncedCommanderNetId then
                TriggerServerEvent("DevJacob:FleetSync:Server:SyncVehicleToCommander", vehicleNetId, closestCommanderNetId)
                goto continue
            end
        end
        
        ::continue::
    end
end)

RegisterNetEvent("DevJacob:FleetSync:Client:SyncVehicleNow", function(vehicleNetId, commanderNetId)
    DevJacobLib.Logger.Debug("Syncing to: " .. vehicleNetId)
    if not NetworkDoesEntityExistWithNetworkId(vehicleNetId) and not NetworkDoesEntityExistWithNetworkId(commanderNetId) then
        TriggerServerEvent("DevJacob:FleetSync:Server:DeadNetworkId", vehicleNetId)
        return
    end

    local vehicleHandle = NetToVeh(vehicleNetId)
    local commanderHandle = NetToVeh(commanderNetId)
    if not DoesEntityExist(vehicleHandle) and not DoesEntityExist(commanderHandle) then
        TriggerServerEvent("DevJacob:FleetSync:Server:DeadNetworkId", vehicleNetId)
        return
    end

    local commanderModel = GetEntityModel(commanderHandle)
    local fleetName, fleetData = GetModelHashFleet(commanderModel)
    local commanderExtraMap = GetLightingExtrasForModelHash(commanderModel, fleetData)
    local myExtraMap = GetLightingExtrasForModelHash(GetEntityModel(vehicleHandle), fleetData)

    -- If we mimic extras, do so now
    if fleetData.copyExtras == true and fleetData.lightingExtras then
        for lightingName, commanderExtra in pairs(commanderExtraMap) do
            local myExtra = myExtraMap[lightingName]

            if myExtra == nil then
                goto continue
            end

            if DoesExtraExist(commanderHandle, commanderExtra) and DoesExtraExist(vehicleHandle, myExtra) then
                SetVehicleExtra(vehicleHandle, myExtra, not IsVehicleExtraTurnedOn(commanderHandle, commanderExtra))
            end

            ::continue::
        end
    end

    SetVehicleSiren(vehicleHandle, false)
    SetVehicleSiren(vehicleHandle, true)
end)
