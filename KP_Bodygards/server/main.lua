ESX = exports["es_extended"]:getSharedObject()

-- Store assistant → boss target mapping
local assistantToBossMap = {}

-- Server-side job/grade validation
ESX.RegisterServerCallback("KP_bodyguard:isAuthorized", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    local job = xPlayer.job.name
    local grade = xPlayer.job.grade

    if job ~= Config.BossJob then return cb(false) end

    -- Boss can always access
    if grade == Config.BossGrade then
        cb({role = "boss", allowed = true})
    -- Assistant can access, but only with boss target assigned
    elseif grade == Config.AssistantGrade then
        local targetId = assistantToBossMap[source]
        cb({role = "assistant", allowed = targetId ~= nil, target = targetId})
    else
        cb(false)
    end
end)

-- Assistant requests to control guards for a specific boss
RegisterNetEvent("KP_bodyguard:assistantAssignBoss", function(bossId)
    local src = source
    local assistant = ESX.GetPlayerFromId(src)
    local boss = ESX.GetPlayerFromId(bossId)

    if not assistant or not boss then return end
    if assistant.job.name ~= Config.BossJob or assistant.job.grade ~= Config.AssistantGrade then return end
    if boss.job.name ~= Config.BossJob or boss.job.grade ~= Config.BossGrade then return end

    assistantToBossMap[src] = bossId
    TriggerClientEvent("KP_bodyguard:assistantConfirmed", src, bossId)
end)

-- Optional: cleanup mapping when assistant disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    assistantToBossMap[src] = nil
end)