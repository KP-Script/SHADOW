local State = require("client/shared_state")
local ApplyOutfit = State.ApplyManualOutfit
local guards = State.guards
local escortVehicles = State.escortVehicles
local manualPositions = State.manualPositions
local isSettingPositions = State.isSettingPositions
local currentFormation = State.currentFormation
local currentBoss = State.bossPed

-- Shared Config
local Config = require("config")

-- Event: Spawn 4 guards in a vehicle
RegisterNetEvent("KP_bodyguard:requestGuards", function(bossPed)
    currentBoss = bossPed or PlayerPedId()
    local spawnOffset = GetOffsetFromEntityInWorldCoords(currentBoss, 0.0, -Config.SpawnDistance, 0.0)
    local vehicle = CreateVehicle(Config.GuardVehicle, spawnOffset.x, spawnOffset.y, spawnOffset.z, 0.0, true, false)
    SetVehicleOnGroundProperly(vehicle)
    table.insert(escortVehicles, vehicle)

    local group = CreateGroup()
    SetPedAsGroupLeader(currentBoss, group)
    for seat = -1, 2 do
        local guard = CreatePedInsideVehicle(vehicle, 4, Config.GuardModel, seat, true, false)
        ApplyOutfit(guard, Config.GuardOutfit)
        GiveWeaponToPed(guard, `WEAPON_CARBINERIFLE`, 9999, true, true)
        SetPedArmour(guard, 100)
        SetPedAsGroupMember(guard, group)
        SetPedNeverLeavesGroup(guard, true)
        SetPedRelationshipGroupHash(guard, `PLAYER`)
        TaskGoToEntity(guard, currentBoss, -1, 2.0, 2.0, 1073741824, 0)
        table.insert(guards, guard)
    end


    TaskVehicleDriveToCoord(guards[1], vehicle, GetEntityCoords(currentBoss), 15.0, 0, GetEntityModel(vehicle), 786603, 5.0)
end)

-- Event: Remove guards
RegisterNetEvent("KP_bodyguard:removeGuards", function()
    for _, ped in ipairs(guards) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    State.guards = {}
end)

-- Event: Remove vehicles and guards
RegisterNetEvent("KP_bodyguard:removeEscortTeam", function()
    for _, ped in ipairs(guards) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, veh in ipairs(escortVehicles) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    State.guards = {}
    State.escortVehicles = {}
end)

-- Event: Set formations
RegisterNetEvent("KP_bodyguard:setFormation", function(type, bossPed)
    currentBoss = bossPed or PlayerPedId()
    currentFormation = type
end)

-- Event: Manual position each guard using [E]
RegisterNetEvent("KP_bodyguard:setManualPositions", function(bossPed)
    currentBoss = bossPed or PlayerPedId()
    manualPositions = {}
    isSettingPositions = true
    ESX.ShowNotification("Press ~INPUT_CONTEXT~ (E) to place 4 guards.")

    CreateThread(function()
        while isSettingPositions and #manualPositions < 4 do
            Wait(0)
            if IsControlJustPressed(0, Config.AssignKey) then
                local pos = GetEntityCoords(currentBoss)
                table.insert(manualPositions, pos)
                ESX.ShowNotification("Position " .. #manualPositions .. " set.")
            end
        end

        if #manualPositions == 4 then
            for i, guard in ipairs(guards) do
                TaskGoStraightToCoord(guard, manualPositions[i].x, manualPositions[i].y, manualPositions[i].z, 1.0, -1, 0.0, 0.0)
            end
            isSettingPositions = false
        end
    end)
end)

-- Event: Guards enter vehicle
RegisterNetEvent("KP_bodyguard:enterVehicles", function()
    for i, guard in ipairs(guards) do
        local veh = escortVehicles[1]
        if veh and DoesEntityExist(veh) then
            TaskEnterVehicle(guard, veh, -1, i - 2, 2.0, 1, 0)
        end
    end
end)

-- Periodically update formations (box/line)
CreateThread(function()
    while true do
        Wait(2000)
        if currentFormation and #guards == 4 and currentBoss then
            local coords = GetEntityCoords(currentBoss)
            if currentFormation == "box" then
                local offsets = {
                    vector3(2.0, 2.0, 0.0),
                    vector3(2.0, -2.0, 0.0),
                    vector3(-2.0, 2.0, 0.0),
                    vector3(-2.0, -2.0, 0.0),
                }
                for i, guard in ipairs(guards) do
                    local pos = coords + offsets[i]
                    TaskGoStraightToCoord(guard, pos.x, pos.y, pos.z, 2.0, -1, 0.0, 0.0)
                end
            elseif currentFormation == "line" then
                for i, guard in ipairs(guards) do
                    local pos = GetOffsetFromEntityInWorldCoords(currentBoss, 0.0, -2.0 - i * 1.5, 0.0)
                    TaskGoStraightToCoord(guard, pos.x, pos.y, pos.z, 2.0, -1, 0.0, 0.0)
                end
            end
        end
    end
end)