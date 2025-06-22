local State = require("client/shared_state")
local ApplyManualOutfit = State.ApplyManualOutfit
local convoyVehicles = State.convoyVehicles
local convoyActive = State.convoyActive
local bossPed = State.bossPed

-- Utility: Calculate a random spawn position ~Config.escort.spawnDistance from boss
local function GetSpawnPositionAroundBoss()
    local bossCoords = GetEntityCoords(PlayerPedId())
    local dist = Config.escort.spawnDistance or 100.0
    local angle = math.random() * 2 * math.pi
    local xOffset = math.cos(angle) * dist
    local yOffset = math.sin(angle) * dist
    local spawnX = bossCoords.x + xOffset
    local spawnY = bossCoords.y + yOffset
    local _, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, bossCoords.z + 50.0, 0)
    if groundZ then
        return vector3(spawnX, spawnY, groundZ)
    else
        return vector3(spawnX, spawnY, bossCoords.z)
    end
end

-- Utility: Calculate heading from spawnPos to bossCoords
local function GetHeadingToBoss(fromCoords)
    local bossCoords = GetEntityCoords(PlayerPedId())
    local dx = bossCoords.x - fromCoords.x
    local dy = bossCoords.y - fromCoords.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    return heading
end

-- Removes all convoy entities and resets state
function RemoveEscortTeam()
    for _, entry in ipairs(State.convoyVehicles or {}) do
        for _, ped in ipairs(entry.guards or {}) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        if DoesEntityExist(entry.vehicle) then
            DeleteVehicle(entry.vehicle)
        end
    end
    State.convoyVehicles = {}
    State.escortVehicles = {} -- ✅ Also clear escortVehicles
    State.convoyActive = false
    ESX.ShowNotification("Escort team dismissed.")
end

