math.randomseed(GetGameTimer() + os.time())

-- // EXPORTS \\ --
ESX = exports['es_extended']:getSharedObject()

-- // VARIABLES \\ --
local playerTask = {}
local cooldowns = {}
local lastSpawn = {}
local activeVehicles = {}

-- // FUNCTIONS \\ --
local function generateToken(len)
    local res = ""
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local max = #chars
    for i = 1, len do
        local idx = math.random(1, max)
        res = res .. string.sub(chars, idx, idx)
    end
    return res
end

function GiveNewTask(src)
    if cooldowns[src] and os.time() - cooldowns[src] < 2 then return end
    cooldowns[src] = os.time()

    local taskTypes = {}
    for i,_ in pairs(Config.Tasks) do
        table.insert(taskTypes, i)
    end

    local task = taskTypes[math.random(#taskTypes)]
    local coords = Config.Tasks[task].locations[math.random(#Config.Tasks[task].locations)]
    local token = generateToken(16)
    local expires = os.time() + 1800

    playerTask[src] = {task = task, coords = coords, token = token, expires = expires, created = os.time(), finished = false}
    TriggerClientEvent("dsx-inspectie:client:startTask", src, task, coords, token)
end

-- // EVENTS \\ --
RegisterNetEvent('dsx-inspectie:server:spawnVehicle', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if playerTask[src] == nil or not playerTask[src] then
        TriggerClientEvent("ox_lib:notify", src, {
            description = 'Je moet eerst een klus aannemen!',
            type = "error",
            icon = 'car',
            time = 2500,
        })
        return
    end

    local spawnPoint = Config.Locaties.SpawnVehicle.coords
    local playerCoords = xPlayer.getCoords(true) or vector3(0,0,0)
    if #(playerCoords - spawnPoint) > 50.0 then
        return exports["ElectronAC"]:banPlayer(src, "Inspectie voertuig inspawnen op grote afstand", "huidige coords: " .. tostring(playerCoords) .. " - spawnCoords: " .. tostring(spawnPoint), true)
    end

    if lastSpawn[src] and (os.time() - lastSpawn[src] < 60) then
        local timeLeft = 60 - (os.time() - lastSpawn[src])
        TriggerClientEvent("ox_lib:notify", src, {
            description = ('Wacht nog %d seconden voor je opnieuw kunt spawnen.'):format(timeLeft),
            type = "error",
            icon = 'car',
            time = 2500,
        })
        return
    end

    if activeVehicles[src] and DoesEntityExist(NetworkGetEntityFromNetworkId(activeVehicles[src])) then
        TriggerClientEvent("ox_lib:notify", src, {
            description = "Je hebt al een dienstvoertuig",
            type = "error",
            icon = 'car',
            time = 2500,
        })
        return
    end

    local vehicleModel = 'utillitruck'
    local heading = Config.Locaties.StartJob.heading
    local props = {}

    ESX.OneSync.SpawnVehicle(vehicleModel, spawnPoint, heading, {}, function(networkId)
        if networkId ~= 0 then
            local ped = GetPlayerPed(src)
            local veh = NetworkGetEntityFromNetworkId(networkId)
            if DoesEntityExist(veh) then
                Entity(veh).state.owner = xPlayer.identifier
                Entity(veh).state.emergency = xPlayer.identifier
                SetVehicleDirtLevel(veh, 0.0)
                for _ = 1, 20 do
                    Wait(0)
                    SetPedIntoVehicle(ped, veh, -1)
                    if GetVehiclePedIsIn(ped, false) == veh then
                        Citizen.SetTimeout(1500, function()
                            local entityOwner = NetworkGetEntityOwner(veh)
                            TriggerClientEvent('ox_lib:setVehicleProperties', entityOwner, networkId, props)
                        end)
                        break
                    end
                end

                lastSpawn[src] = os.time()
                activeVehicles[src] = networkId
            end
        end
    end)
end)

RegisterServerEvent('dsx-inspectie:server:delVehicle', function(vehId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local vehicle = NetworkGetEntityFromNetworkId(vehId)
    if not vehicle or not DoesEntityExist(vehicle) then
        TriggerClientEvent("ox_lib:notify", src, {
            description = "het voertuig kon niet worden geladen.",
            type = "error",
            icon = 'car',
            time = 2500,
        })
        return
    end

    if Entity(vehicle).state.owner ~= xPlayer.identifier then
        TriggerClientEvent("ox_lib:notify", src, {
            description = "Je kan dit voertuig niet wegzetten.",
            type = "error",
            icon = 'car',
            time = 2500,
        })
        return
    end

    DeleteEntity(vehicle)
    
    if activeVehicles[src] and activeVehicles[src] == vehId then
        activeVehicles[src] = nil
    end

    TriggerClientEvent("ox_lib:notify", src, {
        description = "Je dienstvoertuig is geparkeerd!",
        type = "success",
        icon = 'car',
        time = 2500,
    })
end)


RegisterNetEvent("dsx-inspectie:server:startShift", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if cooldowns[src] and os.time() - cooldowns[src] < 3 then
        return
    end

    if playerTask[src] then return end
    if not xPlayer then return end

    if xPlayer.job.name ~= Config.JobName then
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een inspectie dienst te starten zonder de juiste job", "Job: " .. tostring(xPlayer.job.name), true)
    end

    local ped = GetPlayerPed(src)
    if not ped then return end

    local playerCoords = GetEntityCoords(ped)
    if #(playerCoords - Config.Locaties.StartJob.coords) > 5.0 then
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een inspectie dienst te starten op een te grote afstand", "Speler: " .. tostring(playerCoords) .. " | Start: " .. tostring(Config.Locaties.StartJob.coords), true)
    end

    GiveNewTask(src)
end)

RegisterNetEvent("dsx-inspectie:server:finishTask", function(tokenFromClient)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not playerTask[src] then
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een taak te finishen zonder dat er een taak bestond", "task: nil", true)
    end

    local data = playerTask[src]
    if not tokenFromClient or tokenFromClient ~= data.token then
        playerTask[src] = nil
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een taak te finishen zonder geldige token", "Gegeven: " .. tostring(tokenFromClient) .. " | Verwacht: " .. tostring(data.token), true)
    end

    if os.time() > data.expires then
        playerTask[src] = nil
        return
    end

    if data.finished then
        playerTask[src] = nil
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een taak te finishen terwijl deze al gefinished was", "", true)
    end

    local ped = GetPlayerPed(src)
    if not ped then
        playerTask[src] = nil
        return exports["ElectronAC"]:banPlayer(src, "Speler coordinaten niet beschikbaar", "", true)
    end

    local playerCoords = GetEntityCoords(ped)
    if #(playerCoords - data.coords) > 5.0 then
        playerTask[src] = nil
        return exports["ElectronAC"]:banPlayer(src, "Probeerde een taak te finishen maar was niet eens in de buurt", "Speler: " .. tostring(playerCoords) .. " | Taak: " .. tostring(data.coords), true)
    end

    local reward = tonumber(Config.Tasks[data.task].reward) or 0
    if reward <= 0 or reward > 1000 then
        playerTask[src] = nil
        return exports["ElectronAC"]:banPlayer(src, "Reward bedrag onrealistisch", "Bedrag: " .. tostring(reward), true)
    end

    data.finished = true
    playerTask[src] = nil
    xPlayer.addMoney(reward)
    cooldowns[src] = os.time()

    Citizen.Wait(2500)
    GiveNewTask(src)
end)

RegisterNetEvent("dsx-inspectie:server:cancelTask", function()
    local src = source
    playerTask[src] = nil
    cooldowns[src] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    playerTask[src] = nil
    cooldowns[src] = nil
end)