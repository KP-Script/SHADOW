local State = require("client/shared_state")
local ApplyManualOutfit = State.ApplyManualOutfit

local heliEntity = nil
local heliPed = nil
local heliBlip = nil
local isSpectating = false
local isNight = false

-- Check if a ped is a threat based on armed status
local function isThreat(playerPed)
    if not DoesEntityExist(playerPed) then return false end

    -- ❌ Ignore non-player peds
    if not IsPedAPlayer(playerPed) then return false end

    local playerId = NetworkGetPlayerIndexFromPed(playerPed)
    if playerId == -1 then return false end

    local job = exports["esx_society"]:GetPlayerJob(playerId)
    if job == Config.BossJob then return false end -- ✅ Allowed job

    -- ✅ Only detect armed or aiming players
    return IsPedArmed(playerPed, 7) or IsPlayerFreeAiming(playerId)
end


-- Draws spotlight from the heli at night
local function createSpotlight(entity)
    local bone = GetEntityBoneIndexByName(entity, "light_r")
    local coords = GetWorldPositionOfEntityBone(entity, bone)
    local direction = GetEntityForwardVector(entity)
    DrawSpotLightWithShadow(coords.x, coords.y, coords.z, direction.x, direction.y, direction.z, 255, 255, 255, 100.0, 1.0, 1.0, 30.0, 1.0)
end

-- Heli AI behavior
local function heliAI()
    CreateThread(function()
        while DoesEntityExist(heliEntity) do
            Wait(1000)

            local bossPed = PlayerPedId()
            local bossCoords = GetEntityCoords(bossPed)
            local patrolZ = bossCoords.z + (Config.HeliUnit.patrolHeight or 35.0)

            -- Default patrol to boss location
            TaskHeliMission(
                heliPed, heliEntity, 0, bossPed,
                bossCoords.x, bossCoords.y, patrolZ,
                4, 50.0, 0.0, -1.0, 0, 50, 10.0, 0
            )

            local players = GetActivePlayers()
            local range = Config.HeliUnit.threatDetectionRange or 70.0
            local threatDetected = false

            for _, pid in ipairs(players) do
                local ped = GetPlayerPed(pid)
                if ped ~= bossPed and #(GetEntityCoords(ped) - bossCoords) < range then
                    if isThreat(ped) then
                        threatDetected = true
                        local targetCoords = GetEntityCoords(ped)

                        TaskHeliMission(
                            heliPed, heliEntity, 0, ped,
                            targetCoords.x, targetCoords.y, targetCoords.z + 15.0,
                            4, 70.0, 0.0, -1.0, 0, 60, 10.0, 0
                        )
                        TaskShootAtEntity(heliPed, ped, 5000, `FIRING_PATTERN_FULL_AUTO`)
                        break
                    end
                end
            end

            if isNight and threatDetected then
                CreateThread(function()
                    local timer = GetGameTimer() + 5000
                    while GetGameTimer() < timer do
                        Wait(0)
                        createSpotlight(heliEntity)
                    end
                end)
            end
        end
    end)
end

-- Spectate mode (triggered via menu only)
local function enterSpectateMode()
    if not DoesEntityExist(heliEntity) then
        ESX.ShowNotification("~r~No helicopter is active.")
        return
    end

    isSpectating = true
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    AttachCamToEntity(cam, heliEntity, 0.0, -5.0, 2.0, true)
    SetCamRot(cam, 0.0, 0.0, 0.0)
    SetCamFov(cam, 60.0)
    RenderScriptCams(true, false, 0, true, true)

    ESX.ShowNotification("~b~Spectating helicopter. Press ~INPUT_CONTEXT~ to exit.")

    CreateThread(function()
        while isSpectating and DoesCamExist(cam) do
            Wait(0)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to exit helicopter view")
            EndTextCommandDisplayHelp(0, false, true, 1)

            if IsControlJustPressed(0, 38) then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(cam, false)
                isSpectating = false
                ESX.ShowNotification("~g~Exited helicopter view.")
            end
        end
    end)
end

