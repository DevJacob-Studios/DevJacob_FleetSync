local commanders = {}
local syncs = {}

RegisterNetEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", function(vehicleNetId)
    commanders[vehicleNetId] = true
    DevJacobLib.Logger.DebugIf(Config["DebugMode"], vehicleNetId .. " registered themselves as a commander")
end)

RegisterNetEvent("DevJacob:FleetSync:Server:ReleaseVehicleAsCommander", function(vehicleNetId)
    commanders[vehicleNetId] = nil
    for syncedVehNetId, commanderNetId in pairs(syncs) do
        if commanderNetId == netId then
            syncs[syncedVehNetId] = nil
        end
    end

    DevJacobLib.Logger.DebugIf(Config["DebugMode"], vehicleNetId .. " released themselves as a commander")
end)

RegisterNetEvent("DevJacob:FleetSync:Server:SyncVehicleToCommander", function(vehicleNetId, commanderNetId)
    syncs[vehicleNetId] = commanderNetId
    
    local targets = {}
    for syncedVehNetId, _commanderNetId in pairs(syncs) do
        if _commanderNetId == commanderNetId then
            local syncedVehEntity = NetworkGetEntityFromNetworkId(syncedVehNetId) 
            if DoesEntityExist(syncedVehEntity) then
                table.insert(targets, {
                    vehNetId = syncedVehNetId,
                    owner = NetworkGetEntityOwner(syncedVehEntity)
                })
            end
        end
    end

    local commanderEntity = NetworkGetEntityFromNetworkId(commanderNetId) 
    if DoesEntityExist(commanderEntity) then
        table.insert(targets, {
            vehNetId = commanderNetId,
            owner = NetworkGetEntityOwner(commanderEntity)
        })
    end

    for i = 1, #targets do
        local target = targets[i]
        TriggerClientEvent("DevJacob:FleetSync:Client:SyncVehicleNow", target.owner, target.vehNetId, commanderNetId)
        target = nil
    end
    targets = nil

    DevJacobLib.Logger.DebugIf(Config["DebugMode"], vehicleNetId .. " synced to commander id " .. commanderNetId)
end)

RegisterNetEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", function(vehicleNetId)
    if syncs[vehicelNetId] ~= nil then
        DevJacobLib.Logger.DebugIf(Config["DebugMode"], vehicleNetId .. " unsynced from commander id " .. commander)
    end

    syncs[vehicleNetId] = nil
end)

RegisterNetEvent("DevJacob:FleetSync:Server:DeadNetworkId", function(netId)
    commanders[netId] = nil
    for syncedVehNetId, commanderNetId in pairs(syncs) do
        if commanderNetId == netId or syncedVehNetId == netId then
            syncs[syncedVehNetId] = nil
        end
    end
end)

CallbackManager.RegisterServerCallback("DevJacob:FleetSync:Server:IsVehicleCommander", function(source, callback, vehicleNetId)
    callback(commanders[vehicleNetId] == true)
end)

CallbackManager.RegisterServerCallback("DevJacob:FleetSync:Server:GetCommanderForVehicle", function(source, callback, vehicleNetId)
    callback(syncs[vehicleNetId])
end)
