local ESX = exports["es_extended"]:getSharedObject()

-- 🔎 ID Search
RegisterNetEvent("shadowcartel:idSearch", function(targetId)
    local src = source
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local identity = ("%s %s"):format(xTarget.get('firstName'), xTarget.get('lastName'))
    local job = xTarget.getJob().label
    local dob = xTarget.get('dateofbirth') or "Unknown"
    local sex = xTarget.get('sex') or "Unknown"
    local id = xTarget.source

    TriggerClientEvent("chat:addMessage", src, {
        color = {0, 255, 255},
        args = {"Shadow Cartel", ("ID: %s | Name: %s | Job: %s | DOB: %s | Sex: %s"):format(id, identity, job, dob, sex)}
    })
end)

-- 🎒 Inventory Search via OX
RegisterNetEvent("shadowcartel:searchInventory", function(targetId)
    local src = source
    exports.ox_inventory:openInventory("player", targetId, src)
end)

-- 🔗 Cuff/Uncuff Toggle
RegisterNetEvent("shadowcartel:toggleCuff", function(targetId)
    TriggerClientEvent("shadowcartel:toggleCuff", targetId)
end)

-- 👣 Escort Player
RegisterNetEvent("shadowcartel:escort", function(targetId)
    TriggerClientEvent("shadowcartel:escort", targetId, source)
end)

-- 🚓 Put in Vehicle
RegisterNetEvent("shadowcartel:putInVehicle", function(targetId)
    TriggerClientEvent("shadowcartel:putInVehicle", targetId)
end)

-- 🚪 Drag Out of Vehicle
RegisterNetEvent("shadowcartel:dragOut", function(targetId)
    TriggerClientEvent("shadowcartel:dragOut", targetId)
end)

-- 💰 Fine Player
RegisterNetEvent("shadowcartel:finePlayer", function(targetId, amount, reason)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    xTarget.removeAccountMoney('bank', amount)
    TriggerClientEvent("esx:showNotification", targetId, ("You were fined ₹%s for: %s"):format(amount, reason))
end)

-- 🚗 Vehicle Info Lookup (MySQL required)
RegisterNetEvent("shadowcartel:vehicleInfo", function(netId)
    local src = source
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
