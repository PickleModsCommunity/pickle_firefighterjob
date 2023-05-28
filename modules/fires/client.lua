Fires = {}
local FireInstances = {}
local Effects = {}
local FireTargetEnabled = false
local UsingTank = true

function GetDirectionFromRotation(rotation)
    local dm = (math.pi / 180)
    return vector3(-math.sin(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.cos(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.sin(dm * rotation.x))
end

function GetDirectionCoords()
    local range = 1000.0
	local coords = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
	local ecoords = vector3(coords.x + dir.x * range, coords.y + dir.y * range, coords.z + dir.z * range)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, ecoords.x, ecoords.y, ecoords.z, -1, -1, 1))
	return hit, endCoords, entityHit 
end

function DisableFireTarget()
    FireTargetEnabled = false
end

function EnableFireTarget(damagePerTick, decreaseFunction)
    CreateThread(function()
        if FireTargetEnabled then 
            DisableFireTarget()
            Wait(1000)
        end
        FireTargetEnabled = true
        local spriteDict, sprite = "darts", "dart_reticules"
        local damage = 0
        while FireTargetEnabled do 
            local hit, coords, entity = GetDirectionCoords()
            RequestStreamedTextureDict(spriteDict, false)
            if hit and coords then 
                local found = false
                for k,v in pairs(FireInstances) do
                    if v.prop == entity then
                        found = true
                        DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, 255, 0, 0, 255)
                        local ped = PlayerPedId()
                        local dist = #(GetEntityCoords(ped) - GetEntityCoords(v.prop))
                        local decrease = decreaseFunction(k, dist)
                        if decrease and damage < Config.Fires.damageUpdate then
                            damage = damage + damagePerTick
                        elseif damage > 0 then
                            TriggerServerEvent("pickle_firefighterjob:attackFire", k, damage)
                            damage = 0
                        end
                        break
                    end
                end
                if not found then 
                    DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, 255, 255, 255, 255)
                end
            else
                DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, 255, 255, 255, 255)
            end
            Wait(0)
        end
    end)
end

