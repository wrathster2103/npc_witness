-- dispatch_adapter.lua
-- Server-side adapter to send calls to common dispatch systems or fallback
local QBCore = exports['qb-core']:GetCoreObject()

local Adapter = {}

-- Normalize payload expected by various dispatchers
local function buildPayload(data)
    return {
        title = data.title or 'Witness Report',
        coords = data.coords,
        description = data.description or '',
        priority = data.priority or 1,
        metadata = data.metadata or {},
    }
end

local function tryExport(resourceName, fn)
    if GetResourceState(resourceName) ~= 'started' then return false end
    local ok, err = pcall(fn)
    if ok then return true end
    return false
end

local function sendToPsDispatch(payload)
    -- ps-dispatch implementations vary; attempt common export/event names
    if exports['ps-dispatch'] and exports['ps-dispatch'].SendAlert then
        exports['ps-dispatch']:SendAlert(payload)
        return true
    elseif exports['ps-dispatch'] and exports['ps-dispatch'].AddCall then
        exports['ps-dispatch']:AddCall(payload)
        return true
    elseif TriggerEvent then
        TriggerEvent('ps-dispatch:server:SendAlert', payload)
        return true
    end
    return false
end

local function sendToQbDispatch(payload)
    if exports['qb-dispatch'] and exports['qb-dispatch'].AddCall then
        exports['qb-dispatch']:AddCall(payload)
        return true
    elseif TriggerEvent then
        TriggerEvent('qb-dispatch:server:AddCall', payload)
        return true
    end
    return false
end

local function sendToOxDispatch(payload)
    if exports['ox_dispatch'] and exports['ox_dispatch'].AddCall then
        exports['ox_dispatch']:AddCall(payload)
        return true
    elseif TriggerEvent then
        TriggerEvent('ox_dispatch:addCall', payload)
        return true
    end
    return false
end

function Adapter.SendCall(data)
    if not data or not data.coords then return false end
    local payload = buildPayload(data)

    if not Config then
        print('npc_witness: missing Config')
    end

    if Config and Config.EnableDispatch then
        -- If a specific resource is set, try it first
        if Config.DispatchResource and Config.DispatchResource ~= '' then
            local r = Config.DispatchResource
            if r == 'ps-dispatch' and Config.DispatchAdapters.ps_dispatch then
                if tryExport('ps-dispatch', function() sendToPsDispatch(payload) end) then return true end
            elseif r == 'qb-dispatch' and Config.DispatchAdapters.qb_dispatch then
                if tryExport('qb-dispatch', function() sendToQbDispatch(payload) end) then return true end
            elseif r == 'ox_dispatch' and Config.DispatchAdapters.ox_dispatch then
                if tryExport('ox_dispatch', function() sendToOxDispatch(payload) end) then return true end
            end
        end

        -- Auto-detect common dispatch resources if no explicit resource set
        if Config.DispatchAdapters.ps_dispatch and tryExport('ps-dispatch', function() sendToPsDispatch(payload) end) then
            return true
        end
        if Config.DispatchAdapters.qb_dispatch and tryExport('qb-dispatch', function() sendToQbDispatch(payload) end) then
            return true
        end
        if Config.DispatchAdapters.ox_dispatch and tryExport('ox_dispatch', function() sendToOxDispatch(payload) end) then
            return true
        end
    end

    -- Fallback: notify online players with police jobs
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.job then
            local jobname = player.PlayerData.job.name
            for _, pj in ipairs(Config.PoliceJobs or {}) do
                if jobname == pj then
                    -- Send a basic notify to police players as a fallback
                    TriggerClientEvent('QBCore:Notify', src, ('%s reported at the scene'):format(payload.title), 'primary', 5000)
                    TriggerClientEvent('npc_witness:client:AddBlip', src, payload.coords, payload.title)
                    break
                end
            end
        end
    end

    return true
end

return Adapter
