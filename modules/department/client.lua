Department = nil
local DepartmentInteractions = {} 

function InitializeScript()
    for i=1, #Config.Departments do 
        local dept = Config.Departments[i]
        if dept.blip then
            CreateBlip(dept.blip)
        end
        DepartmentInteractions[i] = {}
        DepartmentInteractions[i].duty = CreateInteraction({
            label = _L("interact_duty",  _L("on")),
            coords = dept.duty.coords,
            heading = dept.duty.heading,
            model = dept.duty.model
        }, function(selected)
            DepartmentInteract(i, "duty")
        end)
        DepartmentInteractions[i].remove_vehicle = CreateInteraction({
            label = _L("interact_remove_vehicle"),
            coords = dept.vehicles.spawn.coords,
            heading = dept.vehicles.spawn.coords,
            hiddenKeypress = true
        }, function(selected)
            local vehicle = GetVehiclePedIsIn(PlayerPedId())
            if not DoesEntityExist(vehicle) then return end
            DeleteEntity(vehicle)
        end)
    end
end

function VehicleSelectItem(vehicleIndex)
    local deptIndex = Department.index
    local dept = Config.Departments[deptIndex]
    local vehicles = dept.vehicles
    local vehicle = vehicles.catalog[vehicleIndex]
    local options = {}
    for i=1, #vehicle.required do 
        local required = vehicle.required[i]
        local title
        local description
        if required.type == "cash" then
            title = "$" .. required.amount
        elseif required.type == "xp" then
            title = _L("required_level", Config.XPCategories[required.name].label, required.amount)
        else
            title = Inventory.Items[required.name].label
            description = "x" .. required.amount
        end
        local option = {
            title = title,
            description = description
        }
        options[#options + 1] = option
    end
    options[#options + 1] = {
        title = _L("confirm_transaction"),
        description = _L("confirm_transaction_desc"),
        onSelect = function()
            ServerCallback("pickle_firefighterjob:vehicleTransaction", function(result) 
                if not result then return end
                local spawn = vehicles.spawn
                local entity = CreateVeh(vehicle.model, spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.heading, true, false)
                TaskWarpPedIntoVehicle(PlayerPedId(), entity, -1)
            end, deptIndex, vehicleIndex)
        end
    }
    local id = 'firefighter_vehicle_' .. deptIndex .. "_" .. vehicleIndex
    lib.registerContext({
        id = id,
        title = _L("vehicles"),
        options = options
    })
    lib.showContext(id)
end

function DisplayVehicle()
    local options = {}
    local deptIndex = Department.index
    local dept = Config.Departments[deptIndex]
    local vehicles = dept.vehicles
    for i=1, #vehicles.catalog do 
        local vehicle = vehicles.catalog[i]
        local description
        if not vehicle.required or #vehicle.required > 1 or vehicle.required[1].type ~= "cash" then
            description = vehicle.description
        else
            description = "$" .. vehicle.required[1].amount .. " - " .. vehicle.description
        end
        local option = {
            title = vehicle.label,
            description = description,
            onSelect = function()
                VehicleSelectItem(i)
            end
        }
        options[#options + 1] = option
    end
    if #options < 1 then return end
    local id = 'firefighter_vehicle_'
    lib.registerContext({
        id = id,
        title = _L("vehicles"),
        options = options
    })
    lib.showContext(id)
end

function StoreSelectItem(itemIndex)
    local deptIndex = Department.index
    local dept = Config.Departments[deptIndex]
    local store = dept.store
    local item = store.catalog[itemIndex]
    local options = {}
    for i=1, #item.required do 
        local required = item.required[i]
        local title
        local description
        if required.type == "cash" then
            title = "$" .. required.amount
        elseif required.type == "xp" then
            title = _L("required_level", Config.XPCategories[required.name].label, required.amount)
        else
            title = Inventory.Items[required.name].label
            description = "x" .. required.amount
        end
        local option = {
            title = title,
            description = description
        }
        options[#options + 1] = option
    end
    options[#options + 1] = {
        title = _L("confirm_transaction"),
        description = _L("confirm_transaction_desc"),
        onSelect = function()
            TriggerServerEvent("pickle_firefighterjob:storeTransaction", deptIndex, itemIndex)
        end
    }
    local id = 'firefighter_store_' .. deptIndex .. "_" .. itemIndex
    lib.registerContext({
        id = id,
        title = _L("store"),
        options = options
    })
    lib.showContext(id)
end

function DisplayStore()
    local options = {}
    local deptIndex = Department.index
    local dept = Config.Departments[deptIndex]
    local store = dept.store
    for i=1, #store.catalog do 
        local item = store.catalog[i]
        local description
        if not item.required or #item.required > 1 or item.required[1].type ~= "cash" then
            description = item.description
        else
            description = "$" .. item.required[1].amount .. " - " .. item.description
        end
        local option = {
            title = Inventory.Items[item.name].label,
            description = description,
            onSelect = function()
                StoreSelectItem(i)
            end
        }
        options[#options + 1] = option
    end
    if #options < 1 then return end
    local id = 'firefighter_store_'
    lib.registerContext({
        id = id,
        title = _L("store"),
        options = options
    })
    lib.showContext(id)
end

function DepartmentInteract(index, name)
    if name == "boss" then 
        OpenBossMenu(index)
    elseif name == "duty" then
        TriggerServerEvent("pickle_firefighterjob:setDuty", index, not Department)
    elseif name == "vehicles" then
        DisplayVehicle()
    elseif name == "store" then
        DisplayStore()
    end
end

function OndutyEvent(index)
    local dept = Config.Departments[index]
    local interacts = {
        boss = {locale = "interact_boss"},
        vehicles = {locale = "interact_vehicles"},
        store = {locale = "interact_store"},
    }
    for k,v in pairs(interacts) do 
        DepartmentInteractions[index][k] = CreateInteraction({
            label = _L(v.locale),
            coords = dept[k].coords,
            heading = dept[k].heading,
            model = dept[k].model
        }, function(selected)
            DepartmentInteract(index, k)
        end)
    end
    UpdateInteraction(DepartmentInteractions[index].duty, {
        label = _L("interact_duty", _L("off")),
    }, function(selected)
        DepartmentInteract(index, "duty")
    end)
end

function OffdutyEvent(index)
    local dept = Config.Departments[index]
    UpdateInteraction(DepartmentInteractions[index].duty, {
        label = _L("interact_duty", _L("on")),
    }, function(selected)
        DepartmentInteract(index, "duty")
    end)
end

function CleanupDepartment(index)
    for k,v in pairs(DepartmentInteractions[index]) do 
        if k ~= "duty" then
            DeleteInteraction(v)
            DepartmentInteractions[index][k] = nil
        end
    end
end

RegisterNetEvent("pickle_firefighterjob:setDuty", function(index)
    if index and (not Department or Department.index ~= index) then
        if Department then
            local index = Department.index
            Department = nil
            CleanupDepartment(index)
        end
        Department = {index = index}
        OndutyEvent(index)
    elseif not index and Department then
        local index = Department.index
        Department = nil
        CleanupDepartment(index)
        OffdutyEvent(index)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    TriggerServerEvent("pickle_firefighters:initializePlayer")
end)

CreateThread(function() 
    InitializeScript()
    Department = {index = 1}
    OndutyEvent(1)
end)