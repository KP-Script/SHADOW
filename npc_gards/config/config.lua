Config = {}

-- Jobs allowed to request Cayo entry
Config.AllowedRequestJobs = {
    arz = true,
    bld = true,
    mafia = true
}


-- PEDs for interaction (requests/approval)
Config.RequestPed = {
    model = "a_m_m_farmer_01",
    coords = vector4(1438.4750, -2592.3799, 48.4081, 122.5687),
    allowedJobs = Config.AllowedRequestJobs
}

Config.ApprovePedguardSkin = {
    model = "u_m_m_jesus_01",
    coords = vector4(4644.2393, -4481.8779, 4.2722, 11.4963)
}

-- Cayo Zone (simple radius for now)
Config.CayoCenter = vector3(5015.0, -5745.0, 28.0)
Config.CayoRadius = 250.0

-- Allowed job
Config.CartelJob = "sgod"

-- PEDs to spawn as guards
local dresspack1 = {
    sex = 0,
    tshirt_1 = 0, tshirt_2 = 2,
    torso_1 = 47, torso_2 = 0,
    arms = 0,
    pants_1 = 48, pants_2 = 0,
    shoes_1 = 17, shoes_2 = 0,
    helmet_1 = -1, helmet_2 = -1,
    chain_1 = 56, chain_2 = 0,
    decals_1 = 0, decals_2 = 0,
    mask_1 = 23, mask_2 = 0
}
Config.dresspack=dresspack1

Config.Guards = {
    {
        model = "mp_m_freemode_01",
        coords = vector4(4632.0894, -4463.9917, 3.9485, 92.6625),
        weapon = "WEAPON_CARBINERIFLE",
        appearance = dresspack1
    },
    {
        model = "mp_m_freemode_01",
        coords = vector4(4610.9922, -4463.9917, 3.4665, 269.7293),
        weapon = "WEAPON_COMBATMG",
        appearance = dresspack1
    },
    {
        model = "mp_m_freemode_01",
        coords = vector4(4620.9272, -4464.0571, 3.5638, 89.5213),
        weapon = "WEAPON_COMBATMG",
        appearance = dresspack1
    },
    {
        model = "mp_m_freemode_01",
        coords = vector4(4622.1470, -4464.0889, 3.5615, 281.6271),
        weapon = "WEAPON_COMBATMG",
        appearance = dresspack1
    },
}

Config.Helicopters = {
    {
        model = "buzzard",
        coords = vector4(4649.5757, -4472.2471, 4.7286, 92.3433), -- spawn position
        patrolPoints = {
            vector3(4623.7871, -4409.3594, 52.4345),
            vector3(4551.2993, -4454.7412, 39.2452),
            vector3(4606.5303, -4533.9609, 35.2139),
            vector3(4690.1821, -4472.2207, 29.6310),
            vector3(4686.5244, -4427.8267, 25.1755),
        }
    },
    {
        model = "buzzard",
        coords = vector4(4891.0098, -5735.5425, 26.2889, 160.3327),
        patrolPoints = {
            vector3(4889.5444, -5732.5801, 58.7860),
            vector3(4912.2207, -5817.4702, 55.5781),
            vector3(5078.3623, -5843.8599, 44.4862),
            vector3(5144.6094, -5746.4048, 41.3010),
            vector3(4999.1470, -5609.4536, 52.9085),
            vector3(4787.4438, -5667.0952, 84.6873)
        }
    }
}

Config.motionZones = {
    {
        coords = vector3(4600.0, -4500.0, 4.0),
        radius = 25.0
    },
    {
        coords = vector3(5020.0, -5745.0, 28.0),
        radius = 30.0
    }
}

Config.reinforcments = {
    dress = dresspack1,
    weapons = "WEAPON_CARBINERIFLE",
    vehicle = "sandking",
    Spawns = {
        vector3(4632.0, -4460.0, 4.0),
        vector3(4690.0, -4455.0, 4.0),
        vector3(4740.0, -4500.0, 4.0),
        vector3(4600.0, -4550.0, 4.0)
    }
}
