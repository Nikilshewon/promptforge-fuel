-- promptforge-fuel | Author: PromptForge
local prices = {}
for _, t in ipairs(Config.FuelTypes) do prices[t.id] = t.price end

---------------------------------------------------------------- framework bridge
local FW, core

local function detect()
    if FW then return FW end
    local want = Config.Framework or 'auto'
    local function started(r) return GetResourceState(r) == 'started' end
    if want == 'auto' then
        if started('qbx_core') then want = 'qbox'
        elseif started('qb-core') then want = 'qbcore'
        elseif started('es_extended') then want = 'esx'
        else want = 'standalone' end
    end
    if want == 'qbcore' then core = exports['qb-core']:GetCoreObject()
    elseif want == 'esx' then core = exports['es_extended']:getSharedObject() end
    FW = want
    print(('[promptforge-fuel] framework: %s'):format(FW))
    return FW
end

local function getPlayer(src)
    local fw = detect()
    if fw == 'qbox' then return exports.qbx_core:GetPlayer(src)
    elseif fw == 'qbcore' then return core.Functions.GetPlayer(src)
    elseif fw == 'esx' then return core.GetPlayerFromId(src) end
end

local function getBalance(p, method)
    local fw = FW
    if fw == 'esx' then
        if method == 'cash' then return p.getMoney() end
        local acc = p.getAccount('bank')
        return acc and acc.money or 0
    end
    return p.PlayerData.money[method] or 0
end

local function removeMoney(p, method, amount)
    local fw = FW
    if fw == 'esx' then
        if method == 'cash' then p.removeMoney(amount, 'fuel-purchase') else p.removeAccountMoney('bank', amount, 'fuel-purchase') end
        return true
    end
    return p.Functions.RemoveMoney(method, amount, 'fuel-purchase')
end

local function isFree() return detect() == 'standalone' end

---------------------------------------------------------------- helpers
local function quote(typeId, liters)
    local price = prices[typeId]
    liters = tonumber(liters)
    if not price or not liters or liters < 0 then return nil end
    liters = math.min(liters, Config.MaxLitersPerPurchase)
    return math.floor(price * liters + 0.5)
end

local function validMethod(m) return m == 'cash' or m == 'bank' end

---------------------------------------------------------------- callbacks
lib.callback.register('promptforge-fuel:getMoney', function(src)
    if isFree() then return { cash = 0, bank = 0, free = true } end
    local p = getPlayer(src)
    if not p then return { cash = 0, bank = 0 } end
    return { cash = getBalance(p, 'cash'), bank = getBalance(p, 'bank') }
end)

lib.callback.register('promptforge-fuel:canAfford', function(src, typeId, liters, method)
    local amount = quote(typeId, liters)
    if not amount then return false end
    if isFree() then return true end
    if not validMethod(method) then return false end
    local p = getPlayer(src)
    return p and getBalance(p, method) >= amount or false
end)

lib.callback.register('promptforge-fuel:charge', function(src, typeId, liters, method)
    local amount = quote(typeId, liters)
    if not amount then return false end
    if isFree() or amount <= 0 then return 0 end
    if not validMethod(method) then return false end
    local p = getPlayer(src)
    if not p or getBalance(p, method) < amount then return false end
    if removeMoney(p, method, amount) then return amount end
    return false
end)
