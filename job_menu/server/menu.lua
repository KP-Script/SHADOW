local ESX = exports["es_extended"]:getSharedObject()

local function IsCartel(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.job.name == Config.JobName
end

RegisterNetEvent("shadowcartel:idSearch", function(targetId)
    local src = source
    if not IsCartel(src) then return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local identity = ("%s %s"):format(xTarget.get('firstName'), xTarget.get('lastName'))
    local job = xTarget.getJob().label
    local dob = xTarget.get('dateofbirth') or "Unknown"
    local sex = xTarget.get('sex') or "Unknown"

    TriggerClientEvent("chat:addMessage", src, {
        color = {0, 255, 255},
        args = {"Shadow Cartel", ("ID: %s | Name: %s | Job: %s | DOB: %s | Sex: %s"):format(targetId, identity, job, dob, sex)}
    })
end)

RegisterNetEvent("shadowcartel:searchInventory", function(targetId)
    local src = source
    if not IsCartel(src) then return end
    exports.ox_inventory:openInventory("player", targetId, src)
end)

RegisterNetEvent("shadowcartel:toggleCuff", function(targetId)
    if not IsCartel(source) then return end
    TriggerClientEvent("shadowcartel:toggleCuff", targetId)
end)

RegisterNetEvent("shadowcartel:escort", function(targetId)
    if not IsCartel(source) then return end
    TriggerClientEvent("shadowcartel:escort", targetId, source)
end)

RegisterNetEvent("shadowcartel:putInVehicle", function(targetId)
    if not IsCartel(source) then return end
    TriggerClientEvent("shadowcartel:putInVehicle", targetId)
end)

RegisterNetEvent("shadowcartel:dragOut", function(targetId)
    if not IsCartel(source) then return end
    TriggerClientEvent("shadowcartel:dragOut", targetId)
end)

RegisterNetEvent("shadowcartel:finePlayer", function(targetId, amount, reason)
    local src = source
    if not IsCartel(src) then return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    xTarget.removeAccountMoney('bank', amount)
    TriggerClientEvent("esx:showNotification", targetId, ("You were fined ₹%s for: %s"):format(amount, reason))
end)

RegisterNetEvent("shadowcartel:vehicleInfo", function(netId)
    local src = source
    if not IsCartel(src) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    local plate = GetVehicleNumberPlateText(vehicle)

    MySQL.query('SELECT * FROM owned_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result[1] then
            local ownerName = result[1].owner or "Unknown"
            local info = json.decode(result[1].vehicle or "{}")
            local model = info.model or "Vehicle"

            TriggerClientEvent("chat:addMessage", src, {
                color = {0, 255, 100},
                args = {"Shadow Cartel", ("Vehicle: %s | Plate: %s | Owner: %s"):format(model, plate, ownerName)}
            })
        else
            TriggerClientEvent("chat:addMessage", src, {
                color = {255, 0, 0},
                args = {"Shadow Cartel", "Vehicle not found in records."}
            })
        end
    end)
end)
