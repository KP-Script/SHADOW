local spawnedHelis = {}
local lastAlertTime = 0
local alertCooldown = 10000
local spotlightEnabled = false

function spawnHelicopters()
    for _, heliData in pairs(Config.Helicopters) do
        RequestModel(heliData.model)
        while not HasModelLoaded(heliData.model) do Wait(100) end

        local heli = CreateVehicle(heliData.model, heliData.coords.xyz, heliData.coords.w, true, false)
        SetEntityAsMissionEntity(heli, true, true)
        SetHeliBladesFullSpeed(heli)

        local pilot = CreatePedInsideVehicle(heli, 4, `mp_m_freemode_01`, -1, true, false)
        ApplyManualOutfit(pilot, Config.dresspack)
        SetPedAsCop(pilot, true)
        SetPedCanRagdoll(pilot, false)
        TaskHeliMission(pilot, heli, 0, 0, heliData.patrolPoints[1], 4, 50.0, -1.0, -1.0, 10, 20, true, true, false, 0)

        -- Spotlight setup
        CreateThread(function()
            while DoesEntityExist(heli) do
                local hour = GetClockHours()
                if hour >= 20 or hour <= 5 then
                    SetVehicleSearchlight(heli, true, true)
                    spotlightEnabled = true
                else
                    if spotlightEnabled then
                        SetVehicleSearchlight(heli, false, false)
                        spotlightEnabled = false
                    end
                end
                Wait(10000)
            end
        end)

        spawnedHelis[#spawnedHelis+1] = {
            vehicle = heli,
            pilot = pilot,
            patrol = heliData.patrolPoints,
            current = 1
        }
    end
end

-- Patrol + Detection
CreateThread(function()
    Wait(2000)
    spawnHelicopters()

    while true do
        Wait(5000)
        local threatCount = 0

        for _, heli in pairs(spawnedHelis) do
            if DoesEntityExist(heli.vehicle) and DoesEntityExist(heli.pilot) then
                local player = PlayerPedId()
                local coords = GetEntityCoords(player)
                local heliCoords = GetEntityCoords(heli.vehicle)
                local dist = #(coords - heliCoords)

                -- Detect armed or aiming players
                if IsPedArmed(player, 7) and (IsPlayerFreeAiming(PlayerId()) or GetSelectedPedWeapon(player) ~= `WEAPON_UNARMED`) and dist < 150.0 then
                    threatCount += 1
                    TaskVehicleShootAtPed(heli.pilot, player, 20.0)
                    
                    if GetGameTimer() - lastAlertTime > alertCooldown then
                        TriggerServerEvent("shadowcartel_guard:heliThreatDetected", coords)
                        lastAlertTime = GetGameTimer()
                    end
                end

                -- Continue patrol to next point
                local next = heli.current % #heli.patrol + 1
                TaskHeliMission(heli.pilot, heli.vehicle, 0, 0, heli.patrol[next], 4, 50.0, -1.0, -1.0, 10, 20, true, true, false, 0)
                heli.current = next
            end
        end

        -- Emergency protocol
        local isInCayo = exports["npc_gards"]:IsPlayerInCayo()
        if threatCount >= 2 and isInCayo then
            TriggerServerEvent("shadowcartel_guard:emergencyProtocol")
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