-- Spawn helicopter and AI
RegisterNetEvent("KP_bodyguard:spawnHeli", function()
    if DoesEntityExist(heliEntity) then
        ESX.ShowNotification("~r~Helicopter already deployed.")
        return
    end

    local model = Config.HeliUnit.model or "buzzard2"
    local weapon = Config.HeliUnit.weapon or "WEAPON_CARBINERIFLE"
    local guardCount = Config.HeliUnit.guardCount or 2
    local spawnDistance = Config.HeliUnit.spawnDistance or 150.0

    -- Time check
    local hour = GetClockHours()
    isNight = (hour >= 19 or hour <= 5)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local bossCoords = GetEntityCoords(PlayerPedId())
    local angle = math.random() * 2 * math.pi
    local xOffset = math.cos(angle) * spawnDistance
    local yOffset = math.sin(angle) * spawnDistance
    local spawnCoords = vector3(bossCoords.x + xOffset, bossCoords.y + yOffset, bossCoords.z + 50.0)

    heliEntity = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    SetEntityInvincible(heliEntity, true)
    SetVehicleEngineOn(heliEntity, true, true, false)
    SetVehicleDoorsLocked(heliEntity, 1)

    -- Pilot
    local pilotModel = `s_m_m_pilot_02`
    RequestModel(pilotModel)
    while not HasModelLoaded(pilotModel) do Wait(0) end

    heliPed = CreatePedInsideVehicle(heliEntity, 1, pilotModel, -1, true, false)
    SetEntityInvincible(heliPed, true)
    SetPedKeepTask(heliPed, true)
    ApplyManualOutfit(heliPed, Config.GuardOutfit)

    -- Optional gunner guards
    for i = 1, guardCount do
        local seatIndex = i
        RequestModel(Config.GuardModel)
        while not HasModelLoaded(Config.GuardModel) do Wait(0) end

        local guard = CreatePedInsideVehicle(heliEntity, 1, Config.GuardModel, seatIndex, true, false)
        SetEntityInvincible(guard, true)
        ApplyManualOutfit(guard, Config.GuardOutfit)
        GiveWeaponToPed(guard, GetHashKey(weapon), 9999, true, true)
        SetPedKeepTask(guard, true)
    end

    -- Blip
    heliBlip = AddBlipForEntity(heliEntity)
    SetBlipSprite(heliBlip, 422)
    SetBlipScale(heliBlip, 0.8)
    SetBlipColour(heliBlip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cartel Heli Escort")
    EndTextCommandSetBlipName(heliBlip)

    ESX.ShowNotification("~g~Helicopter escort deployed.")
    heliAI()
end)

local heliCam = nil
local heliZoom = 50.0
local camActive = false

RegisterNetEvent("KP_bodyguard:openHeliCamera", function()
    if not heliEntity or not DoesEntityExist(heliEntity) then
        ESX.ShowNotification("~r~No active helicopter unit found.")
        return
    end

    local playerPed = PlayerPedId()

    -- Create camera
    heliCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    AttachCamToEntity(heliCam, heliEntity, 0.0, 0.0, -1.5, true)
    SetCamRot(heliCam, 0.0, 0.0, 0.0)
    SetCamFov(heliCam, heliZoom)
    RenderScriptCams(true, false, 0, true, true)

    camActive = true
    ESX.ShowNotification("~b~Heli Camera Activated. Press ~INPUT_CONTEXT~ (E) to exit.")

    CreateThread(function()
        while camActive do
            Wait(0)

            -- Handle camera rotation
            local xRot = GetCamRot(heliCam, 2).x
            local yRot = GetCamRot(heliCam, 2).y
            local zRot = GetCamRot(heliCam, 2).z

            -- Mouse or controller rotation
            local rightAxisX = GetDisabledControlNormal(0, 220)
            local rightAxisY = GetDisabledControlNormal(0, 221)

            xRot = xRot + rightAxisY * -5.0
            zRot = zRot + rightAxisX * -5.0

            SetCamRot(heliCam, xRot, yRot, zRot, 2)

            -- Zoom in/out
            if IsControlJustPressed(0, 241) then -- SCROLL UP
                heliZoom = heliZoom - 5.0
                if heliZoom < 10.0 then heliZoom = 10.0 end
                SetCamFov(heliCam, heliZoom)
            elseif IsControlJustPressed(0, 242) then -- SCROLL DOWN
                heliZoom = heliZoom + 5.0
                if heliZoom > 70.0 then heliZoom = 70.0 end
                SetCamFov(heliCam, heliZoom)
            end

            -- Exit with E
            if IsControlJustPressed(0, 38) then -- E
                camActive = false
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(heliCam, false)
                heliCam = nil
                ESX.ShowNotification("~r~Heli Camera Deactivated.")
            end

            -- Draw hint
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 215)
            SetTextOutline()
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Exit Heli Camera")
            EndTextCommandDisplayText(0.015, 0.92)
        end
    end)
end)


-- Remove heli + blip
RegisterNetEvent("KP_bodyguard:removeHeli", function()
    if heliEntity then DeleteEntity(heliEntity) heliEntity = nil end
    if heliPed then DeleteEntity(heliPed) heliPed = nil end
    if heliBlip then RemoveBlip(heliBlip) heliBlip = nil end
    isSpectating = false
    ESX.ShowNotification("~r~Helicopter escort removed.")
end)

-- Triggered via menu only: spectate
RegisterNetEvent("KP_bodyguard:specHeli", function()
    enterSpectateMode()
end)