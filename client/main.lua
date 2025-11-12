-- // EXPORTS \\ --
ESX = exports['es_extended']:getSharedObject()

-- // VARIABLES \\ --
local currentTask = nil
local currentCoords = nil
local activeZone = nil
local executingTask = false
local currentToken = nil
local taskBlip = nil
local startPed = nil

-- // FUNCTIONS \\ --
-- Helpers
local function CreateBlip(coords, sprite, scale, color, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function CreateNPC(model, coords, heading)
    local npcHash = GetHashKey(model)
    RequestModel(npcHash)
    while not HasModelLoaded(npcHash) do
        Wait(500)
    end

    local existingNpc = GetClosestPed(coords.x, coords.y, coords.z, 1.0, false, false, false, false, false, -1)
    if DoesEntityExist(existingNpc) then
        return existingNpc
    end

    local npcPed = CreatePed(4, npcHash, coords.x, coords.y, coords.z-1, heading, false, false)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    return npcPed
end

local function GenerateNearbyPoint(coords, radius)
    local angle = math.random() * math.pi * 2
    local r = math.random() * radius
    return vector3(coords.x + math.cos(angle) * r, coords.y + math.sin(angle) * r, coords.z)
end

-- Tasks
local function StoplichtTask()
    local ped = PlayerPedId()

    TaskTurnPedToFaceEntity(ped, ped, 1000)
    lib.progressCircle({ 
        duration = 2500, 
        label = "Zekeringkast openen...", 
        canCancel = true 
    })

    local inspect = lib.inputDialog("Zekeringkast", {
        { type = "select", label = "Welke kastsectie controleren?", options = {
            {label = "Links (stroom)", value = "links"},
            {label = "Midden (regeling)", value = "midden"},
            {label = "Rechts (uitgang)", value = "rechts"},
        }}
    })
    if not inspect then return false end

    lib.progressCircle({ 
        duration = 2000, 
        label = "Controleren van de zekeringkast...", 
        canCancel = false 
    })

    local rounds = 2
    local successes = 0
    for i=1, rounds do
        local ok = lib.skillCheck({{areaSize = 60 - (i*5), speedMultiplier = 1 + (i*0.1)}}, {"e"})
        if ok then successes = successes + 1 end
        Wait(100)
    end

    if successes < 1 then
        lib.notify({
            description = "Je kon de zekering niet vinden, probeer het nog een keer.",
            type = "error", 
            time = 5000
        })
        return false
    end

    TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true)
    lib.progressCircle({ duration = 6000, label = "Zekering vervangen...", canCancel = false })
    ClearPedTasks(ped)

    lib.notify({ 
        description = "Je hebt de zekering succesvol vervangen!", 
        type = "success", 
        time = 5000
    })
    return true
end

local function ZendmastTask()
    local ped = PlayerPedId()

    lib.progressCircle({ duration = 2500, label = "Gereedschap pakken...", canCancel = false })
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
    lib.progressCircle({ duration = 1250, label = "Zoeken van de onderhoudspunten...", canCancel = false })

    local rounds = 3
    local successes = 0
    for i=1, rounds do
        lib.notify({ 
            description = ("Onderhoudspunt %d/%d" ):format(i, rounds), 
            type = "inform",
            time = 1750 
        })

        local ok = lib.skillCheck({{areaSize = 55 - (i * 5), speedMultiplier = 1 + (i * 0.15)}}, {"e"})
        if ok then
            successes += 1
            Wait(100)
        else
            lib.notify({ 
                description = "Punt niet correct vastgezet, probeer het nog een keer", 
                type = "error", 
                time = 1000
            })
            Wait(500)
        end
    end

    if successes < 2 then
        lib.notify({
            description = "Het is je niet gelukt, probeer nog een keer.", 
            type = "error", 
            time = 5000 
        })
        return false
    end

    lib.progressCircle({ 
        duration = 1750, 
        label = "Verbinding herstellen...", 
        canCancel = false 
    })

    ClearPedTasks(ped)
    lib.notify({ 
        description = "De zendmast werkt weer zoals normaal!", 
        type = "success", 
        time = 5000 
    })

    return true
end

