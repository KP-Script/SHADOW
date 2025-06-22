local BodyguardState = {
    guards = {},
    escortVehicles = {},
    convoyVehicles = {},
    convoyActive = false,
    bossPed = nil,
    currentFormation = nil,
    isSettingPositions = false,
    manualPositions = {},
    isDefensive = true,
    weaponsEnabled = true,
    vehicleFollowEnabled = false
}

function BodyguardState.ApplyManualOutfit(ped, outfit)
    if not outfit then return end
    SetPedComponentVariation(ped, 8,  outfit.tshirt_1 or 0,  outfit.tshirt_2 or 0, 2)
    SetPedComponentVariation(ped, 11, outfit.torso_1 or 0, outfit.torso_2 or 0, 2)
    SetPedComponentVariation(ped, 3,  outfit.arms or 0,      0, 2)
    SetPedComponentVariation(ped, 4,  outfit.pants_1 or 0,  outfit.pants_2 or 0, 2)
    SetPedComponentVariation(ped, 6,  outfit.shoes_1 or 0,  outfit.shoes_2 or 0, 2)
    SetPedComponentVariation(ped, 1,  outfit.mask_1 or 0, outfit.mask_2 or 0, 2)
    SetPedPropIndex(ped, 0, outfit.helmet_1 or -1, outfit.helmet_2 or 0, true)
    SetPedPropIndex(ped, 2, outfit.chain_1 or 0,   outfit.chain_2 or 0, true)
end

return BodyguardState