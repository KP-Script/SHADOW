local whitelist = {}
local pendingRequests = {}

-- Utility: Check if player is cartel
local function isCartel(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.job.name == Config.CartelJob
end

-- Check if player's job is whitelisted
local function isWhitelistedJob(jobName)
    return whitelist[jobName] or jobName == Config.CartelJob
end

-- Player aiming detection
RegisterNetEvent("shadowcartel_guard:playerAiming", function(coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not isWhitelistedJob(xPlayer.job.name) then
        TriggerClientEvent("shadowcartel_guard:attackPlayer", -1, coords)
    end
end)

-- Player holding weapon
RegisterNetEvent("shadowcartel_guard:playerArmed", function(coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not isWhitelistedJob(xPlayer.job.name) then
        TriggerClientEvent("shadowcartel_guard:attackPlayer", -1, coords)
    end
end)

-- Gang submits entry request
RegisterNetEvent("shadowcartel_guard:submitRequest", function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Check if job is allowed to request
    if not Config.AllowedRequestJobs[xPlayer.job.name] then
        TriggerClientEvent("esx:showNotification", src, "Your gang is not allowed to request entry.")
        return
    end

    pendingRequests[src] = {
        name = xPlayer.getName(),
        job = xPlayer.job.name,
        reason = reason
    }

    TriggerClientEvent("esx:showNotification", src, "Request submitted to Shadow Cartel.")
end)

-- Shadow Cartel reviews all requests
RegisterNetEvent("shadowcartel_guard:approveMenu", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.job.name ~= Config.CartelJob then return end

    for id, data in pairs(pendingRequests) do
        TriggerClientEvent("esx:showNotification", src,
            string.format("%s (ID: %d, Job: %s): %s\nUse /acceptentry %d or /rejectentry %d",
                data.name, id, data.job or "unknown", data.reason, id, id)
        )
    end
end)

-- Accept gang's request (by job)
RegisterCommand("acceptentry", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= Config.CartelJob then return end

    local targetId = tonumber(args[1])
    local data = pendingRequests[targetId]
    if data and data.job then
        whitelist[data.job] = true
        pendingRequests[targetId] = nil
        TriggerClientEvent("esx:showNotification", source, "Gang '" .. data.job .. "' granted access.")
        TriggerClientEvent("esx:showNotification", targetId, "Your gang was granted access to Cayo.")
    end
end, false)

-- Reject a gang's request
RegisterCommand("rejectentry", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= Config.CartelJob then return end

    local targetId = tonumber(args[1])
    if pendingRequests[targetId] then
        pendingRequests[targetId] = nil
        TriggerClientEvent("esx:showNotification", source, "Entry request rejected.")
        TriggerClientEvent("esx:showNotification", targetId, "Your request was rejected by the Shadow Cartel.")
    end
end, false)

-- Optional: clear whitelist for a gang job
RegisterCommand("clearwhitelist", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= Config.CartelJob then return end

    local job = args[1]
    if job and whitelist[job] then
        whitelist[job] = nil
        TriggerClientEvent("esx:showNotification", source, "Whitelist cleared for job: " .. job)
    else
        TriggerClientEvent("esx:showNotification", source, "Invalid or not whitelisted job.")
    end
end, false)

RegisterNetEvent("shadowcartel_guard:heliThreatDetected", function(coords)
    -- Broadcast to client: ground guards respond too
    TriggerClientEvent("shadowcartel_guard:alertGroundGuards", -1, coords)
end)


local recentThreats = {}

CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()
        for i = #recentThreats, 1, -1 do
            if now - recentThreats[i] > 30 then
                table.remove(recentThreats, i)
            end
        end
    end
end)

RegisterNetEvent("shadowcartel_guard:heliSpottedThreat", function(coords)
    table.insert(recentThreats, os.time())

    if #recentThreats >= 3 then
        TriggerClientEvent("shadowcartel_guard:broadcastAlert", -1, coords, "[LOCKDOWN] Multiple intruders detected! Reinforcements incoming.")
        TriggerClientEvent("shadowcartel_guard:spawnReinforcements", -1)
    end
end)

RegisterNetEvent("shadowcartel_guard:heliSpottedThreat", function(coords)
    TriggerClientEvent("shadowcartel_guard:broadcastAlert", -1, coords, "Helicopter Spotted an Armed Player!")
    TriggerClientEvent("shadowcartel_guard:attackPlayer", -1, coords)
end)

RegisterNetEvent("shadowcartel_guard:motionAlert", function(coords)
    TriggerClientEvent("shadowcartel_guard:broadcastAlert", -1, coords, "Motion Detected!")
end)