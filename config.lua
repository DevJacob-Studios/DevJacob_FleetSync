Config = {}

Config["DebugMode"] = false

-- IN MS
Config["IdleTimeRequired"] = 5000

Config["CommanderRadius"] = 35.0

Config["VehicleFleets"] = {
    ["EXAMPLE_1"] = {
        copyExtras = false,
        lightingExtras = {},
        vehicles = {
            "car1",
            "car2",
            "car3",
        }
    },
    
    ["EXAMPLE_2"] = {
        copyExtras = true,
        lightingExtras = { 1, 4, 5 },
        vehicles = {
            "carA",
            "carB",
            "carC",
        }
    },
}