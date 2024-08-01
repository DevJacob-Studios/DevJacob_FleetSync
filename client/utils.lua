function GetModelHashFleet(modelHash)
    for fleetName, fleet in pairs(Config["VehicleFleets"]) do
        for i = 1, #fleet.vehicles do
            local vehicle = fleet.vehicles[i]
            if modelHash == DevJacobLib.GetHash(vehicle) then
                return fleetName, fleet
            end
        end
    end

    return nil, nil
end

function GetModelNameFleet(modelName)
    return GetModelHashFleet(DevJacobLib.GetHash(modelName))
end

function GetFleetVehiclesInRange(fleetData, excluded)
    excluded = excluded or {}
    local vehicles = {}

    local fleetModelHashes = {}
    for i = 1, #fleetData.vehicles do
        table.insert(fleetModelHashes, DevJacobLib.GetHash(fleetData.vehicles[i]))
    end
    
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)

    local nearby = DevJacobLib.GetNearbyVehicles(pedCoords, Config["CommanderRadius"], false)
    for i = 1, #nearby do
        local vehHandle = nearby[i].vehicle
        local vehModelHash = GetEntityModel(vehHandle)

        if DevJacobLib.Table.ArrayContainsValue(fleetModelHashes, vehModelHash) == true
            and DevJacobLib.Table.ArrayContainsValue(excluded, vehHandle) == false then
            table.insert(vehicles, vehHandle)
        end
    end

    return vehicles
end