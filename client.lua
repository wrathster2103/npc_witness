local QBCore = exports['qb-core']:GetCoreObject()

local Config = Config

local activeWitnesses = {}

local function GetNearbyPeds(radius)
    local peds = {}
    local playerPed = PlayerPedId()
    local plyCoords = GetEntityCoords(playerPed)
    for ped in EnumeratePeds() do
        if ped ~= playerPed and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            if #(plyCoords - pedCoords) <= radius then
                table.insert(peds, ped)
            end
        end
    end
    return peds
end

-- ped enumerator helper (common pattern)
function EnumeratePeds()
    return coroutine.wrap(function()
        local handle, ped = FindFirstPed()
        if not handle or handle == -1 then return end
        local finished = false
        repeat
            coroutine.yield(ped)
            finished, ped = FindNextPed(handle)
        until not finished
        EndFindPed(handle)
    end)
end

local function spawnWitnessAt(coords, suspectPed)
    local model = `a_m_y_business_01`
    RequestModel(model)
    local timeout = GetGameTimer() + 1000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(model) then return end

    -- spawn slightly offset to avoid clipping
    local ox = coords.x + (math.random(-3,3) + 0.0)
    local oy = coords.y + (math.random(-3,3) + 0.0)
    local oz = coords.z
    local ped = CreatePed(4, model, ox, oy, oz, math.random(0,360), true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)

    -- brief startled animation then decide behavior
    TaskStandStill(ped, 500)
    Wait(250)
    -- random chance to call police or flee/run towards cover
    local r = math.random()
    if r < 0.45 then
        -- play phone call scenario
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    elseif r < 0.8 then
        -- look at suspect and take a few steps towards them (curious)
        if DoesEntityExist(suspectPed) then
            TaskTurnPedToFaceEntity(ped, suspectPed, 1000)
            Wait(500)
            TaskGoToEntity(ped, suspectPed, -1, 1.5, 1.0, 1073741824, 0)
        end
    else
        -- panic and flee
        if DoesEntityExist(suspectPed) then
            TaskReactAndFleePed(ped, suspectPed)
        else
            TaskSmartFleeCoord(ped, ox, oy, oz, 10.0, -1, false, false)
        end
    end

    local witness = {
        ped = ped,
        suspect = suspectPed,
        start = GetGameTimer(),
        lastUpdate = 0,
    }
    table.insert(activeWitnesses, witness)
end

-- Create a brief suspect description string
local function buildDescription()
    local ped = PlayerPedId()
    local modelHash = GetEntityModel(ped)
    local sex = IsPedMale(ped) and 'male' or 'female'
    local armour = GetPedArmour(ped)
    local desc = string.format('Suspect: %s, armour:%d, model:%d', sex, armour, modelHash)
    return desc
end

-- Send initial report to server
local function sendReport(pos, suspectPed)
    local desc = buildDescription()
    local data = {
        pos = pos,
        suspect = desc,
        message = 'Witness heard gunshots and saw a suspect',
        accuracy = 'approx',
    }
    TriggerServerEvent('bldr:witness:report', data)
end

