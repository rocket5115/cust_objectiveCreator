local status = false

local function display(st)
    status = st
    local c = GetEntityCoords(PlayerPedId())
    SetNuiFocus(status, status)
    SendNUIMessage({
        status = status,
        additionalData = vector4(c.x, c.y, c.z, GetEntityHeading(PlayerPedId()))
    })
end

RegisterCommand('custoc', function(source, args)
    display(not status)
end)

RegisterNUICallback('exit', function(data)
    display(false)
end)

RegisterNUICallback('execute', function(data)
    custExecute(data.data)
end)

RegisterNUICallback('export', function(data)
    TriggerServerEvent('cust_objectiveCreator:exportLua', data.data)
end)

AddEventHandler('cust_objectiveCreator:execute', function(str, cb)
    if str == nil or str == "" then return end
    custExecute(str, function(ended)
        cb(ended)
    end)
end)

function custExecute(str, callback)
    if not str or str == "" then 
        return 
    end
    local res = {}
    str = string.sub(str, 2, string.len(str))
    local found = false
    local pos = 0
    local start_pos = 0
    for i=1, string.len(str), 1 do
        local sub = string.sub(str, i, i)
        local sub2 = string.sub(str, i, i+3)
        local hasStarted = (string.sub(sub2, 4, 4) == ":")
        local hasEnded = (sub==';' or sub=='}')
        if hasStarted then
            pos = i+4
            start_pos = i
        elseif hasEnded then
            table.insert(res, {
                name = string.sub(str, start_pos, start_pos+3),
                args = string.sub(str, pos, i-1)
            })
        end
    end
    local args = {}
    for i=1, #res, 1 do
        if not args[i] then
            args[i] = {}
        end
        local start_pos = 0
        for j=1, string.len(res[i].args), 1 do
            local sub = string.sub(res[i].args, j, j)
            if start_pos == 0 then
                start_pos = j
            end
            if sub == ',' or j == string.len(res[i].args) then
                isTrue = (j==string.len(res[i].args))
                local arg = string.gsub(string.sub(res[i].args, start_pos, isTrue and j or j-1), '++', ',')
                local c = string.gsub(arg, "==", ':')
                args[i][#args[i]+1] = c
                start_pos = 0
            end
        end
    end
    local retval = {}
    for i=1, #res, 1 do
        retval[#retval+1] = Misc[res[i].name]
    end
    local endedExecuting = false
    Citizen.CreateThread(function()
        local i = 1
        local playerPed = PlayerPedId()
        local lastWait = 0
        local loops = {}
        local inMarker = {}
        local lastMarker = 0
        local shouldStop = false
        local registeredEvents = {}
        while true do
            if not retval[i] then
                break
            end
            retval[i](function(name, bool, additional) 
                if name == 'loop' then
                    loops[additional] = i
                end
                if name == 'goto' then
                    if loops[additional] and not shouldStop then
                        i = loops[additional]
                    else
                        shouldStop = false
                    end
                end
                if name == 'break' then
                    if additional == 'marker' then
                        if lastWait > 0 then
                            retval[lastWait](function(name2, b, add) 
                                if custButtonPressedOnMarker[add.x] or custInMarker[add.x] then
                                    inMarker[lastMarker] = nil
                                    shouldStop = true
                                end
                            end, args[lastWait], true)
                        end
                    else
                        if not registeredEvents[additional] then
                            registeredEvents[additional] = true
                            RegisterNetEvent(additional, function()
                                onEvent = true
                            end)
                        else
                            if onEvent then
                                shouldStop = true
                                onEvent = false
                            end
                        end
                    end
                end
                if name == 'marker' then
                    lastWait = i
                end
                if name == 'await' then
                    if lastWait > 0 then
                        retval[lastWait](function(name2, b, add)
                            if b then
                                while true do
                                    Citizen.Wait(50)
                                    if custButtonPressedOnMarker[add.x] then
                                        custButtonPressedOnMarker[add.x] = nil
                                        inMarker[add.x] = true
                                        lastMarker = add.x
                                        break
                                    end
                                end
                            else
                                while true do
                                    Citizen.Wait(50)
                                    if custInMarker[add.x] then
                                        custInMarker[add.x] = nil
                                        inMarker[add.x] = true
                                        lastMarker = add.x
                                        break
                                    end
                                end
                            end
                        end, args[lastWait], true)
                    end
                end
            end, args[i], false)
            i=i+1
        end
        endedExecuting = true
    end)
    if callback then
        repeat Citizen.Wait(100) until endedExecuting
        callback(true)
    end
end

AddEventHandler('playerSpawned', function()
    SendNUIMessage({
        status = false
    })
end)

Citizen.CreateThread(function()
    Citizen.Wait(50)
    SendNUIMessage({
        type = 'lua',
        status = false
    })
end)