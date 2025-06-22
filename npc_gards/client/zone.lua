local inCayo = false

lib.zones.poly({
    points = Config.CayoPolygon,
    thickness = 100.0,
    debug = false,
    inside = function()
        if not inCayo then
            inCayo = true
            TriggerEvent("esx:showNotification", "You have entered Cayo Perico.")
        end
    end,
    onExit = function()
        if inCayo then
            inCayo = false
            TriggerEvent("esx:showNotification", "You have left Cayo Perico.")
        end
    end
})

exports("IsPlayerInCayo", function()
    return inCayo
end)