local function WaterTask()
    local rounds = 3
    local successes = 0

    for i = 1, rounds do
        lib.notify({ 
            description = ("Monster %d/%d"):format(i, rounds), 
            type = "inform",
            time = 1750 
        })

        local ok = lib.skillCheck({
            {areaSize = 55 - (i * 5), speedMultiplier = 1 + (i * 0.15)}
        }, {"e"})

        if ok then
            successes = successes + 1
            Wait(100)
        else
            lib.notify({ 
                description = "Je hebt het monster niet goed afgenomen, probeer het nog een keer.", 
                type = "error", 
                time = 1000
            })
            Wait(500)
        end
    end

    if successes < rounds then
        lib.notify({
            description = "Je hebt niet alle monsters correct genomen, probeer het nog een keer.",
            type = "error",
            time = 4000
        })
        return false
    end

    local input = lib.inputDialog("Analyseren van water", {
        { type = "number", label = "Temperatuur (°C)", min = 0, max = 40 },
        { type = "number", label = "pH waarde (1-14)", min = 1, max = 14 },
        { type = "number", label = "Troebelheid (NTU)", min = 0, max = 100 }
    })
    if not input then return false end

    lib.progressCircle({
        duration = 4000,
        label = "Laboratoriumanalyse uitvoeren...",
        canCancel = false
    })

    local temp = tonumber(input[1]) or 15
    local ph = tonumber(input[2]) or 7
    local ntu = tonumber(input[3]) or 5

    local quality = "onbekend"
    if ph >= 6.5 and ph <= 8 and ntu < 10 and temp >= 5 and temp <= 25 then
        quality = "fantastisch"
    elseif ntu < 30 then
        quality = "matig"
    else
        quality = "slecht"
    end

    lib.notify({
        title = "Analyse voltooid",
        description = ("Waterkwaliteit: %s (pH: %s, temp: %s°C, troebelheid: %s NTU)"):format(quality, ph, temp, ntu),
        type = "success",
        time = 5000
    })
    return true
end


local function SatellietTask()
    local ped = PlayerPedId()

    lib.progressCircle({
        duration = 2000, 
        label = "Gereedschap pakken en schotel inspecteren...",
        canCancel = false
    })

    local successes = 0
    for i = 1,3 do
        lib.notify({
            description = ("Kalibreren %d/3" ):format(i),
            type = "inform",
            time = 1400
        })

        local ok = lib.skillCheck({{areaSize = 50 - (i*5), speedMultiplier = 1 + (i*0.12)}}, {"e"})
        if ok then
            successes += 1
            Wait(100)
        else
            lib.notify({
                description = "Kalibratie mislukt, probeer het nog een keer.",
                type = "error",
                time = 1000
            })
            Wait(500)
        end
    end

    if successes < 2 then
        lib.notify({
            title = "Uitlijnen mislukt",
            description = "De schotel is nog niet voldoende gekalibreerd. Probeer het nog een keer.",
            type = "error",
            time = 5000
        })
        return false
    end

    ClearPedTasks(ped)
    lib.notify({
        title = "Uitlijnen voltooid",
        description = "De satellietschotel werkt nu zoals het hoort!", 
        type = "success", 
        time = 5000 
    })
    
    return true
end

local function executeTask()
    if not currentTask then return end
    executingTask = true

    local ped = PlayerPedId()
    local success = false

    if currentTask == "stoplicht" then
        success = StoplichtTask(currentCoords)
    elseif currentTask == "zendmast" then
        success = ZendmastTask(currentCoords)
    elseif currentTask == "water" then
        success = WaterTask(currentCoords)
    elseif currentTask == "satelliet" then
        success = SatellietTask(currentCoords)
    end

    ClearPedTasks(ped)

    if not success then
        lib.notify({
            title = "Taak geannuleerd",
            description = "Je hebt de taak niet afgemaakt.",
            type = "error",
            icon = 'circle-xmark',
            time = 5000,
        })
        executingTask = false
        return
    end

    if currentToken then
        TriggerServerEvent("dsx-inspectie:server:finishTask", currentToken)
    else
        TriggerServerEvent("dsx-inspectie:server:finishTask", "")
    end

    lib.notify({
        title = "Taak voltooid",
        description = Config.Tasks[currentTask].notifyDone,
        type = "success",
        icon = 'circle-check',
        time = 5000,
    })

    currentTask = nil
    currentCoords = nil
    currentToken = nil
    executingTask = false

    if activeZone then 
        exports.ox_target:removeZone(activeZone) 
    end
    
    activeZone = nil
    if taskBlip then 
        RemoveBlip(taskBlip) 
    end
