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

function GetLightingExtrasForModelHash(modelHash, fleet)
    local result = {}
    for lightingName, data in pairs(fleet.lightingExtras) do
        local extra = nil

        -- Loop through the names in the data and try to find matching hash
        for modelName, extraData in pairs(data) do
            if modelHash == DevJacobLib.GetHash(modelName) then
                extra = extraData.extra
                break                
            end
        end

        result[lightingName] = extra
    end

    return result
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

if Config["DebugMode"] == true then
    local table_sort = table.sort
    function TableToString(table, options, _indent)
        options = options or {}
        if options.printFuncAsString == nil then options.printFuncAsString = false end
        if options.printBoolAsString == nil then options.printBoolAsString = false end
        if options.printNilAsString == nil then options.printNilAsString = false end
        if options.subNilForNull == nil then options.subNilForNull = false end
        if options.omitTrailingComma == nil then options.omitTrailingComma = false end
        if options.useColons == nil then options.useColons = false end

        _indent = _indent or 0

        local components = {
            ["number"] = {
                ["number"] = {},
                ["string"] = {},
                ["boolean"] = {},
                ["function"] = {},
                ["nil"] = {},
                ["table"] = {},
            },
            ["string"] = {
                ["number"] = {},
                ["string"] = {},
                ["boolean"] = {},
                ["function"] = {},
                ["nil"] = {},
                ["table"] = {},
            },
        }

        for key, value in pairs(table) do
            local keyType = type(key)
            if components[keyType] == nil then
                goto continue
            end

            local valueType = type(value)
            local currentLength = #components[keyType][valueType]

            components[keyType][valueType][currentLength + 1] = {
                key = key,
                value = value,
            }

            ::continue::
        end

        local sortFunc = function(a, b)
            return a.key < b.key
        end

        table_sort(components["number"]["number"], sortFunc)
        table_sort(components["number"]["string"], sortFunc)
        table_sort(components["number"]["boolean"], sortFunc)
        table_sort(components["number"]["function"], sortFunc)
        table_sort(components["number"]["nil"], sortFunc)
        table_sort(components["number"]["table"], sortFunc)
        
        table_sort(components["string"]["number"], sortFunc)
        table_sort(components["string"]["string"], sortFunc)
        table_sort(components["string"]["boolean"], sortFunc)
        table_sort(components["string"]["function"], sortFunc)
        table_sort(components["string"]["nil"], sortFunc)
        table_sort(components["string"]["table"], sortFunc)

        local specialTable = {
            [1] = components["number"]["number"],
            [2] = components["number"]["string"],
            [3] = components["number"]["boolean"],
            [4] = components["number"]["function"],
            [5] = components["number"]["nil"],
            [6] = components["string"]["number"],
            [7] = components["string"]["string"],
            [8] = components["string"]["boolean"],
            [9] = components["string"]["function"],
            [10] = components["string"]["nil"],
            [11] = components["number"]["table"],
            [12] = components["string"]["table"],
        }

        local definer = options.useColons == true and ": " or " = "
        local str = "{\r\n"
        _indent = _indent + 2
        for _1, items in ipairs(specialTable) do
            for itemIndex, item in ipairs(items) do
                local key = item.key
                local keyType = type(key)
                local value = item.value
                local valueType = type(value)

                str = str .. string.rep(" ", _indent)
            
                if (keyType == "number") then
                    str = str .. "[" .. key .. "]" .. definer
                elseif (keyType == "string") then
                    str = str .. key .. definer  
                end
            
                local lineEnd = (options.omitTrailingComma == true and itemIndex == #items) and "\r\n" or ",\r\n"
                if valueType == "number" then
                    str = str .. value .. lineEnd
                
                elseif valueType == "string" then
                    str = str .. "\"" .. value .. "\"" .. lineEnd
                
                elseif valueType == "table" then
                    str = str .. SparrowUtils.TableToString(value, options, _indent) .. lineEnd
                
                elseif valueType == "boolean" then
                    if options.printBoolAsString == true then
                        str = str .. "\"" .. tostring(value) .. "\"" .. lineEnd
                    else
                        str = str .. tostring(value) .. lineEnd
                    end

                elseif valueType == "function" then
                    if options.printFuncAsString == true then
                        str = str .. "\"" .. tostring(value) .. "\"" .. lineEnd
                    else
                        str = str .. tostring(value) .. lineEnd
                    end

                elseif valueType == "nil" then
                    local _val = options.subNilForNull == true and "null" or "nil"
                    if options.printNilAsString == true then
                        str = str .. "\"" .. _val .. "\"" .. lineEnd
                    else
                        str = str .. _val .. lineEnd
                    end

                else
                    str = str .. "\"" .. tostring(value) .. "\"" .. lineEnd
                end
            end
        end

        str = str .. string.rep(" ", _indent - 2) .. "}"
        return str
    end
end