-- Spawn and set up the 3-vehicle convoy with guards
function SpawnEscortTeam()
    if State.convoyActive then
        ESX.ShowNotification("Escort already active.")
        return
    end

    bossPed = PlayerPedId()
    State.bossPed = bossPed
    local bossCoords = GetEntityCoords(bossPed)
    local spawnPos = GetSpawnPositionAroundBoss()
    local headingToBoss = GetHeadingToBoss(spawnPos)

    convoyVehicles = {}
    convoyActive = true
    State.convoyActive = true

    for idx, vehCfg in ipairs(Config.escort.vehicles) do
        local model = vehCfg.model
        local vtype = vehCfg.type or ("veh" .. idx)
        local seats = vehCfg.seats or 0

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(50) end

        local lateralOffset = 0.0
        if idx == 1 then lateralOffset = 5.0
        elseif idx == 3 then lateralOffset = -5.0 end

        local rad = math.rad(headingToBoss)
        local spawnX = spawnPos.x + lateralOffset * math.cos(rad + math.pi/2)
        local spawnY = spawnPos.y + lateralOffset * math.sin(rad + math.pi/2)
        local spawnZ = spawnPos.z

        local veh = CreateVehicle(model, spawnX, spawnY, spawnZ, headingToBoss, true, false)
        SetVehicleOnGroundProperly(veh)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleNumberPlateText(veh, "CARTEL")

        convoyVehicles[idx] = {
            vehicle = veh,
            type = vtype,
            guards = {}
        }

        local seatIndex = -1
        for i = 1, seats do
            RequestModel(Config.GuardModel)
            while not HasModelLoaded(Config.GuardModel) do Wait(10) end

            local ped = CreatePedInsideVehicle(veh, 4, Config.GuardModel, seatIndex, true, false)
            ApplyManualOutfit(ped, Config.GuardOutfit)
            SetPedRelationshipGroupHash(ped, `PLAYER`)
            local weaponName = Config.escort.weapons and Config.escort.weapons[1] or Config.GuardWeapon
            GiveWeaponToPed(ped, GetHashKey(weaponName), 9999, true, true)
            SetPedArmour(ped, 100)
            SetPedAsGroupMember(ped, GetPedGroupIndex(bossPed))
            SetPedNeverLeavesGroup(ped, true)
            SetPedCanBeTargetted(ped, true)
            table.insert(convoyVehicles[idx].guards, ped)
            seatIndex = seatIndex + 1
        end
    end

    -- ✅ Fixed: Save escortVehicles to state
    State.convoyVehicles = convoyVehicles
    State.escortVehicles = convoyVehicles

    ESX.ShowNotification("Escort team en route to you.")

    local stopDist = Config.escort.stopDistance or 10.0
    local forwardX = math.cos(math.rad(GetEntityHeading(bossPed)))
    local forwardY = math.sin(math.rad(GetEntityHeading(bossPed)))
    local stopFront = vector3(bossCoords.x + forwardX * stopDist, bossCoords.y + forwardY * stopDist, bossCoords.z)
    local stopBossVeh = bossCoords
    local stopRear = vector3(bossCoords.x - forwardX * stopDist, bossCoords.y - forwardY * stopDist, bossCoords.z)

    if convoyVehicles[1] then
        local entry = convoyVehicles[1]
        local driverPed = entry.guards[1]
        if driverPed and DoesEntityExist(driverPed) then
            TaskVehicleDriveToCoord(driverPed, entry.vehicle, stopFront.x, stopFront.y, stopFront.z, 20.0, 1, GetEntityModel(entry.vehicle), 16777216, 5.0)
        end
    end

    if convoyVehicles[2] then
        local entry = convoyVehicles[2]
        local driverPed = entry.guards[1]
        if driverPed and DoesEntityExist(driverPed) then
            TaskVehicleDriveToCoord(driverPed, entry.vehicle, stopBossVeh.x, stopBossVeh.y, stopBossVeh.z, 15.0, 1, GetEntityModel(entry.vehicle), 16777216, 5.0)
        end
    end

    if convoyVehicles[3] then
        local entry = convoyVehicles[3]
        local driverPed = entry.guards[1]
        if driverPed and DoesEntityExist(driverPed) then
            TaskVehicleDriveToCoord(driverPed, entry.vehicle, stopRear.x, stopRear.y, stopRear.z, 20.0, 1, GetEntityModel(entry.vehicle), 16777216, 5.0)
        end
    end

    CreateThread(function()
        local arrivedFront, arrivedBossVeh, arrivedRear = false, false, false

        while not (arrivedFront and arrivedBossVeh and arrivedRear) do
            Wait(500)
            local bossCoordsNow = GetEntityCoords(bossPed)

            if convoyVehicles[1] and not arrivedFront then
                local pos = GetEntityCoords(convoyVehicles[1].vehicle)
                if #(pos - stopFront) < 5.0 then
                    arrivedFront = true
                    TaskVehicleTempAction(convoyVehicles[1].guards[1], convoyVehicles[1].vehicle, 27, 3000)
                end
            end

            if convoyVehicles[2] and not arrivedBossVeh then
                local pos = GetEntityCoords(convoyVehicles[2].vehicle)
                if #(pos - stopBossVeh) < 5.0 then
                    arrivedBossVeh = true
                    TaskVehicleTempAction(convoyVehicles[2].guards[1], convoyVehicles[2].vehicle, 27, 3000)
                end
            end

            if convoyVehicles[3] and not arrivedRear then
                local pos = GetEntityCoords(convoyVehicles[3].vehicle)
                if #(pos - stopRear) < 5.0 then
                    arrivedRear = true
                    TaskVehicleTempAction(convoyVehicles[3].guards[1], convoyVehicles[3].vehicle, 27, 3000)
                end
            end
        end

        Wait(1000)

        if convoyVehicles[2] then
            local bossVeh = convoyVehicles[2].vehicle
            if DoesEntityExist(bossVeh) and not IsPedInAnyVehicle(bossPed, false) then 
                TaskWarpPedIntoVehicle(bossPed, bossVeh, -1)
            end
        end

        Wait(500)

        if convoyVehicles[1] then
            for i = 1, math.min(2, #convoyVehicles[1].guards) do
                local ped = convoyVehicles[1].guards[i]
                if DoesEntityExist(ped) then
                    TaskLeaveVehicle(ped, convoyVehicles[1].vehicle, 0)
                    Wait(500)
                    local flank = GetOffsetFromEntityInWorldCoords(bossPed, (i == 1 and 1.5 or -1.5), 2.0, 0.0)
                    TaskGoStraightToCoord(ped, flank.x, flank.y, flank.z, 2.0, -1, 0.0, 0.5)
                end
            end
        end

        if convoyVehicles[3] then
            for i = 1, math.min(2, #convoyVehicles[3].guards) do
                local ped = convoyVehicles[3].guards[i]
                if DoesEntityExist(ped) then
                    TaskLeaveVehicle(ped, convoyVehicles[3].vehicle, 0)
                    Wait(500)
                    local flank = GetOffsetFromEntityInWorldCoords(bossPed, (i == 1 and 1.5 or -1.5), -2.0, 0.0)
                    TaskGoStraightToCoord(ped, flank.x, flank.y, flank.z, 2.0, -1, 0.0, 0.5)
                end
            end
        end

        ESX.ShowNotification("Escort formed. Drive with protection.")
    end)
end

RegisterNetEvent("KP_bodyguard:requestEscortTeam", function()
    SpawnEscortTeam()
end)

RegisterNetEvent("KP_bodyguard:removeEscortTeam", function()
    RemoveEscortTeam()
end)