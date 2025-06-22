local spawnedGuards = {}

-- Spawn Guard Peds
CreateThread(function()
    for _, guard in pairs(Config.Guards) do
        RequestModel(guard.model)
        while not HasModelLoaded(guard.model) do Wait(100) end

        local ped = CreatePed(4, guard.model, guard.coords.x, guard.coords.y, guard.coords.z - 1, guard.coords.w, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        GiveWeaponToPed(ped, guard.weapon, 9999, true, true)
        SetPedArmour(ped, 100)
        SetPedAccuracy(ped, 100)
        SetPedCanSwitchWeapon(ped, true)
        SetPedDropsWeaponsWhenDead(ped, false)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
        if guard.appearance then
            if TriggerEvent then
                TriggerEvent('skinchanger:loadSkin', guard.appearance, ped)
            else
                ApplyManualOutfit(ped, guard.appearance)
            end
        end

        table.insert(spawnedGuards, ped)
    end
end)


function ApplyManualOutfit(ped, outfit)
    if not outfit then return end
    SetPedComponentVariation(ped, 8,  outfit.tshirt_1 or 15,  outfit.tshirt_2 or 0, 2) -- T-Shirt
    SetPedComponentVariation(ped, 11, outfit.torso_1 or 111, outfit.torso_2 or 0, 2) -- Torso
    SetPedComponentVariation(ped, 3,  outfit.arms or 0,      0, 2) -- Arms
    SetPedComponentVariation(ped, 4,  outfit.pants_1 or 31,  outfit.pants_2 or 0, 2) -- Pants
    SetPedComponentVariation(ped, 6,  outfit.shoes_1 or 25,  outfit.shoes_2 or 0, 2) -- Shoes
    SetPedComponentVariation(ped, 9,  outfit.decals_1 or 0,  outfit.decals_2 or 0, 2) -- Decals
    SetPedComponentVariation(ped, 0, outfit.mask_1 or 0, outfit.mask_2 or 0, 2) -- Mask
    SetPedPropIndex(ped, 0, outfit.helmet_1 or -1, outfit.helmet_2 or 0, true) -- Helmet
    SetPedPropIndex(ped, 2, outfit.chain_1 or 0,   outfit.chain_2 or 0, true) -- Chain
end

-- Threat Detection (Aiming or Weapon Out)
CreateThread(function()
    while true do
        Wait(500)

        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)

        if IsPedArmed(player, 7) and IsPlayerFreeAiming(PlayerId()) then
            TriggerServerEvent("shadowcartel_guard:playerAiming", playerCoords)
        elseif IsPedArmed(player, 7) and GetSelectedPedWeapon(player) ~= `WEAPON_UNARMED` then
            TriggerServerEvent("shadowcartel_guard:playerArmed", playerCoords)
        end
    end
end)

-- Client Trigger from Server: Attack Player
RegisterNetEvent("shadowcartel_guard:attackPlayer", function(targetCoords)
    for _, ped in pairs(spawnedGuards) do
        if DoesEntityExist(ped) and not IsPedDeadOrDying(ped) then
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
        end
    end
end)

-- Target integration with ox_target for Request Ped
CreateThread(function()
    RequestModel(Config.RequestPed.model)
    while not HasModelLoaded(Config.RequestPed.model) do Wait(100) end
    local ped = CreatePed(4, Config.RequestPed.model, Config.RequestPed.coords.x, Config.RequestPed.coords.y, Config.RequestPed.coords.z - 1, Config.RequestPed.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = "Request Entry to Cayo",
            icon = "fa-solid fa-key",
            groups = Config.AllowedRequestJobs,
            onSelect = function()
                lib.inputDialog("Request Entry", {
                    {
                        type = "input",
                        label = "Reason for Entry",
                        placeholder = "Enter your reason here",
                        required = true,
                        name = "reason"
                    }
                }, function(input)
                    if input and input.reason then
                        TriggerServerEvent("shadowcartel_guard:submitRequest", input.reason)
                    end
                end)
            end
        }
    })
end)

-- Target integration with ox_target for Approve Ped
CreateThread(function()
    RequestModel(Config.ApprovePed.model)
    while not HasModelLoaded(Config.ApprovePed.model) do Wait(100) end
    local ped = CreatePed(4, Config.ApprovePed.model, Config.ApprovePed.coords.x, Config.ApprovePed.coords.y, Config.ApprovePed.coords.z - 1, Config.ApprovePed.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = "Review Entry Requests",
            icon = "fa-solid fa-clipboard-check",
            groups = Config.CartelJob,
            onSelect = function()
                TriggerServerEvent("shadowcartel_guard:approveMenu")
            end
        }
    })
end)

RegisterNetEvent("shadowcartel_guard:alertGroundGuards", function(coords)
    for _, ped in pairs(spawnedGuards) do
        if DoesEntityExist(ped) and not IsPedDeadOrDying(ped) then
            TaskGoToCoordWhileAimingAtCoord(ped, coords, coords, 2.0, true, 0, 0.0, true, 0, false, -957453492)
            TaskShootAtCoord(ped, coords, 6000, GetHashKey("FIRING_PATTERN_FULL_AUTO"))
        end
    end
end)
