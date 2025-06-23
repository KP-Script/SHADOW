local ESX = exports["es_extended"]:getSharedObject()
local PlayerData = {}
local myRole = nil
local IsHandcuffed = false
local IsEscorted = false
local civilianSkin = nil

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    SetShadowCartelRole(xPlayer.job.name, xPlayer.job.grade)
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    SetShadowCartelRole(job.name, job.grade)
end)

function SetShadowCartelRole(jobName, jobGrade)
    if jobName ~= Config.JobName then
        myRole = nil
        return
    end

    myRole = jobGrade
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, Config.button) and PlayerData.job and PlayerData.job.name == Config.JobName then
            OpenCartelMenu()
        end
    end
end)

function OpenCartelMenu()
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shadowcartel_main', {
        title = 'Shadow Cartel Menu',
        align = 'right',
        elements = {
            {label = '👤 Player Interaction', value = 'player_actions'},
            {label = '🚗 Vehicle Interaction', value = 'vehicle_actions'},
            {label = '💰 Fine Section', value = 'fine_player'},
            {label = '🔧 Other Options', value = 'other_options'},
        }
    }, function(data, menu)
        if data.current.value == 'player_actions' then
            OpenPlayerInteractionMenu()
        elseif data.current.value == 'vehicle_actions' then
            OpenVehicleInteractionMenu()
        elseif data.current.value == 'fine_player' then
            OpenFineMenu()
        elseif data.current.value == 'other_options' then
            OpenOtherOptionsMenu()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenPlayerInteractionMenu()
    local elements = {
        {label = '🔎 ID Search', value = 'id_search'},
        {label = '🎒 Inventory Search', value = 'inv_search'},
        {label = '🔗 Cuff / Uncuff', value = 'cuff'},
        {label = '👣 Escort Player', value = 'escort'},
        {label = '🚓 Put in Vehicle', value = 'put_in_vehicle'},
        {label = '🚪 Drag Out of Vehicle', value = 'drag_out'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_menu', {
        title = 'Player Interaction',
        align = 'right',
        elements = elements
    }, function(data, menu)
        local closestPlayer, distance = ESX.Game.GetClosestPlayer()
        if distance == -1 or distance > 3.0 then
            ESX.ShowNotification('❌ No player nearby')
            return
        end

        local targetId = GetPlayerServerId(closestPlayer)

        if data.current.value == 'id_search' then
            TriggerServerEvent('shadowcartel:idSearch', targetId)

        elseif data.current.value == 'inv_search' then
            TriggerServerEvent('shadowcartel:searchInventory', targetId)

        elseif data.current.value == 'cuff' then
            TriggerServerEvent('shadowcartel:toggleCuff', targetId)

        elseif data.current.value == 'escort' then
            TriggerServerEvent('shadowcartel:escort', targetId)

        elseif data.current.value == 'put_in_vehicle' then
            TriggerServerEvent('shadowcartel:putInVehicle', targetId)

        elseif data.current.value == 'drag_out' then
            TriggerServerEvent('shadowcartel:dragOut', targetId)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenVehicleInteractionMenu()
    local elements = {
        {label = '🔍 Search Vehicle', value = 'veh_info'},
        {label = '🔓 Unlock Vehicle', value = 'unlock'},
        {label = '💥 Blast Vehicle (15s delay)', value = 'explode'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_menu', {
        title = 'Vehicle Interaction',
        align = 'right',
        elements = elements
    }, function(data, menu)
        local vehicle = ESX.Game.GetClosestVehicle()
        if not DoesEntityExist(vehicle) then
            ESX.ShowNotification('❌ No vehicle nearby')
            return
        end

        if data.current.value == 'veh_info' then
            TriggerServerEvent('shadowcartel:vehicleInfo', VehToNet(vehicle))

        elseif data.current.value == 'unlock' then
            SetVehicleDoorsLocked(vehicle, 1)
            ESX.ShowNotification('🔓 Vehicle unlocked')

        elseif data.current.value == 'explode' then
            ESX.ShowNotification('💣 Vehicle will explode in 15 seconds')
            local coords = GetEntityCoords(vehicle)
            Citizen.SetTimeout(15000, function()
                AddExplosion(coords.x, coords.y, coords.z, 2, 1.0, true, false, true)
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenFineMenu()
    local closestPlayer, distance = ESX.Game.GetClosestPlayer()
    if distance == -1 or distance > 3.0 then
        ESX.ShowNotification('❌ No player nearby')
        return
    end

    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'fine_amount', {
        title = 'Enter fine amount'
    }, function(data, menu)
        local amount = tonumber(data.value)
        if not amount or amount <= 0 then
            ESX.ShowNotification('❌ Invalid amount')
            return
        end
        menu.close()

        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'fine_reason', {
            title = 'Enter fine reason'
        }, function(data2, menu2)
            local reason = data2.value
            menu2.close()
            TriggerServerEvent('shadowcartel:finePlayer', GetPlayerServerId(closestPlayer), amount, reason)
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
    end)
end

function OpenOtherOptionsMenu()
    local elements = {
        {label = '💼 Change Outfit', value = 'change_outfit'},
        {label = '📡 Connect to Radio', value = 'connect_radio'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'other_menu', {
        title = 'Other Options',
        align = 'right',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'change_outfit' then
            ChangeOutfit()
        elseif data.current.value == 'connect_radio' then
            ExecuteCommand('radio '..Config.RadioChannel)
            ESX.ShowNotification('📡 Connected to private radio channel: '..Config.RadioChannel)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function ChangeOutfit()
    TriggerEvent('skinchanger:getSkin', function(skin)
        if not civilianSkin then
            civilianSkin = skin
            local outfit = Config.Outfits[myRole] and Config.Outfits[myRole][skin.sex == 0 and "male" or "female"]
            if outfit then
                TriggerEvent('skinchanger:loadClothes', skin, outfit)
                ESX.ShowNotification('💼 Changed to cartel outfit')
            else
                ESX.ShowNotification('❌ No outfit found for this grade')
            end
        else
            TriggerEvent('skinchanger:loadSkin', civilianSkin)
            ESX.ShowNotification('👕 Changed to civilian outfit')
            civilianSkin = nil
        end
    end)
end

-- Client-side Events from Server
RegisterNetEvent("shadowcartel:toggleCuff", function()
    local ped = PlayerPedId()
    IsHandcuffed = not IsHandcuffed

    if IsHandcuffed then
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do Wait(10) end
        TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
        DisableControlAction(0, 21, true)
        SetEnableHandcuffs(ped, true)
    else
        ClearPedTasksImmediately(ped)
        SetEnableHandcuffs(ped, false)
    end
end)

RegisterNetEvent("shadowcartel:escort", function(copId)
    local ped = PlayerPedId()
    local copPed = GetPlayerPed(GetPlayerFromServerId(copId))

    if not IsEscorted then
        AttachEntityToEntity(ped, copPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        IsEscorted = true
    else
        DetachEntity(ped, true, false)
        IsEscorted = false
    end
end)

RegisterNetEvent("shadowcartel:putInVehicle", function()
    local ped = PlayerPedId()
    local vehicle = ESX.Game.GetClosestVehicle()
    if DoesEntityExist(vehicle) then
        TaskWarpPedIntoVehicle(ped, vehicle, 2)
    end
end)

RegisterNetEvent("shadowcartel:dragOut", function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
    end
end)
