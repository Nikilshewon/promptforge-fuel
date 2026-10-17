-- promptforge-fuel | Author: PromptForge
local nuiOpen, refueling, menuVeh, menuPump = false, false, nil, nil
local pumps = {}
local electric, fuelTypeById, pumpHashes = {}, {}, {}
local ANIM_DICT, ANIM = 'timetable@gardener@filling_can', 'gar_ig_5_filling_can'
local minPrice = 9999

for _, n in ipairs(Config.ElectricVehicles) do electric[joaat(n)] = true end
for _, n in ipairs(Config.PumpModels) do pumpHashes[#pumpHashes + 1] = joaat(n) end
for _, t in ipairs(Config.FuelTypes) do
    fuelTypeById[t.id] = t
    if t.price < minPrice then minPrice = t.price end
end

---------------------------------------------------------------- fuel helpers
local function usesFuel(veh)
    return not Config.IgnoreClasses[GetVehicleClass(veh)] and not electric[GetEntityModel(veh)]
end

local function getFuel(veh)
    if not DoesEntityExist(veh) then return 0.0 end
    local f = Entity(veh).state.fuel
    if f == nil then
        f = math.random(Config.RandomFuel.min, Config.RandomFuel.max) + 0.0
        if NetworkHasControlOfEntity(veh) then Entity(veh).state:set('fuel', f, true) end
    end
    return f + 0.0
end

local function setFuel(veh, amount)
    amount = math.max(0.0, math.min(100.0, amount + 0.0))
    SetVehicleFuelLevel(veh, amount)
    if NetworkHasControlOfEntity(veh) then Entity(veh).state:set('fuel', amount, true) end
end

local function tankSize(veh)
    return Config.TankSize[GetVehicleClass(veh)] or Config.DefaultTank
end

exports('GetFuel', getFuel)
exports('SetFuel', setFuel)

---------------------------------------------------------------- consumption
CreateThread(function()
    local warned = false
    while true do
        Wait(1000)
        local veh = cache.vehicle
        if veh and cache.seat == -1 and usesFuel(veh) then
            local fuel = getFuel(veh)
            if GetIsVehicleEngineRunning(veh) then
                local use = (Config.Consumption.idle + GetVehicleCurrentRpm(veh) * Config.Consumption.rpm)
                    * (Config.ClassMultiplier[GetVehicleClass(veh)] or 1.0) * Config.Consumption.global
                fuel = fuel - use
                setFuel(veh, fuel)
            end
            if fuel <= 0.0 then
                SetVehicleEngineOn(veh, false, true, true)
            elseif fuel <= Config.LowFuelWarning and not warned then
                warned = true
                lib.notify({ type = 'warning', title = 'Fuel', description = 'Low fuel!' })
            elseif fuel > Config.LowFuelWarning then
                warned = false
            end
        end
    end
end)

---------------------------------------------------------------- neon 3D text
local function neonColor(t)
    local pal, n = Config.Text.colors, #Config.Text.colors
    local x = (t * Config.Text.speed) % n
    local i = math.floor(x)
    local f = x - i
    local a, b = pal[i + 1], pal[(i + 1) % n + 1]
    return { r = math.floor(a.r + (b.r - a.r) * f), g = math.floor(a.g + (b.g - a.g) * f), b = math.floor(a.b + (b.b - a.b) * f) }
end

local function layer(text, scale, r, g, b, a, edge)
    SetTextFont(Config.Text.font)
    SetTextScale(0.0, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    SetTextProportional(true)
    if edge then SetTextEdge(2, edge.r, edge.g, edge.b, 255) end
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
end

local function neonText(pos, text, size, col, dist, maxDist)
    local scale = size * math.max(0.35, 1.0 - (dist / maxDist) * 0.55)
    local pulse = 0.85 + 0.15 * math.sin(GetGameTimer() / 180.0)
    SetDrawOrigin(pos.x, pos.y, pos.z, 0)
    for i = 3, 1, -1 do -- glow layers
        layer(text, scale * (1.0 + i * 0.05), col.r, col.g, col.b, math.floor(30 * pulse))
    end
    layer(text, scale, 255, 255, 255, 255, col) -- bright core + neon edge
    ClearDrawOrigin()
end

CreateThread(function() -- pump scanner
    while true do
        local pc = GetEntityCoords(cache.ped)
        local found = {}
        for i = 1, #pumpHashes do
            local ent = GetClosestObjectOfType(pc.x, pc.y, pc.z, Config.TextDistance, pumpHashes[i], false, false, false)
            if ent ~= 0 then found[#found + 1] = ent end
        end
        pumps = found
        Wait(600)
    end
end)

CreateThread(function() -- pump text renderer
    while true do
        local sleep = 500
        if #pumps > 0 and not nuiOpen and not refueling then
            sleep = 0
            local pc = GetEntityCoords(cache.ped)
            local col = neonColor(GetGameTimer() / 1000.0)
            for i = 1, #pumps do
                local p = pumps[i]
                if DoesEntityExist(p) then
                    local pos = GetOffsetFromEntityInWorldCoords(p, 0.0, 0.0, Config.Text.height)
                    local dist = #(pc - pos)
                    if dist < Config.TextDistance then
                        neonText(pos, 'FUEL', 1.0, col, dist, Config.TextDistance)
                        neonText(vec3(pos.x, pos.y, pos.z - 0.28), ('FROM $%d / L'):format(minPrice), 0.42, col, dist, Config.TextDistance)
                        if Config.Text.light then
                            DrawLightWithRange(pos.x, pos.y, pos.z - 0.6, col.r, col.g, col.b, 5.0, 0.6)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

---------------------------------------------------------------- menu
local function closeMenu()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu(pump)
    if cache.vehicle then return lib.notify({ type = 'error', description = 'Exit your vehicle first' }) end
    local veh = lib.getClosestVehicle(GetEntityCoords(pump), Config.VehicleRange, false)
    if not veh or not usesFuel(veh) then return lib.notify({ type = 'error', description = 'No compatible vehicle near the pump' }) end
    if Config.RequireEngineOff and GetIsVehicleEngineRunning(veh) then
        return lib.notify({ type = 'error', description = 'Turn the engine off first' })
    end

    local money = lib.callback.await('promptforge-fuel:getMoney', false)
    local name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local label = GetLabelText(name)
    if label == 'NULL' then label = name end

    menuVeh, menuPump, nuiOpen = veh, pump, true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            model = label,
            spawn = name:lower(),
            imgUrl = Config.VehicleImageURL,
            plate = GetVehicleNumberPlateText(veh),
            fuel = getFuel(veh),
            tank = tankSize(veh),
            speed = math.floor(GetEntitySpeed(veh) * 3.6),
            temp = math.floor(GetVehicleEngineTemperature(veh)),
            fuelTypes = Config.FuelTypes,
            cash = money.cash, bank = money.bank, free = money.free,
        },
    })
end

RegisterNUICallback('close', function(_, cb) closeMenu() cb('ok') end)

---------------------------------------------------------------- hose
local nozzle, rope = nil, nil
local CAP_BONES = { 'petrolcap', 'petroltank', 'petroltank_l', 'petroltank_r' }

local function destroyHose()
    if rope then DeleteRope(rope) rope = nil RopeUnloadTextures() end
    if nozzle and DoesEntityExist(nozzle) then DeleteEntity(nozzle) end
    nozzle = nil
end

local function nozzleToHand()
    if not nozzle then return end
    local c = Config.Hose.hand
    DetachEntity(nozzle, true, true)
    AttachEntityToEntity(nozzle, cache.ped, GetPedBoneIndex(cache.ped, 18905), c.x, c.y, c.z, c.rx, c.ry, c.rz, true, true, false, true, 0, true)
end

local function nozzleToVehicle(veh)
    if not nozzle then return end
    DetachEntity(nozzle, true, true)
    local o, bone = Config.Hose.cap, -1
    for i = 1, #CAP_BONES do
        bone = GetEntityBoneIndexByName(veh, CAP_BONES[i])
        if bone ~= -1 then break end
    end
    if bone ~= -1 then
        AttachEntityToEntity(nozzle, veh, bone, o.x, o.y, o.z, o.rx, o.ry, o.rz, true, true, false, false, 0, true)
    else
        local min = GetModelDimensions(GetEntityModel(veh))
        AttachEntityToEntity(nozzle, veh, 0, min.x + 0.05, min.y * 0.35, 0.25, o.rx, o.ry, o.rz, true, true, false, false, 0, true)
    end
end

local function createHose(pump)
    local model = joaat(Config.Hose.nozzleModel)
    lib.requestModel(model)
    local pc = GetEntityCoords(cache.ped)
    nozzle = CreateObject(model, pc.x, pc.y, pc.z, true, true, true)
    nozzleToHand()

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do Wait(0) end
    local pp = GetOffsetFromEntityInWorldCoords(pump, 0.0, 0.0, Config.Hose.pumpHeight)
    rope = AddRope(pp.x, pp.y, pp.z, 0.0, 0.0, 0.0, 3.0, 1, 1000.0, 0.0, 1.0, false, true, false, 1.0, true, 0, 0, 0)
    ActivatePhysics(rope)
    Wait(100)
    local np = GetOffsetFromEntityInWorldCoords(nozzle, 0.0, -0.033, -0.0125)
    AttachEntitiesToRope(rope, pump, nozzle, pp.x, pp.y, pp.z, np.x, np.y, np.z, Config.Hose.length, false, false, '', '')
end

local function returnNozzle()
    if not nozzle then return end
    nozzleToHand()
    Wait(450)
    destroyHose()
end

---------------------------------------------------------------- refuel
local function startRefuel(veh, pump, typeId, liters, method)
    local ft = fuelTypeById[typeId]
    if not ft or not liters or liters <= 0 or not DoesEntityExist(veh) then return end
    if not lib.callback.await('promptforge-fuel:canAfford', false, typeId, liters, method) then
        return lib.notify({ type = 'error', description = 'Not enough money' })
    end

    refueling = true
    local tank, startFuel = tankSize(veh), getFuel(veh)
    local pumped, lastSync = 0.0, 0
    createHose(pump)
    Wait(500)
    nozzleToVehicle(veh)
    lib.requestAnimDict(ANIM_DICT)
    TaskPlayAnim(cache.ped, ANIM_DICT, ANIM, 2.0, 2.0, -1, 49, 0, false, false, false)

    while true do
        Wait(0)
        pumped = math.min(liters, pumped + Config.RefuelRate * GetFrameTime())
        local fuel = startFuel + pumped / tank * 100.0
        local full = false
        if fuel >= 100.0 then
            fuel, pumped, full = 100.0, (100.0 - startFuel) / 100.0 * tank, true
        end
        SetVehicleFuelLevel(veh, fuel)
        local now = GetGameTimer()
        if now - lastSync > 500 then setFuel(veh, fuel) lastSync = now end

        local vpos = GetEntityCoords(veh)
        local col = neonColor(now / 1000.0)
        local pos = vec3(vpos.x, vpos.y, vpos.z + 1.4)
        local dist = #(GetEntityCoords(cache.ped) - pos)
        neonText(pos, ('%d%%'):format(math.floor(fuel)), 1.0, col, dist, 12.0)
        neonText(vec3(pos.x, pos.y, pos.z - 0.3), ('+%.1f L   $%d'):format(pumped, math.floor(pumped * ft.price + 0.5)), 0.42, col, dist, 12.0)
        neonText(vec3(pos.x, pos.y, pos.z - 0.5), '[X] STOP', 0.34, col, dist, 12.0)

        if full or pumped >= liters then break end
        local far = DoesEntityExist(pump) and #(GetEntityCoords(cache.ped) - GetEntityCoords(pump)) > Config.Hose.maxDistance
        if far then lib.notify({ type = 'warning', description = 'Hose pulled too far' }) end
        if far or IsControlJustPressed(0, 73) or cache.vehicle or not DoesEntityExist(veh)
            or #(GetEntityCoords(cache.ped) - vpos) > Config.VehicleRange + 3.0 then break end
    end

    returnNozzle()
    ClearPedTasks(cache.ped)
    refueling = false
    if DoesEntityExist(veh) then setFuel(veh, startFuel + pumped / tank * 100.0) end

    if pumped > 0.05 then
        local paid = lib.callback.await('promptforge-fuel:charge', false, typeId, pumped, method)
        if paid then
            lib.notify({ type = 'success', title = 'Fuel', description = paid > 0 and ('Pumped %.1f L for $%d'):format(pumped, paid) or ('Pumped %.1f L'):format(pumped) })
        else
            if DoesEntityExist(veh) then setFuel(veh, startFuel) end
            lib.notify({ type = 'error', description = 'Payment failed' })
        end
    end
end

RegisterNUICallback('purchase', function(data, cb)
    cb('ok')
    local veh, pump = menuVeh, menuPump
    closeMenu()
    startRefuel(veh, pump, data.type, tonumber(data.liters), data.method)
end)

---------------------------------------------------------------- target + blips
exports.ox_target:addModel(Config.PumpModels, {
    {
        name = 'promptforge_fuel_pump',
        icon = 'fas fa-gas-pump',
        label = 'Use Fuel Pump',
        distance = 2.0,
        canInteract = function() return not refueling and not nuiOpen end,
        onSelect = function(data) openMenu(data.entity) end,
    },
})

CreateThread(function()
    if not Config.Blips.enabled then return end
    for _, c in ipairs(Config.Blips.coords) do
        local b = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(b, Config.Blips.sprite)
        SetBlipColour(b, Config.Blips.color)
        SetBlipScale(b, Config.Blips.scale)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.label)
        EndTextCommandSetBlipName(b)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if nuiOpen then SetNuiFocus(false, false) end
    if refueling then ClearPedTasks(cache.ped) end
    destroyHose()
end)
