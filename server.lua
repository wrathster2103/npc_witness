local QBCore = exports['qb-core']:GetCoreObject()
-- Config is provided via shared_script 'config.lua' and exposed as global `Config`
Config = Config or {}

local function isPoliceJob(name)
    if not name then return false end
    for _, j in ipairs(Config.PoliceJobs or {'police'}) do
        if j == name then return true end
    end
    return false
end

-- Simple dispatch: send witness report to all online police
RegisterNetEvent('bldr:witness:report', function(data)
    local src = source
    if not data or not data.pos then return end

    local report = {
        message = data.message or 'Witness report: suspicious activity',
        coords = data.pos,
        suspect = data.suspect or 'unknown',
        accuracy = data.accuracy or 'low',
    }

    -- Try configured dispatch resource first (if available), otherwise send to online police clients
    local dispatched = false
    if Config.EnableDispatch and Config.DispatchResource and exports[Config.DispatchResource] then
        -- attempt common send APIs (some servers use different function names)
        local ok, err = pcall(function()
            local disp = exports[Config.DispatchResource]
            if disp.SendAlert then
                disp:SendAlert('police', report)
                dispatched = true
            elseif disp.SendPoliceAlert then
                disp:SendPoliceAlert(report)
                dispatched = true
            elseif disp.AddCall then
                disp:AddCall(report)
                dispatched = true
            end
        end)
        if not ok then
            print('bldr:witness: ps-dispatch call failed: ' .. tostring(err))
        end
    end

    if not dispatched then
        for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(playerId)
            if Player and Player.PlayerData and Player.PlayerData.job and isPoliceJob(Player.PlayerData.job.name) then
                TriggerClientEvent('bldr:witness:dispatch', playerId, report)
            end
        end
    end
end)

-- Optional server validation endpoint to accept further updates from witnesses
RegisterNetEvent('bldr:witness:update', function(update)
    local src = source
    if not update or not update.pos then return end
    -- Try to forward update via ps-dispatch if available
    local dispatchedUpdate = false
    if Config.EnableDispatch and Config.DispatchResource and exports[Config.DispatchResource] then
        local ok, err = pcall(function()
            local disp = exports[Config.DispatchResource]
            if disp.UpdateCall then
                disp:UpdateCall(update)
                dispatchedUpdate = true
            elseif disp.SendAlert then
                -- fallback: send as another alert
                disp:SendAlert('police', update)
                dispatchedUpdate = true
            end
        end)
        if not ok then
            print('bldr:witness: ps-dispatch update failed: ' .. tostring(err))
        end
    end

    if not dispatchedUpdate then
        for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(playerId)
            if Player and Player.PlayerData and Player.PlayerData.job and isPoliceJob(Player.PlayerData.job.name) then
                TriggerClientEvent('bldr:witness:updateDispatch', playerId, update)
            end
        end
    end
end)