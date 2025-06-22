Config = {}

-- Shadow Cartel Job Setup
Config.BossJob = "sgod"            -- Job name for Shadow Cartel
Config.BossGrade = 2               -- Grade of the actual Boss
Config.AssistantGrade = 1         -- Grade of the Boss's Assistant

-- Guard Outfit (for manual spawn & vehicle guards)
Config.GuardOutfit = {
    tshirt_1 = 15, tshirt_2 = 0,
    torso_1 = 111, torso_2 = 0,
    arms = 0,
    pants_1 = 31, pants_2 = 0,
    shoes_1 = 25, shoes_2 = 0,
    helmet_1 = -1, helmet_2 = 0,
    chain_1 = 0, chain_2 = 0,
    mask_1 = 3, mask_2 = 0
}

-- Guard Model & Default Vehicle
Config.GuardModel = "mp_m_freemode_01"
Config.GuardVehicle = "baller6"
Config.GuardWeapon = ""

-- Spawn Logic
Config.SpawnDistance = 100.0      -- How far guards spawn from boss
Config.StopDistanceFromBoss = 10.0

-- Escort Configuration (for Convoy)
Config.escort = {
    vehicles = {
        {
            model = "baller6",     -- Front Guard Vehicle
            type = "guard",
            seats = 4
        },
        {
            model = "baller7",     -- Boss Vehicle (center)
            type = "boss",
            seats = 2
        },
        {
            model = "baller6",     -- Rear Guard Vehicle
            type = "guard",
            seats = 4
        }
    },

    spawnDistance = 100.0,         -- Convoy spawn distance from boss
    stopDistance = 10.0,           -- Convoy stops this far in front of boss

    weapons = {
        "WEAPON_CARBINERIFLE",
        "WEAPON_PISTOL"
    }
}

Config.HeliUnit = {
    model = "buzzard2", -- Or "frogger"
    spawnDistance = 150.0,
    patrolHeight = 35.0,
    patrolRadius = 40.0,
    weapon = "WEAPON_SNIPERRIFLE",
    guardCount = 2,
    threatDetectionRange = 70.0
}


-- Keybind
Config.AssignKey = 38 -- E key