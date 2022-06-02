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

AddEventHandler('cust_objectiveCreator:execute', function(str)
    if str == nil or str == "" then return end
    custExecute(str)
end)

function custExecute(str)
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
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local shouldWait = false
        local lastWait = 0
        for i=1, #retval, 1 do
            retval[i](function(name, bool, additional) 
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
                                        break
                                    end
                                end
                            else
                                while true do
                                    Citizen.Wait(50)
                                    if Vdist2(GetEntityCoords(playerPed), add) < 3.0 then
                                        break
                                    end
                                end
                            end
                        end, args[lastWait], true)
                    end
                end
            end, args[i], false)
        end
    end)
end
--[[
--Example, not adding in "lines" on forum
RegisterCommand('custexample', function(source, args)
    local s = "{cnp:1,s_m_y_airworker,-207.24481201171875,-1114.4189453125,22.8735294342041,72.69156646728516,false,false;cnp:1,s_m_m_dockwork_01,-183.84750366210935,-1079.1448974609375,30.13942146301269,153.7270965576172,false,false;sce:2,WORLD_HUMAN_SMOKING_POT,-1,false;mar:0,-208.28111267089844,-1114.4786376953125,22.86520004272461,0,0,0,0,0,0,1,1,1,0,255,0,100,true,true,2,false,null,null,false,true,46;awa:true;cmt:Hey there! You’re late again! Talk with Bob he has a job for you.,4000;del:4500;cmt:He is on the first floor up there.,3000;del:3500;cnt:You were given a task to complete!;mar:0,-183.8783721923828,-1079.120361328125,30.13940238952636,0,0,0,0,0,0,1,1,1,0,255,0,100,false,false,2,false,null,null,false,true,46;awa:true;cmt:On top of this building is a package++ bring it here!,3500;del:4000;mar:0,-179.866943359375,-1077.0670166015625,42.41322708129883,0,0,0,0,0,0,1,1,1,0,255,0,0,false,false,2,false,null,null,false,true,46;cob:prop_drug_package,-179.57652282714844,-1077.403564453125,42.13927841186523,303.3604736328125,false,false;exo:cust_exampleMarker,1;awa:true;cnt:Bring the package to Bob!;tce:cust_stopMarker;mar:0,-184.1178436279297,-1080.09619140625,30.16493606567382,0,0,0,0,0,0,1,1,1,0,255,0,100,false,false,2,false,null,null,false,true,46;awa:true;cmt:Thanks. You are free to go now.;tce:cust_finished;cnt:You have finished tutorial objective! This script can be altered to your liking++ Thanks for using and sharing your opinions!}"
    custExecute(s)
end)

local shouldStop = false
local object = 0

AddEventHandler('cust_exampleMarker', function(obj)
    Citizen.CreateThread(function()
        obj = obj
        object = obj
        while true do
            Citizen.Wait(5)
            DrawMarker(0, GetEntityCoords(obj), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 255, 100, true, false, nil, nil, false)
            if shouldStop then
                break
            end
        end
    end)
end)

AddEventHandler('cust_stopMarker', function()
    shouldStop = true
    AttachEntityToEntity(object, PlayerPedId(), 24817, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, false, 100, true)
end)

AddEventHandler('cust_finished', function()
    shouldStop = false
    DetachEntity(object, true, true)
    SetEntityAsMissionEntity(object, true, true)
    DeleteEntity(object)
end)
--]]