-- Witness follow/update loop
CreateThread(function()
    while true do
        Wait(1000)
        -- simple crime detection: player shooting or melee hitting peds nearby
        local playerPed = PlayerPedId()
        local didCrime = (Config.DetectWeapons and IsPedShooting(playerPed)) or (Config.DetectMelee and IsPedInMeleeCombat(playerPed))
        if didCrime then
            local plyCoords = GetEntityCoords(playerPed)
            -- find peds within CrimeRadius and spawn witnesses on some
            local peds = GetNearbyPeds(Config.CrimeRadius)
            for i=1, math.min(Config.MaxWitnesses, #peds) do
                local ped = peds[math.random(#peds)]
                local pedCoords = GetEntityCoords(ped)
                spawnWitnessAt(pedCoords, playerPed)
            end
            -- send immediate report to server
            sendReport(plyCoords, playerPed)
            -- small cooldown to avoid spam
            Wait(10000)
        end

        -- update active witnesses: handle animations, follow/flee behavior, and periodic reporting
        for i = #activeWitnesses, 1, -1 do
            local w = activeWitnesses[i]
            if not w or not DoesEntityExist(w.ped) then
                table.remove(activeWitnesses, i)
            else
                local now = GetGameTimer()
                local elapsed = now - w.start
                if elapsed > Config.WitnessLifetime then
                    -- graceful cleanup
                    if DoesEntityExist(w.ped) then
                        ClearPedTasksImmediately(w.ped)
                        SetBlockingOfNonTemporaryEvents(w.ped, false)
                        SetEntityAsNoLongerNeeded(w.ped)
                        DeletePed(w.ped)
                    end
                    table.remove(activeWitnesses, i)
                else
                    local sus = w.suspect
                    if DoesEntityExist(sus) then
                        -- dynamic behavior: if suspect close and witness not already fleeing, 30% chance to panic and flee
                        local wpos = GetEntityCoords(w.ped)
                        local spos = GetEntityCoords(sus)
                        local dist = #(wpos - spos)

                        if dist < 6.0 and math.random() < 0.3 then
                            -- panic: play scream and flee
                            TaskPlayAnim(w.ped, "amb@code_human_wander_texting_fat@male@base", "static", 8.0, -8.0, 1000, 0, 0, false, false, false)
                            TaskReactAndFleePed(w.ped, sus)
                        else
                            -- otherwise look and update position, occasionally move closer for better sight
                            TaskTurnPedToFaceEntity(w.ped, sus, 1000)
                            if math.random() < 0.4 then
                                TaskGoToEntity(w.ped, sus, -1, 1.7, 1.0, 1073741824, 0)
                            end
                        end

                        if now - w.lastUpdate >= Config.ReportInterval then
                            w.lastUpdate = now
                            local reportPos = GetEntityCoords(sus)
                            local update = {
                                pos = reportPos,
                                suspect = buildDescription(),
                                message = 'Witness saw suspect and is updating position',
                                accuracy = (dist < 10 and 'high' or 'medium')
                            }
                            TriggerServerEvent('bldr:witness:update', update)
                        end
                    else
                        -- suspect no longer exists; witness reports last seen and may call police or wander away
                        local lastPos = GetEntityCoords(w.ped)
                        local update = {
                            pos = lastPos,
                            suspect = 'suspect lost',
                            message = 'Witness lost the suspect',
                            accuracy = 'low'
                        }
                        TriggerServerEvent('bldr:witness:update', update)

                         -- attempt a brief call animation then cleanup
                         if DoesEntityExist(w.ped) then
                             TaskStartScenarioInPlace(w.ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
                             SetTimeout(3000, function()
                                 if DoesEntityExist(w.ped) then
                                     ClearPedTasks(w.ped)
                                     SetBlockingOfNonTemporaryEvents(w.ped, false)
                                     SetEntityAsNoLongerNeeded(w.ped)
                                     DeletePed(w.ped)
                                 end
                             end)
                         end

                        table.remove(activeWitnesses, i)
                    end
                end
            end
        end
    end
end)

-- client event: police receive dispatch
RegisterNetEvent('bldr:witness:dispatch', function(report)
    -- show blip + notification for cops only
    local src = source
    local coords = report.coords
    local msg = report.message .. ' | ' .. (report.suspect or '')
    -- basic notification
    QBCore.Functions.Notify(msg, 'primary', 8000)
     -- create short lived blip
     local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
     SetBlipSprite(blip, 161)
     SetBlipColour(blip, 1)
     SetBlipScale(blip, 1.2)
     BeginTextCommandSetBlipName('STRING')
     AddTextComponentString('Witness Report')
     EndTextCommandSetBlipName(blip)
     SetBlipAsShortRange(blip, false)
     SetTimeout(30000, function()
         RemoveBlip(blip)
     end)
end)

-- client event: police receive updates (moving ping)
RegisterNetEvent('bldr:witness:updateDispatch', function(update)
    local coords = update.pos
    local msg = update.message .. ' | ' .. (update.suspect or '')
    QBCore.Functions.Notify(msg, 'primary', 4000)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Witness Update')
    EndTextCommandSetBlipName(blip)
     SetTimeout(15000, function()
         RemoveBlip(blip)
     end)
end)

-- small utility: vector3 unpack helper for some runtimes
function vec3(v)
    return {v.x, v.y, v.z}
end