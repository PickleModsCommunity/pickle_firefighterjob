Config = {}

Config.Debug = true

Config.Language = "en" -- Language to use.

Config.RenderDistance = 20.0 -- Model Display Radius.

Config.InteractDistance = 2.0 -- Interact Radius

Config.UseTarget = true -- When set to true, it'll use targeting instead of key-presses to interact.

Config.NoModelTargeting = true -- When set to true and using Target, it'll spawn a small invisible prop so you can third-eye when no entity is defined.

Config.Marker = { -- This will only be used if enabled, not using target, and no model is defined in the interaction.
    enabled = true,
    id = 2,
    scale = 0.25, 
    color = {255, 255, 255, 127}
}

Config.XPEnabled = true -- When set to true, this will enable Pickle's XP compatibility, and enable xp rewards.

Config.XPCategories = { -- Registered XP Types for Pickle's XP.
    ["firefighter"] = {
        label = "Firefighter", 
        xpStart = 1000, 
        xpFactor = 0.2, 
        maxLevel = 2
    },
}

Config.Alerts = function(data) -- Alerts used in the script, great for linking to dispatch systems.
end

Config.Default = {
    permissions = { -- Permissions settings.
        duty = {
            jobs = {["firefighter"] = 0},
            groups = {"admin", "god"}
        },
    },
    outfit = { -- On-duty outfits.
        male = {
            ['arms'] = 0,
            ['tshirt_1'] = 15, 
            ['tshirt_2'] = 0,
            ['torso_1'] = 86, 
            ['torso_2'] = 0,
            ['bproof_1'] = 0,
            ['bproof_2'] = 0,
            ['decals_1'] = 0, 
            ['decals_2'] = 0,
            ['chain_1'] = 0,
            ['chain_2'] = 0,
            ['pants_1'] = 10, 
            ['pants_2'] = 2,
            ['shoes_1'] = 56, 
            ['shoes_2'] = 0,
            ['helmet_1'] = 14, 
            ['helmet_2'] = 0,
        },
        female = {
            ['arms'] = 0,
            ['tshirt_1'] = 15, 
            ['tshirt_2'] = 0,
            ['torso_1'] = 86, 
            ['torso_2'] = 0,
            ['bproof_1'] = 0,
            ['bproof_2'] = 0,
            ['decals_1'] = 0, 
            ['decals_2'] = 0,
            ['chain_1'] = 0,
            ['chain_2'] = 0,
            ['pants_1'] = 10, 
            ['pants_2'] = 2,
            ['shoes_1'] = 56, 
            ['shoes_2'] = 0,
            ['helmet_1'] = 14, 
            ['helmet_2'] = 0,
        }
    }
}

Config.Departments = {
    {
        job = "firefighter", -- This is what the boss menu will be based on. It is recommended to only allow this job in this department.
        label = "Los Santos Fire Department", -- Department label for notifications & texts.
        permissions = nil, -- When nil, defaults to Config.Default.permissions.  
        outfit = nil, -- When nil, defaults to Config.Default.outfit.  
        blip = {
            label = "Los Santos Fire Department",
            coords = vector3(204.8514, -1652.1567, 29.8007),
            id = 60,
            color = 1,
            scale = 0.75,
        },
        boss = {
            coords = vector3(193.0856, -1641.4713, 29.8007),
            heading = 45.2183
        },
        duty = {
            model = {hash = `mp_m_boatstaff_01`},
            coords = vector3(198.8848, -1639.2321, 29.8008),
            heading = 273.0646
        },
        vehicles = {
            coords = vector3(214.9789, -1651.9619, 29.8007),
            heading = 50.5791,
            model = {hash = `s_m_y_fireman_01`},
            spawn = {
                coords = vector3(209.1309, -1647.2399, 29.8687),
                heading = 320.1417,
            },
            catalog = {
                {
                    label = "Firetruck", 
                    model = `firetruk`, 
                    description = "A great truck that gets the job done.",
                    required = {
                        {type = "cash", amount = 100},
                        {type = "xp", name = "firefighter", amount = 1}, -- Amount = Level
                    }
                },
            }
        },
        store = {
            coords = vector3(205.2619, -1641.4888, 29.8008),
            heading = 49.1569,
            catalog = {
                {
                    name = "water",
                    description = "A water bottle.",
                    amount = 1,
                    required = {
                        {type = "cash", amount = 100},
                    },
                },
            }
        },
    }
}