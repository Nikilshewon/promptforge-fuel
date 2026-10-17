-- promptforge-fuel | Author: PromptForge
Config = {}

-- 'auto' | 'qbox' | 'qbcore' | 'esx' | 'standalone'  (standalone = free refuelling, no money system)
Config.Framework = 'auto'

-- Pumps
Config.PumpModels = {
    'prop_gas_pump_1a', 'prop_gas_pump_1b', 'prop_gas_pump_1c', 'prop_gas_pump_1d',
    'prop_gas_pump_old2', 'prop_gas_pump_old3', 'prop_vintage_pump',
}
Config.VehicleRange     = 6.0    -- max distance pump -> vehicle
Config.RequireEngineOff = true
Config.RefuelRate       = 3.0    -- liters per second
Config.MaxLitersPerPurchase = 150

-- Tank sizes (liters) by vehicle class
Config.DefaultTank = 60.0
Config.TankSize = { [8] = 18.0, [9] = 80.0, [10] = 120.0, [11] = 80.0, [12] = 75.0, [18] = 70.0 }

-- Classes that never use fuel (cycles, boats, helis, planes, trains)
Config.IgnoreClasses = { [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }
Config.ElectricVehicles = { 'voltic', 'voltic2', 'neon', 'raiden', 'cyclone', 'cyclone2', 'tezeract', 'imorgon', 'iwagen', 'khamelion', 'surge', 'dilettante', 'omnisegt' }

-- Consumption: % per second = (idle + rpm * rpmFactor) * classMult * global
Config.Consumption = { idle = 0.004, rpm = 0.04, global = 1.0 }
Config.ClassMultiplier = { [0] = 1.0, [1] = 1.0, [2] = 1.1, [3] = 1.0, [4] = 1.3, [5] = 1.2, [6] = 1.3, [7] = 1.5, [8] = 0.7, [9] = 1.1, [10] = 1.6, [11] = 1.2, [12] = 1.2 }
Config.RandomFuel = { min = 35, max = 85 }
Config.LowFuelWarning = 15

-- Fuel types (price per liter). color = card accent in the NUI
Config.FuelTypes = {
    { id = 'diesel',  label = 'Diesel',   price = 10, color = '#ffb020' },
    { id = 'economic', label = 'Economic', price = 20, color = '#c040ff' },
    { id = 'super',   label = 'Super',    price = 30, color = '#3a8bff' },
    { id = 'premium', label = 'Super +',  price = 20, color = '#22e08a' },
}

-- Neon 3D text over pumps (colors cycle smoothly)
Config.TextDistance = 14.0
Config.Text = {
    font   = 4,
    height = 2.3,   -- above pump origin
    speed  = 0.35,  -- color cycle speed
    colors = {
        { r = 0,   g = 255, b = 240 },
        { r = 255, g = 0,   b = 200 },
        { r = 150, g = 90,  b = 255 },
    },
    light = true,   -- colored light glow on the pump
}

-- Blips
Config.Blips = {
    enabled = true, sprite = 361, color = 1, scale = 0.7, label = 'Gas Station',
    coords = {
        vec3(49.42, 2778.79, 58.04), vec3(263.89, -1261.31, 29.29), vec3(819.65, -1028.85, 26.40),
        vec3(1208.95, -1402.57, 35.22), vec3(-1437.62, -276.75, 46.21), vec3(-2096.24, -320.29, 13.17),
        vec3(-724.62, -935.16, 19.21), vec3(-526.02, -1211.00, 18.18), vec3(-70.21, -1761.79, 29.53),
        vec3(1181.38, -330.85, 69.32), vec3(620.84, 269.10, 103.09), vec3(2581.32, 362.04, 108.47),
        vec3(176.63, -1562.03, 29.26), vec3(2539.69, 2594.19, 37.94), vec3(2679.86, 3263.95, 55.24),
        vec3(1687.16, 4929.39, 42.08), vec3(1701.31, 6416.03, 32.76), vec3(-1800.38, 803.66, 138.65),
    },
}

-- Vehicle picture in the UI. Tries web/img/<spawnname>.png first, then this URL, then a built-in silhouette.
Config.VehicleImageURL = 'https://docs.fivem.net/vehicles/%s.webp'

-- Fuel hose (rope from pump -> nozzle -> vehicle fuel cap)
Config.Hose = {
    nozzleModel = 'prop_cs_fuel_nozle',
    pumpHeight  = 1.45,   -- where the hose leaves the pump
    length      = 6.0,    -- rope length
    maxDistance = 9.0,    -- walk further than this from the pump and the hose snaps back
    hand = { x = 0.24, y = 0.10, z = -0.052, rx = -45.0, ry = 120.0, rz = 75.0 },
    cap  = { x = 0.0,  y = 0.0,  z = 0.0,    rx = -90.0, ry = 0.0,   rz = 0.0 }, -- tune if the nozzle sits crooked
}