function EnsureFire(index)
    if FireInstances[index] then return FireInstances[index] end
    local data = Fires[index]
    local off = data.offset or vector3(0.0, 0.0, 0.0)
    local rot = data.rotation or vector3(0.0, 0.0, 0.0)
    local prop = CreateProp(`v_serv_abox_g3`, data.coords.x, data.coords.y, data.coords.z, false, true, false)
    SetEntityAlpha(prop, 0, false)
    FreezeEntityPosition(prop, true)
    local particles = {}
    if data.flame then 
        for i=1, data.flame.stack do 
            local newOff = vector3(off.x, off.y, off.z + (data.flame.height * (i - 1)))
            particles[#particles + 1] = { type = "flame", offset = newOff, rotation = rot, handle = PlayEffect(data.flame.dict, data.flame.particle, prop, newOff, rot, data.flame.scale)}
            local percent = data.health / data.maxHealth
            local scale = data.flame.scale * percent
            local height = (particles[#particles].offset.z - off.z) * percent
            SetParticleFxLoopedScale(particles[#particles].handle, scale)
            SetParticleFxLoopedOffsets(particles[#particles].handle, off.x, off.y, off.z + height, rot.x, rot.y, rot.z)
        end
    end
    if data.smoke then 
        for i=1, data.smoke.stack do 
            local newOff = vector3(off.x, off.y, off.z + (data.smoke.height * (i - 1)))
            particles[#particles + 1] = { type = "smoke", offset = newOff, rotation = rot, handle = PlayEffect(data.smoke.dict, data.smoke.particle, prop, newOff, rot, data.smoke.scale)}
            local percent = data.health / data.maxHealth
            local scale = data.smoke.scale * percent
            local height = (particles[#particles].offset.z - off.z) * percent
            SetParticleFxLoopedScale(particles[#particles].handle, scale)
            SetParticleFxLoopedOffsets(particles[#particles].handle, off.x, off.y, off.z + height, rot.x, rot.y, rot.z)
        end
    end
    FireInstances[index] = {
        prop = prop,
        particles = particles
    }
    return FireInstances[index]
end

function RemoveFire(index)
    if not FireInstances[index] then return end
    DeleteEntity(FireInstances[index].prop)
    for i=1, #FireInstances[index].particles do
        RemoveParticleFx(FireInstances[index].particles[i].handle, true)
    end
    FireInstances[index] = nil
end

function WaterTank()
    UsingTank = true
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local prop = CreateProp(`v_ind_cs_gascanister`, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 24818)
    local off = vector3(0.0, -0.25, 0.0)
    local rot = vector3(0.0, 90.0, 0.0)
    AttachEntityToEntity(prop, ped, boneIndex, off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)
    
    local nozzle = CreateProp(`prop_hose_nozzle`, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local off = vector3(0.2, 0.0, 0.0)
    local rot = vector3(18.0, 180.0, -25.0)
    AttachEntityToEntity(nozzle, ped, boneIndex, off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)

    GiveWeaponToPed(ped, `WEAPON_FIREEXTINGUISHER`, 0, true, true)
    
    local WaterEffect

    EnableFireTarget(0.5, function(index, dist)
        return IsDisabledControlPressed(1, 24)  
    end)
    while UsingTank do 
        local ped = PlayerPedId()
        SetCurrentPedWeapon(ped, `WEAPON_FIREEXTINGUISHER`, true)
        SetPedCurrentWeaponVisible(ped, false, false, true)
        DisablePlayerFiring(PlayerId(), true)
        if IsDisabledControlPressed(1, 24) then
            if not WaterEffect then 
                WaterEffect = PlayEffect("core", "water_cannon_jet", nozzle, nil, nil, 1.0, true)
            end
        elseif WaterEffect then
            StopParticleFxLooped(WaterEffect, true)
            TriggerServerEvent("pickle_firefighterjob:stopEffect", ObjToNet(nozzle))
            WaterEffect = nil
        end 
        Wait(0)
    end 
    DisableFireTarget()
end

CreateThread(function()
    local UsingExtinguisher = false
    while true do 
        local wait = 1500
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        for k,v in pairs(Fires) do 
            local dist = #(pcoords-v.coords)
            if dist < Config.RenderDistance then 
                EnsureFire(k)
            else 
                RemoveFire(k)
            end
        end
        local found, hash = GetCurrentPedWeapon(ped, 1)
        if not UsingTank then
            if not UsingExtinguisher and found and hash == Config.Fires.extinguisher.hash and not FireTargetEnabled then 
                UsingExtinguisher = true
                EnableFireTarget(0.5, function(index, dist)
                    local ped = PlayerPedId()
                    if IsPedShooting(ped) and dist < Config.Fires.extinguisher.range then return true end 
                end)
            elseif UsingExtinguisher and (not found or hash ~= Config.Fires.extinguisher.hash) then
                UsingExtinguisher = false
                DisableFireTarget()
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_firefighterjob:startFire", function(index, data)
    Fires[index] = data
end)

RegisterNetEvent("pickle_firefighterjob:removeFire", function(index) 
    Fires[index] = nil
    RemoveFire(index)
end)

RegisterNetEvent("pickle_firefighterjob:updateFire", function(index, data)
    Fires[index] = data
    if not FireInstances[index] then return end 
    local fire = Fires[index]
    for i=1, #FireInstances[index].particles do 
        local particle = FireInstances[index].particles[i]
        local cfg = fire[particle.type]
        local percent = fire.health / fire.maxHealth
        local scale = cfg.scale * percent
        local height = (particle.offset.z - fire.offset.z) * percent
        SetParticleFxLoopedScale(particle.handle, scale)
        SetParticleFxLoopedOffsets(particle.handle, fire.offset.x, fire.offset.y, fire.offset.z + height, fire.rotation.x, fire.rotation.y, fire.rotation.z)
    end
end)

RegisterNetEvent("pickle_firefighterjob:stopFire", function(index, data)
    Fires[index] = nil
end)

RegisterNetEvent("pickle_firefighterjob:startEffect", function(net_id, dict, particleName, off, rot, scale)
    if not NetworkDoesNetworkIdExist(net_id) then return end
    local object = NetToObj(net_id)
    Effects[net_id] = PlayEffect(dict, particleName, object, off, rot, scale)
end)

RegisterNetEvent("pickle_firefighterjob:stopEffect", function(net_id)
    if not Effects[net_id] then return end
    StopParticleFxLooped(Effects[net_id], true)
    Effects[net_id] = nil
end)

AddEventHandler("onResourceStop", function(name)
    if GetCurrentResourceName() ~= name then return end
    for k,v in pairs(Fires) do 
        RemoveFire(k)
    end
end)

RegisterCommand("tank", function()
    WaterTank()
end)