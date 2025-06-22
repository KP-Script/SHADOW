local bossTarget = nil
local playerJob, playerGrade

-- Command to open menu
RegisterCommand("bodyguard", function()
    ESX.TriggerServerCallback("esx:getPlayerData", function(data)
        playerJob = data.job.name
        playerGrade = data.job.grade

        if playerJob == Config.BossJob and playerGrade == 2 then
            bossTarget = PlayerPedId() -- Boss controls himself
            openBodyguardMenu()
        elseif playerJob == Config.BossJob and playerGrade == 1 then
            -- Assistant: prompt for boss ID
            local input = lib.inputDialog("Enter Boss Server ID", {
                {type = "number", label = "Boss ID", required = true}
            })
            if input and input[1] then
                local targetId = tonumber(input[1])
                if targetId and GetPlayerFromServerId(targetId) ~= -1 then
                    bossTarget = GetPlayerPed(GetPlayerFromServerId(targetId))
                    openBodyguardMenu()
                else
                    ESX.ShowNotification("~r~Invalid or offline Boss ID.")
                end
            end
        else
            ESX.ShowNotification("~r~Only Shadow Cartel Boss or Assistant can use this.")
        end
    end)
end)

-- Menu for all roles (bossTarget is used)
function openBodyguardMenu()
    lib.registerContext({
        id = 'bodyguard_main_menu',
        title = '👥 Shadow Cartel Bodyguards',
        options = {
            { title = '📥 Request', description = 'Request personal guards or vehicle team', menu = 'bodyguard_request_menu' },
            { title = '🧍 Positions', description = 'Formations & guard placement', menu = 'bodyguard_position_menu' },
            { title = '❌ Remove', description = 'Remove active guards or vehicles', menu = 'bodyguard_remove_menu' },
            { title = '⚙️ Others', description = 'Other bodyguard features', menu = 'bodyguard_others_menu' },
        }
    })
    lib.showContext('bodyguard_main_menu')
end

-- Request submenu
lib.registerContext({
    id = 'bodyguard_request_menu',
    title = '📥 Request Guards',
    menu = 'bodyguard_main_menu',
    options = {
        {
            title = '👥 Body Guards',
            description = 'Spawn 4 guards with a vehicle',
            icon = 'user-shield',
            onSelect = function()
                TriggerEvent("KP_bodyguard:requestGuards", bossTarget)
            end
        },
        {
            title = '🚗 Vehicle Escort Team',
            description = 'Spawn 3-vehicle convoy with 10 guards',
            icon = 'truck',
            onSelect = function()
                TriggerEvent("KP_bodyguard:requestEscortTeam", bossTarget)
            end
        },
        {
            title = '🦅 Aerial Recon Unit',
            description = 'Deploy helicopter guards for overhead security',
            icon = 'helicopter',
            onSelect = function()
                TriggerEvent("KP_bodyguard:requestHeliUnit", bossTarget)
            end
        }
    }
})

-- Positions submenu
lib.registerContext({
    id = 'bodyguard_position_menu',
    title = '🧍 Position Guards',
    menu = 'bodyguard_main_menu',
    options = {
        {
            title = '🔳 Box Formation',
            description = 'Place guards around boss in a box',
            onSelect = function()
                TriggerEvent("KP_bodyguard:setFormation", "box", bossTarget)
            end
        },
        {
            title = '📏 Line Behind',
            description = 'Guards form a line behind boss',
            onSelect = function()
                TriggerEvent("KP_bodyguard:setFormation", "line", bossTarget)
            end
        },
        {
            title = '📍 Stay Here',
            description = 'Set static position for each guard using [E]',
            onSelect = function()
                TriggerEvent("KP_bodyguard:setManualPositions", bossTarget)
            end
        },
        {
            title = '🚗 Get In Vehicles',
            description = 'Guards return to vehicles and follow',
            onSelect = function()
                TriggerEvent("KP_bodyguard:enterVehicles", bossTarget)
            end
        }
    }
})

-- Remove submenu
lib.registerContext({
    id = 'bodyguard_remove_menu',
    title = '❌ Remove Guards',
    menu = 'bodyguard_main_menu',
    options = {
        {
            title = '🧍 Remove Bodyguards',
            description = 'Dismiss all guards',
            onSelect = function()
                TriggerEvent("KP_bodyguard:removeGuards", bossTarget)
            end
        },
        {
            title = '🚗 Remove Vehicles',
            description = 'Dismiss all guards and vehicles',
            onSelect = function()
                TriggerEvent("KP_bodyguard:removeEscortTeam", bossTarget)
            end
        },
        {
            title = '🚗 Remove Heli',
            description = 'Dismiss all guards and Heli',
            onSelect = function()
                TriggerEvent("KP_bodyguard:removeHeli", bossTarget)
            end
        }
    }
})

-- Others submenu
lib.registerContext({
    id = 'bodyguard_others_menu',
    title = '⚙️ Other Features',
    menu = 'bodyguard_main_menu',
    options = {
        {
            title = '📢 Regroup Guards',
            description = 'Call all guards to boss location',
            icon = 'users',
            onSelect = function()
                TriggerEvent("KP_bodyguard:regroupGuards", bossTarget)
            end
        },
        {
            title = '🛡️ Toggle Defensive Mode',
            description = 'Switch between passive and aggressive behavior',
            icon = 'shield-alt',
            onSelect = function()
                TriggerEvent("KP_bodyguard:toggleDefensiveMode", bossTarget)
            end
        },
        {
            title = '💉 Heal Guards',
            description = 'Restore all guards\' health',
            icon = 'medkit',
            onSelect = function()
                TriggerEvent("KP_bodyguard:healGuards", bossTarget)
            end
        },
        {
            title = '🔫 Toggle Weapons',
            description = 'Equip or remove guard weapons',
            icon = 'ban',
            onSelect = function()
                TriggerEvent("KP_bodyguard:toggleWeapons", bossTarget)
            end
        },
        {
            title = '🚘 Vehicle Follow',
            description = 'Escort vehicles follow boss vehicle',
            icon = 'car-side',
            onSelect = function()
                TriggerEvent("KP_bodyguard:vehicleFollow", bossTarget)
            end
        },
        {
            title = '🎥 Heli Camera View',
            description = 'View the helicopter camera feed',
            icon = 'video',
            onSelect = function()
                TriggerEvent("KP_bodyguard:specHeli",bossTarget)
            end
        }
    }
})