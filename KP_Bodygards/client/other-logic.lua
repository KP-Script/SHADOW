local State = require("client/shared_state")
local ESX = exports["es_extended"]:getSharedObject()

local isDefensive = State.isDefensive
local weaponsEnabled = State.weaponsEnabled
local vehicleFollowEnabled = State.vehicleFollowEnabled

-- Helper to get guards and boss safely
local function getBossPed()
    return State.bossPed or PlayerPedId()
end

local function getGuards()
    return State.guards or {}
end

local function getConvoyVehicles()
    return State.convoyVehicles or {}
end

-- 📢 Regroup: Bring all guards to boss location
RegisterNetEvent("KP_bodyguard:regroupGuards", function()
    local bossCoords = GetEntityCoords(getBossPed())
    for _, guard in ipairs(getGuards()) do
        if DoesEntityExist(guard) then
            TaskGoToCoordAnyMeans(guard, bossCoords.x, bossCoords.y, bossCoords.z, 2.0, 0, 0, 786603, 0xbf800000)
        end
    end
    ESX.ShowNotification("~b~Guards regrouped at your position.")
end)

-- 🛡️ Toggle Defensive/Passive Mode
RegisterNetEvent("KP_bodyguard:toggleDefensiveMode", function()
    State.isDefensive = not State.isDefensive
    local isDefensive = State.isDefensive -- ✅ Updated value

    for _, guard in ipairs(getGuards()) do
        if DoesEntityExist(guard) then
            if isDefensive then
                SetPedCombatAttributes(guard, 46, true)
                SetPedCanRagdoll(guard, true)
            else
                ClearPedTasksImmediately(guard)
                SetPedCombatAttributes(guard, 46, false)
                SetPedCanRagdoll(guard, false)
                TaskStandStill(guard, -1)
            end
        end
    end

    ESX.ShowNotification("Defensive mode: " .. (isDefensive and "~g~ENABLED" or "~r~DISABLED"))
end)

-- 💉 Heal Guards
RegisterNetEvent("KP_bodyguard:healGuards", function()
    for _, guard in ipairs(getGuards()) do
        if DoesEntityExist(guard) then
            SetEntityHealth(guard, GetEntityMaxHealth(guard))
            ClearPedBloodDamage(guard)
        end
    end
    ESX.ShowNotification("~g~All guards healed.")
end)

-- 🔫 Toggle Weapons
RegisterNetEvent("KP_bodyguard:toggleWeapons", function()
    State.weaponsEnabled = not State.weaponsEnabled
    local weaponsEnabled = State.weaponsEnabled -- ✅ Updated value

    for _, guard in ipairs(getGuards()) do
        if DoesEntityExist(guard) then
            if weaponsEnabled then
                GiveWeaponToPed(guard, Config.GuardWeapon, 9999, true, true)
            else
                RemoveAllPedWeapons(guard, true)
            end
        end
    end

    ESX.ShowNotification("Weapons: " .. (weaponsEnabled and "~g~ENABLED" or "~r~DISABLED"))
end)


-- 🚘 Vehicle Follow Mode (Toggle On/Off)
RegisterNetEvent("KP_bodyguard:vehicleFollow", function()
    local boss = getBossPed()
    local convoy = getConvoyVehicles()

    -- 🚫 If follow already active, stop it
    if State.vehicleFollowEnabled then
        for _, entry in ipairs(convoy) do
            local driver = entry.guards and entry.guards[1]
            if DoesEntityExist(driver) then
                ClearPedTasks(driver)
            end
        end
        State.vehicleFollowEnabled = false
        ESX.ShowNotification("~r~Vehicle follow stopped.")
        return
    end

    -- ✅ Otherwise, start following
    if not IsPedInAnyVehicle(boss, false) then
        ESX.ShowNotification("~y~You must be in a vehicle to start escort.")
        return
    end

    local bossVeh = GetVehiclePedIsIn(boss, false)
    if not bossVeh then return end

    for _, entry in ipairs(convoy) do
        local veh = entry.vehicle
        local driver = entry.guards and entry.guards[1]
        if DoesEntityExist(veh) and DoesEntityExist(driver) and IsPedInAnyVehicle(driver, false) then
            TaskVehicleFollow(driver, veh, bossVeh, 25.0, 786603, 10.0)
        end
    end

    State.vehicleFollowEnabled = true
    ESX.ShowNotification("~b~Convoy now following your vehicle.")
end)