end

-- // MAIN SCRIPT \\ --
Citizen.CreateThread(function()
    startPed = CreateNPC('a_m_y_business_01', Config.Locaties.StartJob.coords, Config.Locaties.StartJob.heading)
    CreateBlip(Config.Locaties.StartJob.coords, 525, 0.75, 0, "Kwaliteitsmedewerker")
    exports.ox_target:addLocalEntity(startPed, {
        icon = 'fa-solid fa-briefcase',
        label = "Start je dienst",
        distance = 2,
        onSelect = function()
            TriggerServerEvent("dsx-inspectie:server:startShift")
        end
    })

    exports.ox_target:addLocalEntity(startPed, {
        icon = 'fa-solid fa-car',
        label = "Pak dienstvoertuig",
        distance = 2,
        onSelect = function()
            TriggerServerEvent("dsx-inspectie:server:spawnVehicle")
        end
    })

    local deletePoint = Config.Locaties.DeleteVehicle.coords
    local deleteRadius = 5.0
    local textUIOpen = false

    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local veh = GetVehiclePedIsIn(ped, false)

            if veh ~= 0 then
                local dist = #(coords - deletePoint)
                if dist <= 25.0 then
                    sleep = 0
                    DrawMarker(36, deletePoint.x, deletePoint.y, deletePoint.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 235, 40, 40, 200, false, false, 2, true, nil, nil, false)

                    if dist <= deleteRadius then
                        if not textUIOpen then
                            lib.showTextUI('[E] Zet je dienstvoertuig weg', {position = 'right-center', icon = 'fa-solid fa-truck'})
                            textUIOpen = true
                        end

                        if IsControlJustPressed(0, 38) then
                            local netId = VehToNet(veh)
                            TriggerServerEvent('dsx-inspectie:server:delVehicle', netId)
                        end
                    elseif textUIOpen then
                        lib.hideTextUI()
                        textUIOpen = false
                    end
                elseif textUIOpen then
                    lib.hideTextUI()
                    textUIOpen = false
                end
            elseif textUIOpen then
                lib.hideTextUI()
                textUIOpen = false
            end
            Wait(sleep)
        end
    end)
end)

-- // EVENTS \\ --
RegisterNetEvent("dsx-inspectie:client:startTask", function(task, coords, token)
    currentTask = task
    currentCoords = coords
    currentToken = token

    if taskBlip then 
        RemoveBlip(taskBlip) 
    end
    taskBlip = CreateBlip(coords, 525, 0.75, 0, "Werklocatie")
    SetNewWaypoint(coords.x, coords.y)

    lib.notify({
        title = "Nieuwe klus",
        description = Config.Tasks[task].notify,
        type = "inform",
        icon = 'magnifying-glass',
        time = 5000,
    })

    if activeZone then 
        exports.ox_target:removeZone(activeZone) 
    end

    activeZone = exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = 0,
        debug = false,
        options = {
            {
                name = "dsx-inspectie:doTask",
                icon = "fa-solid fa-wrench",
                label = "Taak uitvoeren",
                onSelect = function()
                    if currentTask and not executingTask then
                        executeTask()
                    end
                end
            },
            {
                name = "dsx-inspectie:stopTask",
                icon = "fa-solid fa-xmark",
                label = "Taak weigeren",
                onSelect = function()
                    TriggerServerEvent("dsx-inspectie:server:cancelTask")
                    lib.notify({
                        description = "Taak geweigerd",
                        type = "error",
                        icon = 'circle-xmark',
                        time = 5000,
                    })
                    ClearPedTasks(PlayerPedId())

                    currentTask = nil
                    currentCoords = nil
                    currentToken = nil
                    executingTask = false

                    if activeZone then 
                        exports.ox_target:removeZone(activeZone) 
                    end

                    activeZone = nil
                    if taskBlip then 
                        RemoveBlip(taskBlip) 
                    end
                end
            }
        }
    })
end)
