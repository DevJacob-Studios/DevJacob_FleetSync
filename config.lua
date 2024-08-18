Config = {
    --[[
        Enabled and disabled extra logging to the console
    ]]
    DebugMode = false,

    --[[
        The amount of time in ms that a car must be still for
        before it tries to sync or register as a commander
    ]]
    IdleTimeRequired = 5000,

    --[[
        The radius around the commander vehicle inside which
        other vehicles are looked for
    ]]
    CommanderRadius = 35.0,

    --[[
        The different fleets which define syncable vehicles.
    ]]
    VehicleFleets = {
        ["EXAMPLE_1"] = {  -- The name of the fleet, must be unique
            copyExtras = false,  -- If vehicles should attempt to copy extras from the commander
            lightingExtras = {}, -- The extra config, leave as '{}' when 'copyExtras' is false
            vehicles = {  -- The list of vehicle models which can sync with eachother
                "car1",
                "car2",
                "car3",
            }
        },
        
        ["EXAMPLE_2"] = {
            copyExtras = true,
            lightingExtras = {
                ["LIGHT_NAME_1"] = {  -- Plain text name for the lighting component, must be unique to this fleet
                    ["carA"] = { extra = 1 },  -- What extra on 'carA' controls 'LIGHT_NAME_1'
                    ["carB"] = { extra = 1 },  -- What extra on 'carB' controls 'LIGHT_NAME_1'
                    ["carC"] = { extra = 6 },  -- What extra on 'carC' controls 'LIGHT_NAME_1'
                },
                ["LIGHT_NAME_2"] = {  -- Plain text name for the lighting component, must be unique to this fleet
                    ["carA"] = { extra = 3 },  -- What extra on 'carA' controls 'LIGHT_NAME_2'
                    ["carB"] = { extra = 2 },  -- What extra on 'carB' controls 'LIGHT_NAME_2'
                    ["carC"] = { extra = 1 },  -- What extra on 'carC' controls 'LIGHT_NAME_2'
                }
            },
            vehicles = {
                "carA",
                "carB",
                "carC",
            }
        },
    }
}