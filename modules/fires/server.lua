Fires = {}

function StartFire(coords, data)
    local index
    local data = data or {}
    repeat
        index = math.random(1, 999999999)
    until not Fires[index]
    local maxHealth = data.maxHealth or 100
    Fires[index] = {
        coords = coords, 
        offset = data.offset or vector3(0.0, 0.0, 0.0),
        rotation = data.rotation or vector3(0.0, 0.0, 0.0),
        flame = data.flame or {
            dict = "core",
            particle = "fire_object",
            stack = 3, -- Amount of flames to stack on eachother.
            height = 0.4, -- Each flame particle's height
            scale = 3.0,
        },
        smoke = data.flame or {
            dict = "des_gas_station",
            particle = "ent_ray_paleto_gas_plume_L",
            stack = 3, -- Amount of flames to stack on eachother.
            height = 6.0, -- Each flame particle's height
            scale = 1.0,
        },
        fighters = {},
        maxHealth = maxHealth,
        health = maxHealth
    }
    TriggerClientEvent("pickle_firefighterjob:startFire", -1, index, Fires[index])
    return index, Fires[index]
end

function RemoveFire(index, rewards)
    local fire = Fires[index]
    Fires[index] = nil
    if rewards then
        for k,v in pairs(fire.fighters) do
            if GetPlayerName(k) then
                local scale = v / fire.maxHealth
                if scale > 1 then
                    scale = 1
                end
                local player_rewards = {}
                for i=1, #rewards do 
                    player_rewards[#player_rewards + 1] = { 
                        type = rewards[i].type, 
                        name = rewards[i].name, 
                        amount = math.ceil(rewards[i].amount * scale)
                    }
                    print(json.encode(player_rewards[#player_rewards]))
                    print("-------------")
                end
                GiveRewards(k, player_rewards)
            end
        end
    end
    TriggerClientEvent("pickle_firefighterjob:removeFire", -1, index)
end

RegisterNetEvent("pickle_firefighterjob:attackFire", function(index, damage)
    local source = source
    if not Fires[index] then return end
    if not Fires[index].fighters[source] then 
        Fires[index].fighters[source] = damage
    else
        Fires[index].fighters[source] = Fires[index].fighters[source] + damage
    end
    Fires[index].health = Fires[index].health - damage
    if Fires[index].health < 0.1 then 
        RemoveFire(index, Config.Fires.rewards)
    else
        TriggerClientEvent("pickle_firefighterjob:updateFire", -1, index, Fires[index])
    end
end)

RegisterNetEvent("pickle_firefighterjob:startEffect", function(net_id, dict, particleName, off, rot, scale) 
    TriggerClientEvent("pickle_firefighterjob:startEffect", -1, net_id, dict, particleName, off, rot, scale)
end)

RegisterNetEvent("pickle_firefighterjob:stopEffect", function(net_id) 
    TriggerClientEvent("pickle_firefighterjob:stopEffect", -1, net_id)
end)

CreateThread(function()
    Wait(1000)
    StartFire(vector3(1752.9574, -1480.4850, 112.8672))
end)