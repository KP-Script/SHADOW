local spawnedReinforcements = {}

RegisterNetEvent("shadowcartel_guard:spawnReinforcements", function(coords)
    for _, loc in pairs(Config.reinforcments.Spawns) do
        local model = `mp_m_freemode_01`
        local vehModel = Config.reinforcments.vehicle or `sandking`
        RequestModel(model)
        RequestModel(vehModel)
        while not HasModelLoaded(model) or not HasModelLoaded(vehModel) do Wait(100) end

        local vehicle = CreateVehicle(vehModel, loc.x, loc.y, loc.z, 0.0, true, false)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, "CARTEL")

        local peds = {}
        for i = -1, 2 do
            local ped = CreatePedInsideVehicle(vehicle, 4, model, i, true, false)
            ApplyManualOutfit(ped, Config.reinforcments.dress)
            GiveWeaponToPed(ped, Config.reinforcments.weapons, 9999, true, true)
            SetPedAsGroupMember(ped, GetPedGroupIndex(ped))
            SetPedCombatAttributes(ped, 46, true)
            SetPedSeeingRange(ped, 100.0)
            SetPedArmour(ped, 100)
            peds[#peds + 1] = ped
        end

        local driver = peds[1]
        TaskVehicleDriveToCoord(driver, vehicle, coords.x, coords.y, coords.z, 60.0, 0, vehModel, 786603, 10.0)

        spawnedReinforcements[#spawnedReinforcements + 1] = {
            vehicle = vehicle,
            peds = peds
        }

        CreateThread(function()
            local arrived = false
            while not arrived do
                Wait(1000)
                local vehCoords = GetEntityCoords(vehicle)
                if #(vehCoords - coords) < 30.0 then
                    arrived = true
                    for i = 2, #peds do
                        TaskLeaveVehicle(peds[i], vehicle, 256)
                        Wait(1000)
                        TaskCombatPed(peds[i], PlayerPedId(), 0, 16)
                    end
                end
            end
        end)
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        local aliveEnemyCount = 0

        for _, player in pairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            if IsPedArmed(ped, 7) and not IsPedDeadOrDying(ped) then
                aliveEnemyCount = aliveEnemyCount + 1
            end
        end

        if aliveEnemyCount <= 1 and #spawnedReinforcements > 0 then
            for _, group in pairs(spawnedReinforcements) do
                for _, ped in pairs(group.peds) do
                    if DoesEntityExist(ped) then DeleteEntity(ped) end
                end
                if DoesEntityExist(group.vehicle) then DeleteEntity(group.vehicle) end
            end
            spawnedReinforcements = {}
            print("[Shadow Cartel] Emergency Protocol ended. All reinforcements cleaned up.")
        end
    end
end)


RegisterNetEvent("shadowcartel_guard:broadcastAlert", function(coords, message)
    if ESX.GetPlayerData().job.name == Config.CartelJob then
        TriggerEvent("esx:showNotification", "[ALERT] " .. message)
        PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        SetNewWaypoint(coords.x, coords.y)
    end
end)


local motionZones = Config.motionZones

CreateThread(function()
    while true do
        Wait(1000)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, zone in pairs(motionZones) do
            if #(playerCoords - zone.coords) < zone.radius then
                TriggerServerEvent("shadowcartel_guard:motionAlert", zone.coords)
            end
        end
    end
end)

function ApplyManualOutfit(ped, outfit)
    SetPedComponentVariation(ped, 8,  outfit.tshirt_1 or 15,  outfit.tshirt_2 or 0, 2) -- T-Shirt
    SetPedComponentVariation(ped, 11, outfit.torso_1 or 111, outfit.torso_2 or 0, 2) -- Torso
    SetPedComponentVariation(ped, 3,  outfit.arms or 0,      0, 2) -- Arms
    SetPedComponentVariation(ped, 4,  outfit.pants_1 or 31,  outfit.pants_2 or 0, 2) -- Pants
    SetPedComponentVariation(ped, 6,  outfit.shoes_1 or 25,  outfit.shoes_2 or 0, 2) -- Shoes
    SetPedComponentVariation(ped, 9,  outfit.decals_1 or 0,  outfit.decals_2 or 0, 2) -- Decals
    SetPedComponentVariation(ped, 1,  outfit.mask_1 or 0, outfit.mask_2 or 0, 2) -- Mask
    SetPedPropIndex(ped, 0, outfit.helmet_1 or -1, outfit.helmet_2 or 0, true) -- Helmet
    SetPedPropIndex(ped, 2, outfit.chain_1 or 0,   outfit.chain_2 or 0, true) -- Chain
end